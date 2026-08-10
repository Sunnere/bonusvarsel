// scripts/apply_auth_wait_fix.mjs
//
// Fikser en sannsynlig race condition: ved kaldstart kan
// FirebaseAuth.instance.currentUser fortsatt være null et øyeblikk mens
// Firebase gjenoppretter innloggingsøkten. Fiksen: vent eksplisitt på
// authStateChanges().first før checkSubscription-kallet.
//
// Kjør med: node scripts/apply_auth_wait_fix.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'services', 'entitlement_service.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('authStateChanges().first')) {
  console.error('FEIL: entitlement_service.dart har allerede auth-wait-fiksen. Avbryter uten å endre noe.');
  process.exit(1);
}

if (!content.includes('syncFromBackend')) {
  console.error('FEIL: fant ikke syncFromBackend() - kjør apply_entitlement_backend_sync.mjs først.');
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
  `import 'package:cloud_functions/cloud_functions.dart';`,
  `import 'package:cloud_functions/cloud_functions.dart';\nimport 'package:firebase_auth/firebase_auth.dart';`,
  'import firebase_auth'
);

content = replaceOnce(
  content,
  `  Future<void> syncFromBackend() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('checkSubscription');`,
  `  Future<void> syncFromBackend() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) {
        debugPrint('EntitlementService.syncFromBackend: ingen innlogget bruker, hopper over');
        return;
      }

      final callable = FirebaseFunctions.instance.httpsCallable('checkSubscription');`,
  'vent på authStateChanges'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_auth_wait.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: entitlement_service.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: flutter analyze');
