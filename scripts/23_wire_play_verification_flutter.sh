#!/usr/bin/env bash
set -euo pipefail

ENT_FILE="lib/services/entitlement_service.dart"
CHK_FILE="lib/services/checkout_service.dart"
BACKUP_DIR="scripts/backups"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "=== 1) Forhåndssjekker ==="
for f in "$ENT_FILE" "$CHK_FILE"; do
  if [ ! -f "$f" ]; then
    echo "❌ Fant ikke $f. Kjør fra roten av bonusvarsel-repoet."
    exit 1
  fi
done

if grep -q "verifyPlayPurchaseWithBackend" "$ENT_FILE"; then
  echo "✅ Allerede patchet (entitlement_service.dart) — hopper over."
  exit 0
fi

echo "=== 2) Backup ==="
mkdir -p "$BACKUP_DIR"
cp "$ENT_FILE" "$BACKUP_DIR/entitlement_service.dart.$STAMP.bak"
cp "$CHK_FILE" "$BACKUP_DIR/checkout_service.dart.$STAMP.bak"
echo "✅ Backup tatt av begge filer"

echo "=== 3) Legger til verifyPlayPurchaseWithBackend i entitlement_service.dart ==="
node - << 'NODE_EOF'
const fs = require("fs");
const file = "lib/services/entitlement_service.dart";
let src = fs.readFileSync(file, "utf8");

if (!src.includes("import 'package:cloud_functions/cloud_functions.dart';")) {
  const importAnchor = "import 'package:firebase_auth/firebase_auth.dart';";
  if (!src.includes(importAnchor)) {
    console.error("❌ Fant ikke forventet import-linje for firebase_auth i entitlement_service.dart");
    process.exit(1);
  }
  src = src.replace(
    importAnchor,
    importAnchor + "\nimport 'package:cloud_functions/cloud_functions.dart';"
  );
}

const anchor = "  Future<void> clear() async {";
if (!src.includes(anchor)) {
  console.error("❌ Fant ikke 'Future<void> clear() async {' i entitlement_service.dart");
  process.exit(1);
}

const method = `  /// Verifiserer et Google Play-kjøp server-side via Cloud Function
  /// verifyPlayPurchase, og oppdaterer entitlement med source='google_play'
  /// hvis aktivt. Feiler trygt: ved nettverksfeil beholdes lokal IAP-status
  /// uendret (unlock() med source='iap' er allerede kjørt før dette kalles).
  Future<void> verifyPlayPurchaseWithBackend(String purchaseToken, String productId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyPlayPurchase');
      final result = await callable.call({'purchaseToken': purchaseToken});
      final active = result.data?['active'] as bool? ?? false;
      final backendPlan = (result.data?['plan'] as String?) ?? 'free';

      if (active) {
        debugPrint('verifyPlayPurchaseWithBackend: bekreftet aktivt ($backendPlan) for \$productId');
        await unlock(productId, source: 'google_play');
      } else {
        debugPrint('verifyPlayPurchaseWithBackend: Google sier IKKE aktivt for \$productId (plan=$backendPlan) - beholder lokal iap-status');
      }
    } catch (e) {
      debugPrint('verifyPlayPurchaseWithBackend feilet (beholder lokal iap-status): \$e');
    }
  }

${anchor}`;

src = src.replace(anchor, method);
fs.writeFileSync(file, src);
console.log("✅ entitlement_service.dart patchet");
NODE_EOF

echo "=== 4) Kobler kallet inn i checkout_service.dart (Android-only) ==="
node - << 'NODE_EOF'
const fs = require("fs");
const file = "lib/services/checkout_service.dart";
let src = fs.readFileSync(file, "utf8");

if (src.includes("verifyPlayPurchaseWithBackend")) {
  console.log("✅ Allerede koblet inn i checkout_service.dart — hopper over");
  process.exit(0);
}

if (!src.includes("import 'dart:io'")) {
  src = src.replace("import 'dart:async';", "import 'dart:async';\nimport 'dart:io' show Platform;");
}

const anchor = `          await EntitlementService.instance.unlock(purchase.productID);
          debugPrint(
            'Unlocked plan=\${EntitlementService.instance.plan} via \${purchase.productID} (\${purchase.status.name})',
          );`;

if (!src.includes(anchor)) {
  console.error("❌ Fant ikke forventet unlock()-blokk i checkout_service.dart");
  process.exit(1);
}

const replacement = anchor + `
          if (Platform.isAndroid) {
            final token = purchase.verificationData.serverVerificationData;
            if (token.isNotEmpty) {
              await EntitlementService.instance.verifyPlayPurchaseWithBackend(
                token,
                purchase.productID,
              );
            } else {
              debugPrint('Android-kjøp uten serverVerificationData - hopper over backend-verifisering');
            }
          }`;

src = src.replace(anchor, replacement);
fs.writeFileSync(file, src);
console.log("✅ checkout_service.dart patchet");
NODE_EOF

echo "=== 5) Sjekker cloud_functions i pubspec.yaml ==="
if grep -q "cloud_functions:" pubspec.yaml; then
  echo "✅ cloud_functions finnes allerede i pubspec.yaml"
else
  echo "⚠️  cloud_functions mangler i pubspec.yaml — legg til manuelt:"
  echo "    cloud_functions: ^5.6.2"
fi

echo "=== 6) Grov strukturkontroll (balanserte { } ( )) ==="
for f in "$ENT_FILE" "$CHK_FILE"; do
  python3 - "$f" << 'PY_EOF'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
ob, cb = src.count("{"), src.count("}")
op, cp = src.count("("), src.count(")")
ok = (ob == cb) and (op == cp)
print(f"{'✅' if ok else '❌'} {path}: {{ {ob}/{cb} }}  ( {op}/{cp} )")
if not ok:
    sys.exit(1)
PY_EOF
done

echo ""
echo "=== Ferdig — VIKTIG neste steg ==="
echo "Dart/Flutter kunne ikke kjøres i scriptets testmiljø. Kjør selv:"
echo "  flutter analyze"
echo "  flutter pub get   (hvis cloud_functions manglet over)"
echo ""
echo "Deretter: test et ekte Android-testkjøp og sjekk loggen med:"
echo "  firebase functions:log --only verifyPlayPurchase"
