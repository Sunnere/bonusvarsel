#!/usr/bin/env bash
set -euo pipefail

echo "==> 811_reiseprofil_inline_choices_exact_live_block"

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
bak = path.with_name(path.name + f".bak_{stamp}_811")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

start_marker = """                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,"""

end_marker = """                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F4E8),"""

start = text.find(start_marker)
if start == -1:
    print("❌ Fant ikke start på Reiseprofil-valgene")
    print("Kjør og send:")
    print("  sed -n '920,1065p' lib/pages/travel_page.dart")
    raise SystemExit(1)

end = text.find(end_marker, start)
if end == -1:
    print("❌ Fant ikke slutten etter Reiseprofil-valgene")
    print("Kjør og send:")
    print("  sed -n '920,1095p' lib/pages/travel_page.dart")
    raise SystemExit(1)

replacement = """                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4E1E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type tur',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF27414A),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tripThemes.map((t) {
                              final selected = t == _selectedTripTheme;
                              return ChoiceChip(
                                label: Text(
                                  t,
                                  style: TextStyle(
                                    color: const Color(0xFF162E35),
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: const Color(0xFFD9EEF1),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF6CBCCA)
                                      : const Color(0xFFD4E1E5),
                                ),
                                onSelected: (_) => setState(() => _selectedTripTheme = t),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F8F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD4E1E5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voksne',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF27414A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List<int>.generate(6, (i) => i + 1).map((v) {
                                    final selected = v == _adults;
                                    return ChoiceChip(
                                      label: Text(
                                        '$v',
                                        style: TextStyle(
                                          color: const Color(0xFF162E35),
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                        ),
                                      ),
                                      selected: selected,
                                      selectedColor: const Color(0xFFD9EEF1),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF6CBCCA)
                                            : const Color(0xFFD4E1E5),
                                      ),
                                      onSelected: (_) => setState(() => _adults = v),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F8F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD4E1E5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Barn',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF27414A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List<int>.generate(6, (i) => i).map((v) {
                                    final selected = v == _children;
                                    return ChoiceChip(
                                      label: Text(
                                        '$v',
                                        style: TextStyle(
                                          color: const Color(0xFF162E35),
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                        ),
                                      ),
                                      selected: selected,
                                      selectedColor: const Color(0xFFD9EEF1),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF6CBCCA)
                                            : const Color(0xFFD4E1E5),
                                      ),
                                      onSelected: (_) => setState(() => _children = v),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4E1E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antall dager',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF27414A),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dayOptions.map((d) {
                              final selected = d == _days;
                              return ChoiceChip(
                                label: Text(
                                  '$d dager',
                                  style: TextStyle(
                                    color: const Color(0xFF162E35),
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: const Color(0xFFD9EEF1),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF6CBCCA)
                                      : const Color(0xFFD4E1E5),
                                ),
                                onSelected: (_) => setState(() => _days = d),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
"""

new_text = text[:start] + replacement + text[end:]

if new_text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(new_text)
print("✅ 811 ferdig: Reiseprofil bruker nå inline valg i stedet for popup-dropdowns")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
