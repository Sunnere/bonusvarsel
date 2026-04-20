#!/usr/bin/env bash
set -euo pipefail

mkdir -p scripts

cat > scripts/release_checklist_run.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "== Bonusvarsel release checklist run =="

echo
echo "[1/6] flutter analyze"
flutter analyze

echo
echo "[2/6] verifiser launch docs"
test -f docs/launch/release_checklist.md
test -f docs/launch/app_store_text.md
test -f docs/launch/play_store_text.md
test -f docs/launch/privacy_policy.md
echo "✅ launch docs finnes"

echo
echo "[3/6] sjekk at alerts-side finnes"
test -f lib/pages/bonusvarsel_alerts_page.dart
echo "✅ alerts-side finnes"

echo
echo "[4/6] sjekk at Dev Hub gating finnes"
grep -n "_devHubEnabled" lib/pages/bonusvarsel_dev_hub_page.dart >/dev/null
grep -n "ENABLE_DEV_HUB" lib/pages/bonusvarsel_dev_hub_page.dart >/dev/null
echo "✅ Dev Hub gating funnet"

echo
echo "[5/6] sjekk at release-scripts finnes"
test -f scripts/run_prod_like_web.sh
test -f scripts/verify_dev_hub_hidden.sh
test -f scripts/release_snapshot.sh
echo "✅ release-scripts finnes"

echo
echo "[6/6] oppsummering"
echo "✅ Release-basics ser OK ut"
SH

cat > scripts/run_prod_like_web.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Kjører Bonusvarsel i prod-lignende modus =="
echo "Dev Hub skal være skjult når ENABLE_DEV_HUB ikke settes."

flutter run -d chrome \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=API_BASE=http://127.0.0.1:8081
SH

cat > scripts/verify_dev_hub_hidden.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"

echo "== Verifiserer at Dev Hub er gated i prod =="
grep -n "_devHubEnabled" "$FILE"
grep -n "ENABLE_DEV_HUB" "$FILE"
grep -n "Dev Hub er deaktivert i denne byggen." "$FILE"

echo
echo "✅ Kode for å skjule Dev Hub i prod finnes"
echo "Kjør deretter scripts/run_prod_like_web.sh og bekreft i UI"
SH

cat > scripts/release_snapshot.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="tmp/release_snapshot_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p tmp

{
  echo "== Bonusvarsel release snapshot =="
  echo "Dato: $(date)"
  echo
  echo "-- git status --"
  git status --short || true
  echo
  echo "-- flutter analyze --"
  flutter analyze || true
  echo
  echo "-- launch docs --"
  ls -1 docs/launch || true
  echo
  echo "-- release scripts --"
  ls -1 scripts/release_checklist_run.sh \
        scripts/run_prod_like_web.sh \
        scripts/verify_dev_hub_hidden.sh \
        scripts/release_snapshot.sh 2>/dev/null || true
} | tee "$OUT"

echo
echo "✅ Snapshot lagret i $OUT"
SH

chmod +x scripts/release_checklist_run.sh
chmod +x scripts/run_prod_like_web.sh
chmod +x scripts/verify_dev_hub_hidden.sh
chmod +x scripts/release_snapshot.sh

echo "✅ Opprettet:"
echo " - scripts/release_checklist_run.sh"
echo " - scripts/run_prod_like_web.sh"
echo " - scripts/verify_dev_hub_hidden.sh"
echo " - scripts/release_snapshot.sh"
