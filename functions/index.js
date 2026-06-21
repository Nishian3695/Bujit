const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const https = require("https");

setGlobalOptions({maxInstances: 10});

admin.initializeApp();

const tellerCert = defineSecret("TELLER_CERT");
const tellerKey = defineSecret("TELLER_PRIVATE_KEY");

exports.tellerProxy = onRequest(
  {secrets: [tellerCert, tellerKey], invoker: "public"},
  async (req, res) => {
    // Verify Firebase ID token — blocks unauthenticated callers.
    const idToken = req.headers["authorization"]?.split("Bearer ")[1];
    if (!idToken) {
      res.status(401).send("Unauthorized");
      return;
    }
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      console.error("Auth verification failed:", e.message);
      res.status(403).send("Forbidden");
      return;
    }

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
