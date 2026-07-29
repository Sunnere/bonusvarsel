// scripts/apply_kalkulator_info_video.mjs
//
// Video-støtte i Trumf-kalkulatorens tips:
//   1. Importerer InfoVideo-widgeten
//   2. "Du er godt optimalisert!"-tipset får overførings-videoen
//   3. Tips-rendereren viser video når tipset har en 'video'-nøkkel
//
// Kjør med: node scripts/apply_kalkulator_info_video.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'pages', 'trumf_kalkulator_page.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('info_video.dart')) {
  console.error('FEIL: trumf_kalkulator_page.dart har allerede video-støtte. Avbryter uten å endre noe.');
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
  `import 'package:flutter/material.dart';`,
  `import 'package:flutter/material.dart';\nimport '../widgets/info_video.dart';`,
  'import InfoVideo'
);

content = replaceOnce(
  content,
  `        'desc': 'Husk å sette opp automatisk overføring til EuroBonus i Trumf-appen. '
            'Du får 35% mer poeng enn ved manuell overføring.',
        'gain': '',`,
  `        'desc': 'Husk å sette opp automatisk overføring til EuroBonus i Trumf-appen. '
            'Du får 35% mer poeng enn ved manuell overføring.',
        'video': 'trumf-bruk-bonus-overforing',
        'gain': '',`,
  'video på optimalisert-tipset'
);

content = replaceOnce(
  content,
  `        const SizedBox(height: 8),
        Text(t['desc'] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5)),
      ]),`,
  `        const SizedBox(height: 8),
        Text(t['desc'] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5)),
        if (t['video'] != null) ...[
          const SizedBox(height: 10),
          InfoVideo(name: t['video'] as String),
        ],
      ]),`,
  'video i tips-renderer'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_info_video.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: trumf_kalkulator_page.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: flutter analyze');
