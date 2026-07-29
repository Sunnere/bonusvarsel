// scripts/apply_eb_shopping_info_videos.mjs
//
// Bygger videre på bilde-støtten: steg kan nå også ha en "video"-nøkkel.
// Kjør med: node scripts/apply_eb_shopping_info_videos.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'pages', 'eb_shopping_page.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('info_video.dart')) {
  console.error('FEIL: eb_shopping_page.dart har allerede video-støtte. Avbryter uten å endre noe.');
  process.exit(1);
}

if (!content.includes('info_image.dart')) {
  console.error('FEIL: bilde-patchen (apply_eb_shopping_info_images.mjs) må kjøres først. Avbryter.');
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
  `import '../widgets/info_image.dart';`,
  `import '../widgets/info_image.dart';\nimport '../widgets/info_video.dart';`,
  'import InfoVideo'
);

content = replaceOnce(
  content,
  `      "title": "Bli SAS EuroBonus-medlem",
      "short": "Gratis å melde seg inn – ta 2 minutter nå",`,
  `      "title": "Bli SAS EuroBonus-medlem",
      "short": "Gratis å melde seg inn – ta 2 minutter nå",
      "video": "medlemskap-trumf-sas-guide",`,
  'video på SAS-steget'
);

content = replaceOnce(
  content,
  `      "title": "Bli Trumf-medlem",
      "short": "Gratis å melde seg inn – ta 2 minutter nå",`,
  `      "title": "Bli Trumf-medlem",
      "short": "Gratis å melde seg inn – ta 2 minutter nå",
      "video": "medlemskap-trumf-sas-guide",`,
  'video på Trumf-steget'
);

content = replaceOnce(
  content,
  `                  if (step["image"] != null) ...[
                    InfoImage(name: step["image"] as String),
                    const SizedBox(height: 12),
                  ],`,
  `                  if (step["image"] != null) ...[
                    InfoImage(name: step["image"] as String),
                    const SizedBox(height: 12),
                  ],
                  if (step["video"] != null) ...[
                    InfoVideo(name: step["video"] as String),
                    const SizedBox(height: 12),
                  ],`,
  'video i detalj-visning'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_info_videos.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: eb_shopping_page.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: flutter analyze');
