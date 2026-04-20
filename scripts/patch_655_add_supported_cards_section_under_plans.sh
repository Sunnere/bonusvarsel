#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_655_add_supported_cards_section_under_plans"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

old = """                    _PlanPicker(
                      accent: accent,
                      selected: _selected,
                      onSelect: _select,
                      onCheckout: _checkout,
                    ),

                    const SizedBox(height: 18),"""

new = """                    _PlanPicker(
                      accent: accent,
                      selected: _selected,
                      onSelect: _select,
                      onCheckout: _checkout,
                    ),

                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: const Color(0xFF0F172A),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Icon(
                                  Icons.credit_card_rounded,
                                  color: accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kort vi støtter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Se kort og programmer vi bygger rundt for å maksimere poengverdien.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.78),
                                        fontSize: 12.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Container(
                                width: isMobile ? double.infinity : 195,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'SAS Amex',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sterk verdi for deg som vil kombinere kortopptjening med SAS-flybonus.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.credit_score_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'SAS Mastercard',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Relevant for daglig bruk og opptjening mot EuroBonus over tid.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.language_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Visa / SAS-partnere',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Gir plass til Visa-baserte kort og partnere som inngår i SAS-løpet.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.savings_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Trumf-kort',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'For deg som vil fange opp dagligvare- og Trumf-verdi som kan konverteres videre.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),"""

if old not in text:
    print("❌ Fant ikke _PlanPicker-blokken. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old, new, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ La inn 'Kort vi støtter'-seksjon under planene")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
