const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const https = require("https");

setGlobalOptions({maxInstances: 10});

admin.initializeApp();

// Teller secrets (mTLS certificate + private key stored in Secret Manager)
const tellerCert = defineSecret("TELLER_CERT");
const tellerKey = defineSecret("TELLER_PRIVATE_KEY");

// Plaid secrets, selected at runtime by PLAID_ENV.
const plaidClientId          = defineSecret("PLAID_CLIENT_ID");
const plaidSecretSandbox     = defineSecret("PLAID_SECRET_SANDBOX");
const plaidSecretProduction  = defineSecret("PLAID_SECRET_PRODUCTION");

function plaidSecretValue() {
  switch (PLAID_ENV.value()) {
    case "sandbox":     return plaidSecretSandbox.value();
    case "production":  return plaidSecretProduction.value();
    default:            return plaidSecretSandbox.value();  // fallback to sandbox if PLAID_ENV is invalid
  }
}

// Plaid environment. Set PLAID_ENV in .env.<project> to one of:
//   sandbox | development | production   (defaults to production)
const PLAID_ENV = defineString("PLAID_ENV", {default: "production"});

// Plaid base URL based on environment.
// Sandbox: https://sandbox.plaid.com
// Development/Production: https://production.plaid.com (they use the same now)
function plaidBaseUrl() {
  switch (PLAID_ENV.value()) {
    case "sandbox":     return "https://sandbox.plaid.com";
    case "production":  return "https://production.plaid.com";
    default:            return "https://sandbox.plaid.com";  // fallback to sandbox if PLAID_ENV is invalid
  }
}

// Set ENFORCE_APP_CHECK=true in production to require Firebase App Check tokens.
// Flip this via Cloud Run env vars; leave false during initial rollout/testing.
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === "true";

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

// ─── Plaid handler ───────────────────────────────────────────────────────────

async function handlePlaidRequest(req, res, decodedToken) {
  const clientId = plaidClientId.value();
  const secret = plaidSecretValue();
  const baseUrl = plaidBaseUrl();

  try {
    // POST /plaid/link/token
    if (req.method === "POST" && req.path === "/plaid/link/token") {
      const response = await axios.post(`${baseUrl}/link/token/create`, {
        client_id: clientId,
        secret: secret,
        user: {client_user_id: decodedToken.uid},
        client_name: "Bujit",
        products: ["transactions"],
        country_codes: ["US"],
        language: "en",
        android_package_name: "io.github.nishian3695.bujit",
      });
      res.json({link_token: response.data.link_token});
      return;
    }

    // POST /plaid/exchange
    if (req.method === "POST" && req.path === "/plaid/exchange") {
      const {public_token: publicToken} = req.body;
      if (!publicToken) {
        res.status(400).json({error: "Missing public_token"});
        return;
      }
      const response = await axios.post(`${baseUrl}/item/public_token/exchange`, {
        client_id: clientId,
        secret: secret,
        public_token: publicToken,
      });
      res.json({access_token: response.data.access_token});
      return;
    }

    // POST /plaid/remove  — revokes the Item so the access_token is invalidated on Plaid's side.
    if (req.method === "POST" && req.path === "/plaid/remove") {
      const accessToken = req.headers["x-plaid-token"];
      if (!accessToken) {
        res.status(401).json({error: "Missing X-Plaid-Token header"});
        return;
      }
      await axios.post(`${baseUrl}/item/remove`, {
        client_id: clientId,
        secret: secret,
        access_token: accessToken,
      });
      res.json({revoked: true});
      return;
    }

    // All remaining Plaid routes require X-Plaid-Token.
    const accessToken = req.headers["x-plaid-token"];
    if (!accessToken) {
      res.status(401).json({error: "Missing X-Plaid-Token header"});
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

    // GET /plaid/accounts/{id}/balance
    const balanceMatch = req.path.match(/^\/plaid\/accounts\/([^/]+)\/balance$/);
    if (req.method === "GET" && balanceMatch) {
      const accountId = balanceMatch[1];
      const response = await axios.post(`${baseUrl}/accounts/balance/get`, {
        client_id: clientId,
        secret: secret,
        access_token: accessToken,
        options: {account_ids: [accountId]},
      });
      const accts = response.data.accounts;
      if (!accts || accts.length === 0) {
        res.status(404).json({error: "Account not found"});
        return;
      }
      const balances = accts[0].balances;
      res.json({
        ledger: balances.current != null ? balances.current.toString() : "—",
        available: balances.available != null ? balances.available.toString() : "—",
        limit: balances.limit != null ? balances.limit.toString() : null,
      });
      return;
    }

    // TODO: On-the-fly refresh, Layer 2. User-triggered real-time balance refresh with server-side rate limiting.
    //
    // Adds POST /plaid/accounts/{id}/balance/refresh: calls /accounts/balance/get (real-time,
    // charged per call) but enforces a per-user per-account cooldown via Firestore so no single
    // user can drive up Plaid costs. The client calls this only when the user explicitly requests
    // a "force refresh"; normal startup/pull-to-refresh continues to use /accounts/get (free).
    //
    // ── To change the cooldown, edit this one line: ──────────────────────────────────────────
    // const REAL_TIME_BALANCE_COOLDOWN_MS = 60 * 60 * 1000; // 1 hour  (change this value)
    // ─────────────────────────────────────────────────────────────────────────────────────────
    //
    // Firestore path: users/{uid}/balanceCache/{accountId}
    //   Fields: { ledger, available, limit, fetchedAt }
    // Data is scoped to the Firebase Auth UID that is already verified above, so one user's
    // cache cannot be read or poisoned by another. No PII is stored beyond what Plaid returns.
    //
    // HTTP 200 → fresh real-time data was fetched and cached.
    // HTTP 429 → cooldown not elapsed; cached values are returned alongside retryAfter (seconds)
    //            so the client can tell the user when they can refresh again.
    //
    // const REAL_TIME_BALANCE_COOLDOWN_MS = 60 * 60 * 1000; // ← change this (currently 1 hour)
    //
    // const refreshMatch = req.path.match(/^\/plaid\/accounts\/([^/]+)\/balance\/refresh$/);
    // if (req.method === "POST" && refreshMatch) {
    //   const accountId = refreshMatch[1];
    //   const db        = admin.firestore();
    //   const cacheRef  = db.collection("users").doc(decodedToken.uid)
    //                       .collection("balanceCache").doc(accountId);
    //
    //   const cached = await cacheRef.get();
    //   if (cached.exists) {
    //     const { fetchedAt, ledger, available, limit } = cached.data();
    //     if (Date.now() - fetchedAt < REAL_TIME_BALANCE_COOLDOWN_MS) {
    //       // Within cooldown — return the cached snapshot and signal the client.
    //       res.status(429).json({
    //         ledger, available, limit: limit ?? null,
    //         retryAfter: Math.ceil((fetchedAt + REAL_TIME_BALANCE_COOLDOWN_MS - Date.now()) / 1000),
    //       });
    //       return;
    //     }
    //   }
    //
    //   // Cooldown elapsed (or first call) — hit /accounts/balance/get for a real-time pull.
    //   const response = await axios.post(`${baseUrl}/accounts/balance/get`, {
    //     client_id:    clientId,
    //     secret:       secret,
    //     access_token: accessToken,
    //     options:      { account_ids: [accountId] },
    //   });
    //   const accts = response.data.accounts;
    //   if (!accts || accts.length === 0) {
    //     res.status(404).json({ error: "Account not found" });
    //     return;
    //   }
    //   const balances = accts[0].balances;
    //   const result = {
    //     ledger:    balances.current   != null ? balances.current.toString()   : "—",
    //     available: balances.available != null ? balances.available.toString() : "—",
    //     limit:     balances.limit     != null ? balances.limit.toString()     : null,
    //   };
    //
    //   // Persist under the authenticated UID — Firestore rules should restrict reads/writes
    //   // to the owning user (users/{uid}/balanceCache/{accountId} → request.auth.uid == uid).
    //   await cacheRef.set({ ...result, fetchedAt: Date.now() });
    //
    //   res.json(result);
    //   return;
    // }

    res.status(404).json({error: "Unknown Plaid route"});
  } catch (e) {
    const status = e.response?.status ?? 500;
    // Surface only the Plaid error_code (not the full response body) to avoid leaking API details.
    const errorCode = e.response?.data?.error_code ?? "PLAID_ERROR";
    console.error("handlePlaidRequest error:", errorCode, "status:", status);
    res.status(status).json({error: errorCode});
  }
}

// ─── Teller handler ──────────────────────────────────────────────────────────

async function handleTellerRequest(req, res, agent) {
  try {
    // POST /teller/remove  — deletes the enrollment so the access_token is invalidated on Teller's side.
    // Finds the enrollment_id via GET /accounts (each account carries an enrollment_id field),
    // then DELETE /enrollments/{id}.
    if (req.method === "POST" && req.path === "/teller/remove") {
      const accessToken = req.headers["x-teller-token"];
      if (!accessToken) {
        res.status(401).json({error: "Missing X-Teller-Token header"});
        return;
      }

      let enrollmentId = null;
      try {
        const accountsResp = await axios.get("https://api.teller.io/accounts", {
          httpsAgent: agent,
          auth: {username: accessToken, password: ""},
        });
        const accounts = accountsResp.data;
        if (accounts && accounts.length > 0) {
          enrollmentId = accounts[0].enrollment_id;
        }
      } catch (e) {
        if (e.response?.status === 401) {
          // Already revoked or invalid — treat as success.
          res.json({revoked: true});
          return;
        }
        throw e;
      }

      if (!enrollmentId) {
        // No accounts found; enrollment is already empty or revoked.
        res.json({revoked: true});
        return;
      }

      await axios.delete(`https://api.teller.io/enrollments/${enrollmentId}`, {
        httpsAgent: agent,
        auth: {username: accessToken, password: ""},
      });
      res.json({revoked: true});
      return;
    }

    res.status(404).json({error: "Unknown Teller management route"});
  } catch (e) {
    const status = e.response?.status ?? 500;
    const errorCode = e.response?.data?.error?.code ?? "TELLER_ERROR";
    console.error("handleTellerRequest error:", errorCode, "status:", status);
    res.status(status).json({error: errorCode});
  }
}

// ─── Main export ─────────────────────────────────────────────────────────────

exports.tellerProxy = onRequest(
  {secrets: [tellerCert, tellerKey, plaidClientId, plaidSecretSandbox, plaidSecretProduction], invoker: "public"},
  async (req, res) => {
    // POST /exchangeIntegrityToken — verifies a Play Integrity Standard API token via
    // decodeIntegrityToken, then issues a Firebase App Check token via the Admin SDK.
    // Placed before App Check enforcement so clients can bootstrap App Check itself.
    if (req.method === "POST" && req.path === "/exchangeIntegrityToken") {
      const {integrityToken} = req.body;
      if (!integrityToken) {
        res.status(400).json({error: "Missing integrityToken"});
        return;
      }
      try {
        const {GoogleAuth} = require("google-auth-library");
        const client = await new GoogleAuth({scopes: ["https://www.googleapis.com/auth/playintegrity"]}).getClient();
        const accessToken = (await client.getAccessToken()).token;
        const verifyResp = await axios.post(
          "https://playintegrity.googleapis.com/v1/io.github.nishian3695.bujit:decodeIntegrityToken",
          {integrity_token: integrityToken},
          {headers: {Authorization: `Bearer ${accessToken}`}},
        );
        const payload = verifyResp.data.tokenPayloadExternal;
        const appVerdict = payload?.appIntegrity?.appRecognitionVerdict;
        const deviceVerdicts = payload?.deviceIntegrity?.deviceRecognitionVerdict ?? [];
        const packageName = payload?.requestDetails?.requestPackageName;
        const tokenAgeMs = Date.now() - Number(payload?.requestDetails?.timestampMillis ?? 0);

        if (packageName !== "io.github.nishian3695.bujit") {
          console.warn("exchangeIntegrityToken: package mismatch", packageName);
          res.status(403).json({error: "Package name mismatch"});
          return;
        }
        if (tokenAgeMs > 10 * 60 * 1000) {
          console.warn("exchangeIntegrityToken: token too old", tokenAgeMs);
          res.status(403).json({error: "Integrity token too old"});
          return;
        }
        if (appVerdict !== "PLAY_RECOGNIZED" || !deviceVerdicts.includes("MEETS_BASIC_INTEGRITY")) {
          console.warn("exchangeIntegrityToken: verdict rejected", {appVerdict, deviceVerdicts});
          res.status(403).json({error: "Integrity check failed"});
          return;
        }

        const APP_ID = "1:533939418471:android:e39cb96592f09e1c036bc2";
        const appCheckToken = await admin.appCheck().createToken(APP_ID, {ttlMillis: 3600000});
        res.json({token: appCheckToken.token, ttlMillis: appCheckToken.ttlMillis});
      } catch (e) {
        console.error("exchangeIntegrityToken error:", JSON.stringify(e.response?.data ?? e.message));
        res.status(500).json({error: "Integrity verification failed"});
      }
      return;
    }

    // Step 1: Verify App Check token (when enforcement is enabled).
    if (!await verifyAppCheck(req, res)) return;

    // Step 2: Verify Firebase ID token — blocks unauthenticated callers for all routes.
    const decodedToken = await verifyFirebaseToken(req, res);
    if (!decodedToken) return;

    // Step 3: Route /plaid/* to the Plaid handler.
    if (req.path.startsWith("/plaid/")) {
      await handlePlaidRequest(req, res, decodedToken);
      return;
    }

    // Step 4: Build the mTLS agent for Teller (used by both management and pass-through routes).
    const normalizePem = (pem) => pem.replace(/\r\n/g, "\n").replace(/\r/g, "\n").trimEnd() + "\n";
    const agent = new https.Agent({
      cert: normalizePem(tellerCert.value()),
      key: normalizePem(tellerKey.value()),
    });

    // Step 5: Route /teller/* to the Teller management handler.
    if (req.path.startsWith("/teller/")) {
      await handleTellerRequest(req, res, agent);
      return;
    }

    // Step 6: Legacy Teller pass-through for account/balance fetches (/accounts, /accounts/{id}/balances).
    const accessToken = req.headers["x-teller-token"];
    if (!accessToken) {
      res.status(401).send("Missing token");
      return;
    }
    try {
      const response = await axios.get("https://api.teller.io" + req.path, {
        httpsAgent: agent,
        auth: {username: accessToken, password: ""},
      });
      res.json(response.data);
    } catch (e) {
      const status = e.response?.status ?? 500;
      const errorCode = e.response?.data?.error?.code ?? "TELLER_ERROR";
      console.error("tellerProxy error:", errorCode, "status:", status);
      res.status(status).json({error: errorCode});
    }
  },
);
