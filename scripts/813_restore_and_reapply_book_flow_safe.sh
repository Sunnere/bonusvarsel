#!/usr/bin/env bash
set -euo pipefail

echo "==> 813_restore_and_reapply_book_flow_safe"

TARGET="lib/pages/travel_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

BACKUP_FILE="$(ls -1t lib/pages/travel_page.dart.bak_*_813 2>/dev/null | head -1 || true)"
if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Fant ikke backup fra 813"
  echo "Kjør og send:"
  echo "  ls -1t lib/pages/travel_page.dart.bak_* | head -20"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_before_restore_813_fix"

cp "$TARGET" "$BROKEN_BAK"
cp "$BACKUP_FILE" "$TARGET"

echo "✅ Gjenopprettet fra: $BACKUP_FILE"
echo "🗂 Backup av ødelagt fil: $BROKEN_BAK"

python3 <<'PY'
from pathlib import Path

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

old_block = """    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E1E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
"""

new_block = """    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE7F4F7),
            Color(0xFFF8FBFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E1E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
"""

if old_block not in text:
    print("❌ Fant ikke eksakt Book/bruk-container å oppgradere.")
    print("Kjør og send:")
    print("  sed -n '140,260p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_block, new_block, 1)

text = text.replace(
    "primaryCta = 'Sjekk SAS-fly';",
    "primaryCta = 'Start booking med SAS →';",
    1,
)

text = text.replace(
    "secondaryCta = 'Se partnerlogikk';",
    "secondaryCta = 'Sammenlign partnere';",
    1,
)

text = text.replace(
    "SAS først, deretter relevante partnere hvis tilgjengelighet eller poengbruk er bedre.",
    "👉 Start med SAS. Bytt til partner kun hvis du får bedre poengverdi eller tilgjengelighet.",
    1,
)

text = text.replace(
    "Start med fly for",
    "Beste strategi: start med fly for",
    1,
)

if text == orig:
    print("❌ Ingen trygg endring ble gjort.")
    raise SystemExit(1)

path.write_text(text)
print("✅ Presis Book/bruk-oppgradering lagt inn")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
