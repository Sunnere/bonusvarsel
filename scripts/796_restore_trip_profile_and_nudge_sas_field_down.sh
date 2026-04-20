#!/usr/bin/env bash
set -euo pipefail

echo "==> 796_restore_trip_profile_and_nudge_sas_field_down"

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
bak = path.with_name(path.name + f".bak_{stamp}_796")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Legg inn state hvis den mangler
state_anchor = "  String _selectedProgram = 'SAS EuroBonus';\n"
state_insert = """  String _selectedProgram = 'SAS EuroBonus';

  final TextEditingController _destinationCtrl = TextEditingController(text: 'Bangkok');
  static const List<String> _tripThemes = <String>[
    'Strand',
    'Vinter',
    'By',
    'Familie',
  ];
  String _selectedTripTheme = 'Strand';
  int _adults = 2;
  int _children = 2;
  int _days = 14;
"""

if "_destinationCtrl" not in text:
    if state_anchor not in text:
        print("❌ Fant ikke state-ankeret for _selectedProgram.")
        print("Kjør og send:")
        print("  sed -n '1,60p' lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(state_anchor, state_insert, 1)
    print("✅ La inn reiseprofil-state")

# 2) dispose for destinationCtrl
dispose_anchor = "    _sasPointsCtrl.dispose();\n"
if "_destinationCtrl.dispose();" not in text and dispose_anchor in text:
    text = text.replace(
        dispose_anchor,
        "    _destinationCtrl.dispose();\n" + dispose_anchor,
        1,
    )
    print("✅ La inn _destinationCtrl.dispose()")

# 3) Legg inn Reiseprofil før Din poengstatus
panel_anchor = """              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Din poengstatus',
"""

trip_panel = """              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Velg type tur, reisemål og antall personer før du ser poengstatus og forslag.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B7077),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _destinationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reisemål',
                        hintText: 'f.eks Bangkok',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      decoration: const InputDecoration(
                        labelText: 'Type tur',
                        border: OutlineInputBorder(),
                      ),
                      items: _tripThemes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedTripTheme = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _adults,
                            decoration: const InputDecoration(
                              labelText: 'Voksne',
                              border: OutlineInputBorder(),
                            ),
                            items: List<int>.generate(6, (i) => i + 1)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _adults = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _children,
                            decoration: const InputDecoration(
                              labelText: 'Barn',
                              border: OutlineInputBorder(),
                            ),
                            items: List<int>.generate(6, (i) => i)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _children = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _days,
                      decoration: const InputDecoration(
                        labelText: 'Antall dager',
                        border: OutlineInputBorder(),
                      ),
                      items: const [3, 5, 7, 10, 14, 21]
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d dager'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _days = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
""" + panel_anchor

if "Reiseprofil" not in text:
    if panel_anchor not in text:
        print("❌ Fant ikke 'Din poengstatus'-ankeret.")
        print("Kjør og send:")
        print("  grep -n \"Din poengstatus\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(panel_anchor, trip_panel, 1)
    print("✅ La inn Reiseprofil over Din poengstatus")

# 4) Flytt SAS-feltet litt ned visuelt
old_field = """                      decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        border: OutlineInputBorder(),
                      ),
"""
new_field = """                      decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                        border: const OutlineInputBorder(),
                      ),
"""

if old_field in text:
    text = text.replace(old_field, new_field, 1)
    print("✅ Flyttet SAS-feltet litt lenger ned")
else:
    print("ℹ️ Fant ikke eksakt SAS InputDecoration-blokk, hopper over felt-justering")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 796 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
