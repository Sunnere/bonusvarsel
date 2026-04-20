#!/usr/bin/env bash
set -euo pipefail

echo "==> 786_add_travel_use_module_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_786")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

if "_selectedTravelUse = 'Fly';" in text or "_buildTravelUseModule(BuildContext context)" in text:
    print("ℹ️ Reisemål/bruk-modul finnes allerede. Stopper for å unngå dobbeltpatch.")
    raise SystemExit(0)

# 1) Legg inn state rett etter class-start
class_anchor = "class _TravelPageState extends State<TravelPage> {"
if class_anchor not in text:
    print("❌ Fant ikke class-anchor for _TravelPageState")
    raise SystemExit(1)

state_insert = """class _TravelPageState extends State<TravelPage> {
  String _selectedTravelUse = 'Fly';
  static const List<String> _travelUseOptions = <String>[
    'Fly',
    'Hotell',
    'Leiebil',
  ];

"""
text = text.replace(class_anchor, state_insert, 1)

# 2) Legg inn helper-metoder før første hjelpefunksjon
method_anchor = "double _amount()"
if method_anchor not in text:
    print("❌ Fant ikke method-anchor: double _amount()")
    raise SystemExit(1)

methods_insert = r"""
  Widget _buildTravelUseModule(BuildContext context) {
    final theme = Theme.of(context);
    final destination = _destinationCtrl.text.trim().isEmpty
        ? 'Bangkok'
        : _destinationCtrl.text.trim();

    final headline = switch (_selectedTravelUse) {
      'Fly' => 'Bruk poeng på fly til $destination',
      'Hotell' => 'Bruk poeng på hotell i $destination',
      'Leiebil' => 'Bruk poeng på leiebil i $destination',
      _ => 'Bruk poeng smart i $destination',
    };

    final detail = switch (_selectedTravelUse) {
      'Fly' =>
        'Sjekk direktefly eller reiser med flere stopp. Dette er riktig sted å koble inn SAS og SkyTeam senere.',
      'Hotell' =>
        'Vis hotellvalg, poengbruk per natt og hvilke partnere som gir best verdi for oppholdet.',
      'Leiebil' =>
        'Vis leiebil-partnere, pris per dag og om det er bedre å betale med kort eller bruke poeng.',
      _ => 'Velg hva poengene skal brukes på.',
    };

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF27495A),
          width: 1,
        ),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _travelUseOptions.map((option) {
              final selected = option == _selectedTravelUse;

              final icon = switch (option) {
                'Fly' => Icons.flight_takeoff_rounded,
                'Hotell' => Icons.hotel_rounded,
                'Leiebil' => Icons.directions_car_filled_rounded,
                _ => Icons.star_rounded,
              };

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  if (_selectedTravelUse == option) return;
                  setState(() => _selectedTravelUse = option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2E5BFF)
                        : const Color(0xFF173244),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF8FB7FF)
                          : const Color(0xFF315264),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF132B39),
              borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD8E6ED),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedTravelUse == 'Fly'
                      ? 'Neste steg: ruter, poengpris, mellomlandinger og senere SAS/SkyTeam-visning.'
                      : _selectedTravelUse == 'Hotell'
                          ? 'Neste steg: netter, partnerhotell og verdi per poeng.'
                          : 'Neste steg: biltype, leieperiode og partnerpriser.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9FC0CF),
                    fontWeight: FontWeight.w700,
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
text = text.replace(method_anchor, methods_insert + method_anchor, 1)

# 3) Sett inn modulen rett under TravelValueCard
widget_anchor = """              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""
if widget_anchor not in text:
    print("❌ Fant ikke widget-anchor for TravelValueCard")
    raise SystemExit(1)

widget_insert = """              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
              _buildTravelUseModule(context),
"""
text = text.replace(widget_anchor, widget_insert, 1)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ La inn reisemål/bruk-modul trygt i travel_page.dart")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
