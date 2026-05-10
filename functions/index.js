const functions = require("firebase-functions");
const crypto = require("crypto");
const { v4: uuidv4 } = require("uuid");
const fs = require("fs");
const path = require("path");

// Last inn .p8-nøkkelen – legg filen i functions/keys/SubscriptionKey.p8
const KEY_ID = "WNU3742ZH9";
const BUNDLE_ID = "com.royrotvold.bonusvarsel";

function loadPrivateKey() {
  const keyPath = path.join(__dirname, "keys", "SubscriptionKey.p8");
  return fs.readFileSync(keyPath, "utf8");
}

exports.signPromoOffer = functions.https.onCall(async (data, context) => {
  // Krev innlogging
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Må være innlogget.");
  }

  const { productId, offerId } = data;

  if (!productId || !offerId) {
    throw new functions.https.HttpsError("invalid-argument", "productId og offerId er påkrevd.");
  }

  const appBundleId = BUNDLE_ID;
  const keyId = KEY_ID;
  const nonce = uuidv4().toLowerCase();
  const timestamp = Date.now();

  // Payload som signeres
  const payload = `${appBundleId}\u2063${keyId}\u2063${productId}\u2063${offerId}\u2063${nonce}\u2063${timestamp}`;

  const privateKey = loadPrivateKey();
  const sign = crypto.createSign("SHA256");
  sign.update(payload);
  sign.end();
  const signature = sign.sign({ key: privateKey, dsaEncoding: "ieee-p1363" }, "base64");

  return {
    keyId,
    nonce,
    timestamp,
    signature,
  };
});
