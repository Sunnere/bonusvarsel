// scripts/apply_stripe_entitlement_patch.mjs
//
// Kobler Stripe-webhook og /v1/me inn i server.js.
// Kjør med: node scripts/apply_stripe_entitlement_patch.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'api', 'server.js');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('entitlementStore.init()')) {
  console.error('FEIL: server.js er allerede patchet (fant "entitlementStore.init()"). Avbryter uten å endre noe.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen endringer gjort.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter.`);
  }
  return content.replace(search, replace);
}

content = replaceOnce(
  content,
  `import * as deviceFavoritesStore from './lib/deviceFavoritesStore.js';`,
  `import * as deviceFavoritesStore from './lib/deviceFavoritesStore.js';\nimport * as entitlementStore from './lib/entitlementStore.js';\nimport { handleStripeWebhook } from './lib/stripeWebhook.js';\nimport { handleGetMe } from './lib/meHandler.js';`,
  'imports'
);

content = replaceOnce(
  content,
  `app.use(express.json({ limit: "256kb" }));`,
  `app.use(express.json({\n  limit: "256kb",\n  verify: (req, res, buf) => { req.rawBody = buf; },\n}));\n\nentitlementStore.init();\napp.post("/webhook/stripe", handleStripeWebhook);\napp.get("/v1/me", handleGetMe);`,
  'express.json + entitlement-ruter'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_stripe_entitlement.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: server.js oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: node --check api/server.js');
