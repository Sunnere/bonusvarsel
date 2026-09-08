// scripts/apply_uid_debug.mjs
//
// MIDLERTIDIG debug-linje: skriver ut den faktiske Firebase UID-en appen
// bruker akkurat nå. Fjernes etter feilsøking.
//
// Kjør med: node scripts/apply_uid_debug.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'services', 'entitlement_service.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('DEBUG-UID')) {
  console.error('FEIL: debug-linjen finnes allerede. Avbryter uten å endre noe.');
  process.exit(1);
}

const search = `      if (user == null) {
        debugPrint('EntitlementService.syncFromBackend: ingen innlogget bruker, hopper over');
        return;
      }`;

const replace = `      if (user == null) {
        debugPrint('EntitlementService.syncFromBackend: ingen innlogget bruker, hopper over');
        return;
      }

      // MIDLERTIDIG DEBUG-UID - fjernes etter feilsøking
      debugPrint('EntitlementService.syncFromBackend [DEBUG-UID]: uid=\${user.uid} email=\${user.email}');`;

const count = content.split(search).length - 1;
if (count === 0) {
  throw new Error('FEIL: fant ikke ankertekst. Kjør apply_auth_wait_fix.mjs først hvis du ikke allerede har gjort det.');
}
if (count > 1) {
  throw new Error(`FEIL: fant ankertekst ${count} ganger. Avbryter.`);
}

content = content.replace(search, replace);

const backupPath = FILE + `.bak_uid_debug.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: debug-linje lagt til (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: flutter analyze, deretter flutter run');
