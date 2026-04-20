#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_670_luxury_elite_colors_only"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) Gjør accent dynamisk: Elite får gullaccent
old = "    final accent = const Color(0xFFF0D48A);"
new = """    final accent = _selected == 'Elite'
        ? const Color(0xFFD4AF37)
        : const Color(0xFFF0D48A);"""

if old in text:
    text = text.replace(old, new, 1)
else:
    print("⚠️ Fant ikke accent-linjen. Hopper over den delen.")

# 2) Gjør luksus-shell rundt planvelgeren mer Elite når Elite er valgt
old_block = """                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF172033),
                            Color(0xFF1E293B),
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.34),
                          width: 1.2,
                        ),"""

new_block = """                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _selected == 'Elite'
                              ? const [
                                  Color(0xFF120F2A),
                                  Color(0xFF1F1B4D),
                                  Color(0xFF0F172A),
                                ]
                              : const [
                                  Color(0xFF0F172A),
                                  Color(0xFF172033),
                                  Color(0xFF1E293B),
                                ],
                        ),
                        border: Border.all(
                          color: (_selected == 'Elite'
                                  ? const Color(0xFFD4AF37)
                                  : accent)
                              .withValues(alpha: _selected == 'Elite' ? 0.52 : 0.34),
                          width: _selected == 'Elite' ? 1.4 : 1.2,
                        ),"""

if old_block in text:
    text = text.replace(old_block, new_block, 1)
else:
    print("⚠️ Fant ikke luksus-shell-blokken. Hopper over den delen.")

# 3) Gjør top-strip i shell mer Elite-luksus når Elite er valgt
old_block = """                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  accent.withValues(alpha: 0.18),
                                  accent.withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.24),
                              ),"""

new_block = """                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: _selected == 'Elite'
                                    ? [
                                        const Color(0xFFD4AF37).withValues(alpha: 0.24),
                                        const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                                      ]
                                    : [
                                        accent.withValues(alpha: 0.18),
                                        accent.withValues(alpha: 0.05),
                                      ],
                              ),
                              border: Border.all(
                                color: (_selected == 'Elite'
                                        ? const Color(0xFFD4AF37)
                                        : accent)
                                    .withValues(alpha: _selected == 'Elite' ? 0.34 : 0.24),
                              ),"""

if old_block in text:
    text = text.replace(old_block, new_block, 1)
else:
    print("⚠️ Fant ikke top-strip-blokken. Hopper over den delen.")

# 4) Litt sterkere Elite-tekst
text = text.replace(
    "                                            ? 'Elite — eksklusiv maksverdi'",
    "                                            ? 'Elite — luksusnivået'",
)
text = text.replace(
    "                                            ? 'Dypere premium-uttrykk, mer eksklusiv oversikt og tydelig fokus på total poengmaksimering.'",
    "                                            ? 'Mørkere luksusdesign, gullaccent og tydelig fokus på maksimal poengverdi.'",
)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Elite-fargene er gjort mer luksuriøse")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
