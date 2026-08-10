// scripts/apply_entitlement_backend_sync.mjs
//
// Kobler EntitlementService til den EKSISTERENDE checkSubscription
// Cloud Function (functions/index.js) - ingen ny backend bygges.
//
// Kjør med: node scripts/apply_entitlement_backend_sync.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ENTITLEMENT_FILE = path.join(__dirname, '..', 'lib', 'services', 'entitlement_service.dart');
const MAIN_FILE = path.join(__dirname, '..', 'lib', 'main.dart');

const entitlementContent = fs.readFileSync(ENTITLEMENT_FILE, 'utf8');
const mainContent = fs.readFileSync(MAIN_FILE, 'utf8');

if (entitlementContent.includes('syncFromBackend')) {
  console.error('FEIL: entitlement_service.dart har allerede syncFromBackend(). Avbryter uten å endre noe.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen filer er endret.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter.`);
  }
  return content.replace(search, replace);
}

let newEntitlementContent = replaceOnce(
  entitlementContent,
  `  Future<void> clear() async {`,
  `  /// Henter faktisk abonnement-status fra den eksisterende
  /// checkSubscription Cloud Function (functions/index.js), og overstyrer
  /// lokal SharedPreferences-status hvis backend vet bedre.
  Future<void> syncFromBackend() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('checkSubscription');
      final result = await callable.call();
      final backendPlan = (result.data?['plan'] as String?) ?? 'free';

      if (backendPlan != _plan) {
        debugPrint('EntitlementService.syncFromBackend: lokal=$_plan backend=$backendPlan -> oppdaterer');
        await unlock(backendPlan);
      } else {
        debugPrint('EntitlementService.syncFromBackend: allerede synkronisert ($_plan)');
      }
    } catch (e) {
      debugPrint('EntitlementService.syncFromBackend feilet (beholder lokal status): $e');
    }
  }

  Future<void> clear() async {`,
  'syncFromBackend-metode'
);

let newMainContent = replaceOnce(
  mainContent,
  `  await EntitlementService.instance.load();`,
  `  await EntitlementService.instance.load();\n  // Ikke await - skal ikke forsinke appstart. Oppdaterer UI via\n  // notifyListeners() når (om) den er ferdig i bakgrunnen.\n  EntitlementService.instance.syncFromBackend();`,
  'kall syncFromBackend i main.dart'
);

const entBackup = ENTITLEMENT_FILE + `.bak_backend_sync.${Date.now()}`;
const mainBackup = MAIN_FILE + `.bak_backend_sync.${Date.now()}`;
fs.writeFileSync(entBackup, entitlementContent, 'utf8');
fs.writeFileSync(mainBackup, mainContent, 'utf8');
fs.writeFileSync(ENTITLEMENT_FILE, newEntitlementContent, 'utf8');
fs.writeFileSync(MAIN_FILE, newMainContent, 'utf8');

console.log('OK: entitlement_service.dart og main.dart oppdatert');
console.log(`Backup: ${path.basename(entBackup)}, ${path.basename(mainBackup)}`);
console.log('');
console.log('Kjør nå: flutter analyze');
