import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'pubspec.yaml');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('version: 1.2.4+36')) {
  console.error('FEIL: allerede versjon 1.2.4+36. Avbryter.');
  process.exit(1);
}

const search = 'version: 1.2.0+31';
const replace = 'version: 1.2.4+36';

const count = content.split(search).length - 1;
if (count === 0) {
  throw new Error('FEIL: fant ikke "version: 1.2.0+31". Sjekk linjen manuelt.');
}
if (count > 1) {
  throw new Error(`FEIL: fant linjen ${count} ganger.`);
}

content = content.replace(search, replace);
fs.writeFileSync(FILE + `.bak_version_bump.${Date.now()}`, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');
console.log('OK: pubspec.yaml oppdatert til 1.2.4+36');
