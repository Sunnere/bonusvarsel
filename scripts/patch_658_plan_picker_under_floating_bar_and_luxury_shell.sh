#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_658_plan_picker_under_floating_bar_and_luxury_shell"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) La innholdet kunne scrolle under den flytende oppgrader-fanen
old_padding = "                  padding: EdgeInsets.fromLTRB(16, 16, 16, isMobile ? 98 : 24),"
new_padding = "                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),"

if old_padding in text:
    text = text.replace(old_padding, new_padding, 1)
else:
    print("⚠️ Fant ikke eksakt ListView-padding. Hopper over den delen.")

# 2) Gjør Premium/Elite-området mer luksuspreget uten å tukle med intern logikk i _PlanPicker
old_block = """                    _PlanPicker(
                      accent: accent,
                      selected: _selected,
                      onSelect: _select,
                      onCheckout: _checkout,
                    ),

                    const SizedBox(height: 14),"""

new_block = """                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
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
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  accent.withValues(alpha: 0.18),
                                  accent.withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.42),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: Icon(
                                    _selected == 'Elite'
                                        ? Icons.workspace_premium_rounded
                                        : Icons.auto_awesome_rounded,
                                    color: accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selected == 'Elite'
                                            ? 'Elite — maks verdi'
                                            : 'Premium — smartere opptjening',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selected == 'Elite'
                                            ? 'Mer eksklusiv visning og tydeligere fokus på total poengmaksimering.'
                                            : 'Et renere løft for SAS Shopping og bedre oversikt over gevinst.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.76),
                                          fontSize: 12.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PlanPicker(
                            accent: accent,
                            selected: _selected,
                            onSelect: _select,
                            onCheckout: _checkout,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),"""

if old_block not in text:
    print("❌ Fant ikke _PlanPicker-blokken. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old_block, new_block, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Premium/Elite-seksjonen kan nå scrolle under flytende fane og har fått luksus-shell")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
