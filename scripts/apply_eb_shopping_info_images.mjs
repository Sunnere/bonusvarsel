// scripts/apply_eb_shopping_info_images.mjs
//
// Legger instruksjonsbilder inn i steg-detaljene på eb_shopping_page:
//   1. Importerer InfoImage-widgeten
//   2. Steg "Scan QR-koden i kassen" får bildet trumf-qr-kasse-kiwi
//   3. Steg "Sjekk Varsler og handle smart" får bildet telegram-varsel-eksempel
//   4. Detalj-visningen viser bildet over teksten når steget har en "image"-nøkkel
//
// Nye bilder på flere steg senere = bare legg til "image"-nøkkel i steget.
//
// Kjør med: node scripts/apply_eb_shopping_info_images.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'pages', 'eb_shopping_page.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('info_image.dart')) {
  console.error('FEIL: eb_shopping_page.dart er allerede patchet (fant "info_image.dart"). Avbryter uten å endre noe.');
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
  `import '../theme/app_theme.dart';`,
  `import '../theme/app_theme.dart';\nimport '../widgets/info_image.dart';`,
  'import InfoImage'
);

content = replaceOnce(
  content,
  `      "title": "Scan QR-koden i kassen",
      "short": "Dobler bonusen til 2% – gratis og enkelt",`,
  `      "title": "Scan QR-koden i kassen",
      "short": "Dobler bonusen til 2% – gratis og enkelt",
      "image": "trumf-qr-kasse-kiwi",`,
  'image på QR-steget'
);

content = replaceOnce(
  content,
  `      "title": "Sjekk Varsler og handle smart",
      "short": "Vi varsler deg når favorittbutikkene har bonus",`,
  `      "title": "Sjekk Varsler og handle smart",
      "short": "Vi varsler deg når favorittbutikkene har bonus",
      "image": "telegram-varsel-eksempel",`,
  'image på varsel-steget'
);

content = replaceOnce(
  content,
  `              child: Text(
                (step["detail"] as String).replaceAll("\\\\n", "\\n"),
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF8FAFC),
                    height: 1.7),
              ),`,
  `              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step["image"] != null) ...[
                    InfoImage(name: step["image"] as String),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    (step["detail"] as String).replaceAll("\\\\n", "\\n"),
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFF8FAFC),
                        height: 1.7),
                  ),
                ],
              ),`,
  'detalj-visning med bilde'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_info_images.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: eb_shopping_page.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Endringer:');
console.log('  1. import av InfoImage');
console.log('  2. QR-steget viser trumf-qr-kasse-kiwi');
console.log('  3. Varsel-steget viser telegram-varsel-eksempel');
console.log('  4. Detalj-visning utvidet med bilde-støtte');
console.log('');
console.log('Kjør nå: flutter analyze');
