#!/usr/bin/env bash
set -euo pipefail

echo "==> 788_upgrade_travel_use_module_to_premium"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_788")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

pattern = re.compile(
    r"  Widget _buildTravelUseModule\(BuildContext context\) \{.*?\n  \}\n\n(?=double _amount\(\))",
    re.DOTALL,
)

replacement = """  Widget _buildTravelUseModule(BuildContext context) {
    final theme = Theme.of(context);
    final destination = 'Bangkok';

    final headline = switch (_selectedTravelUse) {
      'Fly' => 'Bruk poeng på fly til $destination',
      'Hotell' => 'Bruk poeng på hotell i $destination',
      'Leiebil' => 'Bruk poeng på leiebil i $destination',
      _ => 'Bruk poeng smart i $destination',
    };

    final detail = switch (_selectedTravelUse) {
      'Fly' =>
        'Se direktefly eller reiser med flere stopp. Dette er riktig sted å koble inn SAS og SkyTeam senere.',
      'Hotell' =>
        'Vis hotellvalg, poengbruk per natt og hvilke partnere som gir best verdi for oppholdet.',
      'Leiebil' =>
        'Vis leiebil-partnere, pris per dag og om det er bedre å betale med kort eller bruke poeng.',
      _ => 'Velg hva poengene skal brukes på.',
    };

    IconData iconFor(String option) {
      switch (option) {
        case 'Fly':
          return Icons.flight_takeoff_rounded;
        case 'Hotell':
          return Icons.hotel_rounded;
        case 'Leiebil':
          return Icons.directions_car_filled_rounded;
        default:
          return Icons.star_rounded;
      }
    }

    Color accentFor(String option) {
      switch (option) {
        case 'Fly':
          return const Color(0xFF5ED0E0);
        case 'Hotell':
          return const Color(0xFFFFD76A);
        case 'Leiebil':
          return const Color(0xFF7ED957);
        default:
          return const Color(0xFF5ED0E0);
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF081B2E),
            Color(0xFF0E2A3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF284764),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hva vil du bruke poengene på?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Velg bruk først. Deretter kan appen sende deg videre til riktig fly-, hotell- eller leiebilflyt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFD7E6EF),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _travelUseOptions.map((option) {
              final selected = option == _selectedTravelUse;
              final accent = accentFor(option);

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  if (_selectedTravelUse == option) return;
                  setState(() => _selectedTravelUse = option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.95),
                              accent.withValues(alpha: 0.70),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF143145),
                              Color(0xFF17384D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? Colors.white : const Color(0xFF315264),
                      width: selected ? 1.2 : 1.0,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconFor(option),
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF122B39),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF27495A),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD8E6ED),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17384D),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _selectedTravelUse == 'Fly'
                        ? 'Neste steg: ruter, poengpris og mellomlandinger'
                        : _selectedTravelUse == 'Hotell'
                            ? 'Neste steg: netter, partnerhotell og verdi per poeng'
                            : 'Neste steg: biltype, leieperiode og partnerpriser',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFAED1DF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

"""

new_text, count = pattern.subn(replacement, text, count=1)

if count == 0:
    print("❌ Fant ikke _buildTravelUseModule for utskifting.")
    print("Kjør og send:")
    print("  sed -n '60,180p' lib/pages/travel_page.dart")
    raise SystemExit(1)

if new_text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(new_text)
print("✅ Oppgraderte reisemål/bruk-modulen til premium-versjon")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
