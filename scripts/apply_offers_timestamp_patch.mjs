// scripts/apply_offers_timestamp_patch.mjs
//
// Legger til lastUpdatedAt (fra state.lastGoodCampaignsAt) i /v1/offers-
// responsen, slik at appen kan vise "Sist oppdatert X min siden".
//
// Kjør med: node scripts/apply_offers_timestamp_patch.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'api', 'server.js');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('lastUpdatedAt: state.lastGoodCampaignsAt')) {
  console.error('FEIL: /v1/offers er allerede patchet. Avbryter uten å endre noe.');
  process.exit(1);
}

const search = `app.get("/v1/offers", (req, res) => {
  res.json({
    ok: true,
    offers: state.seededOffers || [],
    count: (state.seededOffers || []).length,
  });
});`;

const replace = `app.get("/v1/offers", (req, res) => {
  res.json({
    ok: true,
    offers: state.seededOffers || [],
    count: (state.seededOffers || []).length,
    lastUpdatedAt: state.lastGoodCampaignsAt,
  });
});`;

const count = content.split(search).length - 1;
if (count === 0) {
  throw new Error('FEIL: fant ikke /v1/offers-handleren. Ingen endringer gjort.');
}
if (count > 1) {
  throw new Error(`FEIL: fant handleren ${count} ganger. Avbryter.`);
}

content = content.replace(search, replace);

const backupPath = FILE + `.bak_offers_timestamp.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: /v1/offers sender nå lastUpdatedAt (backup: ${path.basename(backupPath)})`);
