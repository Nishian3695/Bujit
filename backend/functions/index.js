const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const crypto = require("crypto");

setGlobalOptions({maxInstances: 10});

admin.initializeApp();

// Plaid secrets, selected at runtime by PLAID_ENV.
const plaidClientId = defineSecret("PLAID_CLIENT_ID");
const plaidSecretSandbox = defineSecret("PLAID_SECRET_SANDBOX");
const plaidSecretProduction = defineSecret("PLAID_SECRET_PRODUCTION");

// Plaid environment. Set PLAID_ENV in .env.<project> to sandbox or production
// (anything else means sandbox).
const PLAID_ENV = defineString("PLAID_ENV", {default: "production"});

function plaidSecretValue() {
  return PLAID_ENV.value() === "production" ?
    plaidSecretProduction.value() :
    plaidSecretSandbox.value();
}

function plaidBaseUrl() {
  return PLAID_ENV.value() === "production" ?
    "https://production.plaid.com" :
    "https://sandbox.plaid.com";
}

// Where Plaid sends iOS users back after a bank's own login page (OAuth). Must be
// listed in the Plaid dashboard's allowed redirect URIs, and be a universal link to
// the app (served by Firebase Hosting: hosting/.well-known/apple-app-site-association).
const PLAID_REDIRECT_URI = defineString("PLAID_REDIRECT_URI", {
  default: "https://bujit-89ac6.web.app/plaid-oauth",
});

// App Check proves a request comes from the genuine app (Play Integrity on Android,
// App Attest on iOS). It's required unless ENFORCE_APP_CHECK is exactly "false"
// (only for local testing): anonymous Firebase sign-in alone lets anyone call this.
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK !== "false";

const ANDROID_PACKAGE = "io.github.nishian3695.bujit";
const ANDROID_APP_ID = "1:533939418471:android:e39cb96592f09e1c036bc2";

// ─── Auth helpers ────────────────────────────────────────────────────────────

async function verifyFirebaseToken(req, res) {
  const idToken = req.headers["authorization"]?.split("Bearer ")[1];
  if (!idToken) {
    res.status(401).send("Unauthorized");
    return null;
  }
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (e) {
    console.error("ID token verification failed:", e.message);
    res.status(403).send("Forbidden");
    return null;
  }
}

async function verifyAppCheck(req, res) {
  if (!ENFORCE_APP_CHECK) return true;
  const appCheckToken = req.headers["x-firebase-appcheck"];
  if (!appCheckToken) {
    res.status(401).json({error: "Missing App Check token"});
    return false;
  }
  try {
    await admin.appCheck().verifyToken(appCheckToken);
    return true;
  } catch (e) {
    console.error("App Check verification failed:", e.message);
    res.status(403).json({error: "Invalid App Check token"});
    return false;
  }
}

// ─── Bank tokens tied to their user ──────────────────────────────────────────
//
// The app never sees a raw Plaid access token. /plaid/exchange returns it sealed
// with AES-256-GCM together with the caller's Firebase user id, and every later
// call unseals it and checks that the same user sent it. A copied token is useless
// to anyone else, even with their own Firebase sign-in. The key is derived from
// the Plaid secret, so rotating that secret means relinking banks (which a leaked
// secret needs anyway).

const SEALED_PREFIX = "bujit1.";

function sealingKey() {
  return Buffer.from(crypto.hkdfSync(
      "sha256", plaidSecretValue(), "bujit-token-seal", "plaid-access-token", 32));
}

function sealAccessToken(accessToken, uid) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", sealingKey(), iv);
  const sealed = Buffer.concat([
    cipher.update(JSON.stringify({u: uid, t: accessToken}), "utf8"),
    cipher.final(),
  ]);
  return SEALED_PREFIX + Buffer.concat([iv, sealed, cipher.getAuthTag()]).toString("base64url");
}

// The Plaid access token in [token] if [uid] sealed it, else null.
function unsealAccessToken(token, uid) {
  if (typeof token !== "string" || !token.startsWith(SEALED_PREFIX)) return null;
  try {
    const raw = Buffer.from(token.slice(SEALED_PREFIX.length), "base64url");
    if (raw.length < 12 + 16 + 1) return null;
    const decipher = crypto.createDecipheriv("aes-256-gcm", sealingKey(), raw.subarray(0, 12));
    decipher.setAuthTag(raw.subarray(raw.length - 16));
    const plain = Buffer.concat([decipher.update(raw.subarray(12, raw.length - 16)), decipher.final()]);
    const {u, t} = JSON.parse(plain.toString("utf8"));
    return u === uid && typeof t === "string" ? t : null;
  } catch (e) {
    return null;
  }
}

// ─── Plaid handler ───────────────────────────────────────────────────────────

async function handlePlaidRequest(req, res, decodedToken) {
  const clientId = plaidClientId.value();
  const secret = plaidSecretValue();
  const baseUrl = plaidBaseUrl();

  try {
    // POST /plaid/link/token  {platform?: "ios" | "android"}
    // Android names the app's package (Plaid returns to it after OAuth); iOS gives a
    // redirect URI instead.
    if (req.method === "POST" && req.path === "/plaid/link/token") {
      const ios = req.body?.platform === "ios";
      const response = await axios.post(`${baseUrl}/link/token/create`, {
        client_id: clientId,
        secret: secret,
        user: {client_user_id: decodedToken.uid},
        client_name: "Bujit",
        products: ["transactions"],
        country_codes: ["US"],
        language: "en",
        ...(ios ?
          {redirect_uri: PLAID_REDIRECT_URI.value()} :
          {android_package_name: ANDROID_PACKAGE}),
      });
      res.json({link_token: response.data.link_token});
      return;
    }

    // POST /plaid/exchange {public_token} -> {access_token} (sealed to this user)
    if (req.method === "POST" && req.path === "/plaid/exchange") {
      const publicToken = req.body?.public_token;
      if (typeof publicToken !== "string" || !publicToken) {
        res.status(400).json({error: "Missing public_token"});
        return;
      }
      const response = await axios.post(`${baseUrl}/item/public_token/exchange`, {
        client_id: clientId,
        secret: secret,
        public_token: publicToken,
      });
      res.json({access_token: sealAccessToken(response.data.access_token, decodedToken.uid)});
      return;
    }

    const token = req.headers["x-plaid-token"];
    if (!token) {
      res.status(401).json({error: "Missing X-Plaid-Token header"});
      return;
    }
    const accessToken = unsealAccessToken(token, decodedToken.uid);

    // POST /plaid/remove — revokes the Item so the access token stops working at
    // Plaid. Also takes a raw token from before tokens were sealed: revoking is the
    // one thing a holder of an old token should still be able to do.
    if (req.method === "POST" && req.path === "/plaid/remove") {
      const revoke = accessToken ?? (token.startsWith(SEALED_PREFIX) ? null : token);
      if (!revoke) {
        res.status(401).json({error: "INVALID_ACCESS_TOKEN"});
        return;
      }
      await axios.post(`${baseUrl}/item/remove`, {
        client_id: clientId,
        secret: secret,
        access_token: revoke,
      });
      res.json({revoked: true});
      return;
    }

    // Everything else needs a token this user sealed. A raw token from before
    // sealing gets 401, which the app shows as "Reconnect".
    if (!accessToken) {
      res.status(401).json({error: "INVALID_ACCESS_TOKEN"});
      return;
    }

    // GET /plaid/accounts
    if (req.method === "GET" && req.path === "/plaid/accounts") {
      const accountsResp = await axios.post(`${baseUrl}/accounts/get`, {
        client_id: clientId,
        secret: secret,
        access_token: accessToken,
      });
      const {accounts, item} = accountsResp.data;

      let institutionName = "";
      try {
        const instResp = await axios.post(`${baseUrl}/institutions/get_by_id`, {
          client_id: clientId,
          secret: secret,
          institution_id: item.institution_id,
          country_codes: ["US"],
        });
        institutionName = instResp.data.institution.name;
      } catch (e) {
        console.warn("Failed to fetch institution name:", e.message);
      }

      const result = accounts.map((acct) => ({
        id: acct.account_id,
        name: acct.name,
        type: acct.type,
        subtype: acct.subtype,
        mask: acct.mask ?? "",
        institution_name: institutionName,
        ledger: acct.balances.current != null ? acct.balances.current.toString() : "—",
        available: acct.balances.available != null ? acct.balances.available.toString() : "—",
        // limit is only non-null for credit-type accounts; null for depository/investment.
        limit: acct.balances.limit != null ? acct.balances.limit.toString() : null,
      }));

      res.json(result);
      return;
    }

    // No route calls Plaid's /accounts/balance/get, which is billed per call: balances
    // come only from /accounts/get above.

    res.status(404).json({error: "Unknown Plaid route"});
  } catch (e) {
    const status = e.response?.status ?? 500;
    // Surface only the Plaid error_code (not the full response body) to avoid leaking API details.
    const errorCode = e.response?.data?.error_code ?? "PLAID_ERROR";
    console.error("handlePlaidRequest error:", errorCode, "status:", status);
    res.status(status).json({error: errorCode});
  }
}

// ─── Play Integrity exchange (Android App Check) ─────────────────────────────
//
// Android release builds get their App Check token here: a Play Integrity token
// from a genuine, Play-installed app on a real device buys a one-hour App Check
// token. Calls are limited per address and each integrity token works once, and
// only for two minutes, so a captured token can't be reused and garbage can't use
// up the project's daily Play Integrity quota. (Limits are kept per server
// instance, which is enough at maxInstances 10.)

const INTEGRITY_MAX_AGE_MS = 2 * 60 * 1000;
const EXCHANGES_PER_HOUR = 30;
const recentExchanges = new Map(); // client address -> timestamps in the last hour
const usedIntegrityTokens = new Map(); // sha256 of a used token -> when it expires

function clientAddress(req) {
  return (req.headers["x-forwarded-for"] ?? "").split(",")[0].trim() || req.ip || "unknown";
}

// True if [address] may exchange now (and counts this attempt).
function allowExchange(address, now) {
  const recent = (recentExchanges.get(address) ?? []).filter((t) => now - t < 60 * 60 * 1000);
  if (recent.length >= EXCHANGES_PER_HOUR) {
    recentExchanges.set(address, recent);
    return false;
  }
  recent.push(now);
  recentExchanges.set(address, recent);
  if (recentExchanges.size > 10000) {
    for (const [key, times] of recentExchanges) {
      if (times.every((t) => now - t >= 60 * 60 * 1000)) recentExchanges.delete(key);
    }
  }
  return true;
}

// True the first time [hash] is seen in its two-minute life.
function firstUse(hash, now) {
  for (const [key, expires] of usedIntegrityTokens) {
    if (expires <= now) usedIntegrityTokens.delete(key);
  }
  if (usedIntegrityTokens.has(hash)) return false;
  usedIntegrityTokens.set(hash, now + INTEGRITY_MAX_AGE_MS);
  return true;
}

async function exchangeIntegrityToken(req, res) {
  const now = Date.now();
  if (!allowExchange(clientAddress(req), now)) {
    res.status(429).json({error: "Too many requests"});
    return;
  }
  const integrityToken = req.body?.integrityToken;
  // A Standard API token is a long JWE (base64url parts joined by dots); anything
  // else is turned away without spending quota on it.
  if (typeof integrityToken !== "string" || integrityToken.length < 100 ||
      integrityToken.length > 20000 || !/^[A-Za-z0-9_\-.=]+$/.test(integrityToken)) {
    res.status(400).json({error: "Missing integrityToken"});
    return;
  }
  const tokenHash = crypto.createHash("sha256").update(integrityToken).digest("hex");
  if (usedIntegrityTokens.has(tokenHash)) {
    res.status(403).json({error: "Integrity token already used"});
    return;
  }
  try {
    const {GoogleAuth} = require("google-auth-library");
    const client = await new GoogleAuth({scopes: ["https://www.googleapis.com/auth/playintegrity"]}).getClient();
    const accessToken = (await client.getAccessToken()).token;
    const verifyResp = await axios.post(
        `https://playintegrity.googleapis.com/v1/${ANDROID_PACKAGE}:decodeIntegrityToken`,
        {integrity_token: integrityToken},
        {headers: {Authorization: `Bearer ${accessToken}`}},
    );
    const payload = verifyResp.data.tokenPayloadExternal;
    const appVerdict = payload?.appIntegrity?.appRecognitionVerdict;
    const deviceVerdicts = payload?.deviceIntegrity?.deviceRecognitionVerdict ?? [];
    const packageName = payload?.requestDetails?.requestPackageName;
    const tokenAgeMs = now - Number(payload?.requestDetails?.timestampMillis ?? 0);

    if (packageName !== ANDROID_PACKAGE) {
      console.warn("exchangeIntegrityToken: package mismatch", packageName);
      res.status(403).json({error: "Package name mismatch"});
      return;
    }
    if (tokenAgeMs > INTEGRITY_MAX_AGE_MS || tokenAgeMs < -60 * 1000) {
      console.warn("exchangeIntegrityToken: token too old", tokenAgeMs);
      res.status(403).json({error: "Integrity token too old"});
      return;
    }
    if (appVerdict !== "PLAY_RECOGNIZED" || !deviceVerdicts.includes("MEETS_BASIC_INTEGRITY")) {
      console.warn("exchangeIntegrityToken: verdict rejected", {appVerdict, deviceVerdicts});
      res.status(403).json({error: "Integrity check failed"});
      return;
    }
    if (!firstUse(tokenHash, now)) {
      res.status(403).json({error: "Integrity token already used"});
      return;
    }

    const appCheckToken = await admin.appCheck().createToken(ANDROID_APP_ID, {ttlMillis: 3600000});
    res.json({token: appCheckToken.token, ttlMillis: appCheckToken.ttlMillis});
  } catch (e) {
    console.error("exchangeIntegrityToken error:", JSON.stringify(e.response?.data ?? e.message));
    res.status(500).json({error: "Integrity verification failed"});
  }
}

// ─── Main export ─────────────────────────────────────────────────────────────
//
// Still named tellerProxy (from when it also served Teller) so its address, which
// the app has built in, stays the same.

exports.tellerProxy = onRequest(
    {secrets: [plaidClientId, plaidSecretSandbox, plaidSecretProduction], invoker: "public"},
    async (req, res) => {
    // Before App Check: this is how Android release builds get an App Check token.
      if (req.method === "POST" && req.path === "/exchangeIntegrityToken") {
        await exchangeIntegrityToken(req, res);
        return;
      }

      // Step 1: the request comes from the genuine app.
      if (!await verifyAppCheck(req, res)) return;

      // Step 2: a Firebase sign-in (anonymous), which bank tokens are tied to.
      const decodedToken = await verifyFirebaseToken(req, res);
      if (!decodedToken) return;

      if (req.path.startsWith("/plaid/")) {
        await handlePlaidRequest(req, res, decodedToken);
        return;
      }

      res.status(404).json({error: "Unknown route"});
    },
);
