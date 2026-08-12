// scripts/apply_downgrade_safeguard.mjs
//
// KRITISK SIKKERHETSFIKS: syncFromBackend() spør kun checkSubscription,
// som kun kjenner til Stripe-abonnementer. Uten denne fiksen ville en
// bruker som betalte via App Store eller Google Play bli feilaktig
// nedgradert til 'free' ved neste app-oppstart.
//
// Fiksen: sporer eksplisitt HVOR den lokale statusen kom fra ('iap' eller
// 'backend'). syncFromBackend() får lov til å oppgradere alltid, men
// aldri nedgradere en IAP-bekreftet bruker.
//
// Kjør med: node scripts/apply_downgrade_safeguard.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'services', 'entitlement_service.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('_keySource')) {
  console.error('FEIL: entitlement_service.dart har allerede kilde-sporing. Avbryter uten å endre noe.');
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
  `  static const _keyProductId = 'entitlement_product_id';`,
  `  static const _keyProductId = 'entitlement_product_id';\n  static const _keySource = 'entitlement_source';`,
  'ny nøkkel for kilde'
);

content = replaceOnce(
  content,
  `  String _plan = 'free';
  String _productId = '';`,
  `  String _plan = 'free';
  String _productId = '';
  String _source = 'none'; // 'iap' (App Store/Google Play), 'backend' (Stripe via checkSubscription), 'none'`,
  'nytt kildefelt'
);

content = replaceOnce(
  content,
  `    _plan = prefs.getString(_keyPlan) ?? 'free';
    _productId = prefs.getString(_keyProductId) ?? '';`,
  `    _plan = prefs.getString(_keyPlan) ?? 'free';
    _productId = prefs.getString(_keyProductId) ?? '';
    _source = prefs.getString(_keySource) ?? 'none';`,
  'load() leser kilde'
);

content = replaceOnce(
  content,
  `  Future<void> unlock(String productId) async {
    _productId = productId;`,
  `  Future<void> unlock(String productId, {String source = 'iap'}) async {
    _productId = productId;
    _source = source;`,
  'unlock() med kilde-parameter'
);

content = replaceOnce(
  content,
  `    await prefs.setString(_keyPlan, _plan);
    await prefs.setString(_keyProductId, _productId);`,
  `    await prefs.setString(_keyPlan, _plan);
    await prefs.setString(_keyProductId, _productId);
    await prefs.setString(_keySource, _source);`,
  'lagre kilde'
);

content = replaceOnce(
  content,
  `      if (backendPlan != _plan) {
        debugPrint('EntitlementService.syncFromBackend: lokal=\$_plan backend=\$backendPlan -> oppdaterer');
        await unlock(backendPlan);
      } else {
        debugPrint('EntitlementService.syncFromBackend: allerede synkronisert (\$_plan)');
      }`,
  `      if (backendPlan != _plan) {
        const tierRank = {'free': 0, 'premium': 1, 'elite': 2};
        final isDowngrade = (tierRank[backendPlan] ?? 0) < (tierRank[_plan] ?? 0);

        if (isDowngrade && _source == 'iap') {
          debugPrint('EntitlementService.syncFromBackend: backend sier \$backendPlan, men lokal status (\$_plan) er IAP-bekreftet - beholder lokal status');
          return;
        }

        debugPrint('EntitlementService.syncFromBackend: lokal=\$_plan (kilde=\$_source) backend=\$backendPlan -> oppdaterer');
        await unlock(backendPlan, source: 'backend');
      } else {
        debugPrint('EntitlementService.syncFromBackend: allerede synkronisert (\$_plan)');
      }`,
  'nedgraderings-sperre i syncFromBackend'
);

content = replaceOnce(
  content,
  `  Future<void> clear() async {
    _plan = 'free';
    _productId = '';`,
  `  Future<void> clear() async {
    _plan = 'free';
    _productId = '';
    _source = 'none';`,
  'clear() nullstiller kilde'
);

content = replaceOnce(
  content,
  `    await prefs.remove(_keyPlan);
    await prefs.remove(_keyProductId);`,
  `    await prefs.remove(_keyPlan);
    await prefs.remove(_keyProductId);
    await prefs.remove(_keySource);`,
  'clear() fjerner kilde-nøkkel'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_downgrade_safeguard.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: entitlement_service.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: flutter analyze');
