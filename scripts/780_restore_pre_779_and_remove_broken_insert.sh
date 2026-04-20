#!/usr/bin/env bash
set -euo pipefail

echo "==> 780_restore_pre_779_and_remove_broken_insert"

TARGET="lib/pages/travel_page.dart"

if [[ ! -f "$TARGET" ]]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

LATEST_779_BACKUP="$(ls -1t lib/pages/travel_page.dart.bak_*_779 2>/dev/null | head -1 || true)"

if [[ -n "$LATEST_779_BACKUP" ]]; then
  echo "Fant 779-backup:"
  echo "  $LATEST_779_BACKUP"

  STAMP="$(date +%Y%m%d_%H%M%S)"
  cp "$TARGET" "${TARGET}.bak_${STAMP}_780_before_restore"
  cp "$LATEST_779_BACKUP" "$TARGET"

  echo "✅ Reverterte travel_page.dart til backup fra før 779."
  echo
  echo "Kjør nå:"
  echo "  flutter analyze"
  echo "  flutter run -d macos"
  exit 0
fi

echo "Ingen 779-backup funnet. Prøver å fjerne den ødelagte insert-blokka direkte ..."

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_780_before_direct_cleanup")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

broken = """

              // 🔥 HERO + INTRO (SAFE INSERT)
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/travel/hero_beach.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xCC0D1B2A),
                        Color(0x880D1B2A),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Planlegg reisen smartere ✈️',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Se hva du mangler av poeng før du bestiller',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7F8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Familietur-planlegger',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Planlegg familiebehov, estimer poeng og finn hvilke kjøp som gir mest verdi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
"""

if broken in text:
    text = text.replace(broken, "", 1)
else:
    print("❌ Fant ikke den eksakte 779-blokka i filen.")
    raise SystemExit(1)

if text == orig:
    print("❌ Ingen endringer gjort.")
    raise SystemExit(1)

path.write_text(text)
print("✅ Fjernet ødelagt 779-insert direkte.")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
