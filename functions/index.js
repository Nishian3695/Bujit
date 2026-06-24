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

// Plaid secrets
const plaidClientId = defineSecret("PLAID_CLIENT_ID");
const plaidSecret = defineSecret("PLAID_SECRET");

// Plaid environment. 
// Set to "https://sandbox.plaid.com" for sandbox testing.
// Set to "https://production.plaid.com" for production.
// Deploy with: firebase functions:secrets:set PLAID_BASE_URL
// Defaults to sandbox.
const PLAID_BASE_URL = defineString("PLAID_BASE_URL", {default: "https://sandbox.plaid.com"});

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
  const secret = plaidSecret.value();
  const baseUrl = PLAID_BASE_URL.value();

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
      });
      return;
    }

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
  {secrets: [tellerCert, tellerKey, plaidClientId, plaidSecret], invoker: "public"},
  async (req, res) => {
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
