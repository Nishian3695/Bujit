const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const https = require("https");

setGlobalOptions({maxInstances: 10});

admin.initializeApp();

// Teller secrets (mTLS certificate + private key stored in Secret Manager)
const tellerCert = defineSecret("TELLER_CERT");
const tellerKey = defineSecret("TELLER_PRIVATE_KEY");

// Plaid secrets
//   PLAID_CLIENT_ID  : your Plaid client_id
//   PLAID_SECRET     : your Plaid secret (sandbox or production)
const plaidClientId = defineSecret("PLAID_CLIENT_ID");
const plaidSecret = defineSecret("PLAID_SECRET");

// "https://production.plaid.com" for production
// "https://sandbox.plaid.com" for sandbox
const PLAID_BASE_URL = "https://sandbox.plaid.com";

// Handles all /plaid/* requests routed from the main tellerProxy function.
async function handlePlaidRequest(req, res, decodedToken) {
  const clientId = plaidClientId.value();
  const secret = plaidSecret.value();

  try {
    // POST /plaid/link/token
    // Creates a Plaid Link token so the Android SDK can open the bank-linking flow.
    if (req.method === "POST" && req.path === "/plaid/link/token") {
      const response = await axios.post(`${PLAID_BASE_URL}/link/token/create`, {
        client_id: clientId,
        secret: secret,
        user: {client_user_id: decodedToken.uid},
        client_name: "Bujit",
        products: ["transactions", "balance"],
        country_codes: ["US"],
        language: "en",
      });
      res.json({link_token: response.data.link_token});
      return;
    }

    // POST /plaid/exchange
    // Exchanges the short-lived public_token (from the SDK) for a permanent access_token.
    // Body: { "public_token": "public-sandbox-..." }
    if (req.method === "POST" && req.path === "/plaid/exchange") {
      const {public_token: publicToken} = req.body;
      if (!publicToken) {
        res.status(400).json({error: "Missing public_token"});
        return;
      }
      const response = await axios.post(`${PLAID_BASE_URL}/item/public_token/exchange`, {
        client_id: clientId,
        secret: secret,
        public_token: publicToken,
      });
      res.json({access_token: response.data.access_token});
      return;
    }

    // All remaining Plaid routes require X-Plaid-Token (the permanent access_token).
    const accessToken = req.headers["x-plaid-token"];
    if (!accessToken) {
      res.status(401).json({error: "Missing X-Plaid-Token header"});
      return;
    }

    // GET /plaid/accounts
    // Returns all accounts for the given access_token, enriched with institution name
    // and balances, in the normalized format expected by PlaidBackendClient.
    if (req.method === "GET" && req.path === "/plaid/accounts") {
      // Fetch accounts (includes cached balances and institution_id).
      const accountsResp = await axios.post(`${PLAID_BASE_URL}/accounts/get`, {
        client_id: clientId,
        secret: secret,
        access_token: accessToken,
      });
      const {accounts, item} = accountsResp.data;

      // Resolve institution name from institution_id.
      let institutionName = "";
      try {
        const instResp = await axios.post(`${PLAID_BASE_URL}/institutions/get_by_id`, {
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
        // Use the cached balances from /accounts/get.
        // current maps to ledger (posted balance); available may be null for some account types.
        ledger: acct.balances.current != null ? acct.balances.current.toString() : "—",
        available: acct.balances.available != null ? acct.balances.available.toString() : "—",
      }));

      res.json(result);
      return;
    }

    // GET /plaid/accounts/{id}/balance
    // Returns a real-time balance for a single account (used for credit card refresh).
    const balanceMatch = req.path.match(/^\/plaid\/accounts\/([^/]+)\/balance$/);
    if (req.method === "GET" && balanceMatch) {
      const accountId = balanceMatch[1];
      const response = await axios.post(`${PLAID_BASE_URL}/accounts/balance/get`, {
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

    res.status(404).json({error: "Unknown Plaid route: " + req.path});
  } catch (e) {
    console.error("handlePlaidRequest error:", e.message, "status:", e.response?.status);
    res.status(e.response?.status ?? 500).json(
      e.response?.data ?? {error: e.message},
    );
  }
}

exports.tellerProxy = onRequest(
  {secrets: [tellerCert, tellerKey, plaidClientId, plaidSecret], invoker: "public"},
  async (req, res) => {
    // Step 1: Verify Firebase ID token — blocks unauthenticated callers for all routes.
    const idToken = req.headers["authorization"]?.split("Bearer ")[1];
    if (!idToken) {
      res.status(401).send("Unauthorized");
      return;
    }
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      console.error("Auth verification failed:", e.message);
      res.status(403).send("Forbidden");
      return;
    }

    // Step 2: Route /plaid/* to the Plaid handler; everything else goes to Teller.
    if (req.path.startsWith("/plaid/")) {
      await handlePlaidRequest(req, res, decodedToken);
      return;
    }

    // Step 3: Teller proxy (original logic — unchanged).
    const accessToken = req.headers["x-teller-token"];
    if (!accessToken) {
      res.status(401).send("Missing token");
      return;
    }

    const normalizePem = (pem) => pem.replace(/\r\n/g, "\n").replace(/\r/g, "\n").trimEnd() + "\n";
    const agent = new https.Agent({
      cert: normalizePem(tellerCert.value()),
      key: normalizePem(tellerKey.value()),
    });
    try {
      const response = await axios.get("https://api.teller.io" + req.path, {
        httpsAgent: agent,
        auth: {username: accessToken, password: ""},
      });
      res.json(response.data);
    } catch (e) {
      console.error("tellerProxy error:", e.message, "status:", e.response?.status);
      res.status(e.response?.status ?? 500).json(
        e.response?.data ?? {error: e.message},
      );
    }
  },
);
