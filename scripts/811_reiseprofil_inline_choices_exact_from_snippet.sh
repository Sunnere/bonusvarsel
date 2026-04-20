#!/usr/bin/env bash
set -euo pipefail

echo "==> 811_reiseprofil_inline_choices_exact_from_snippet"

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

old = """                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      dropdownColor: const Color(0xFFF6FAFB),
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Type tur',
                        filled: true,
                        fillColor: const Color(0xFFF3F8F9),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                      ),
                      items: _tripThemes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFF162E35),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                            dropdownColor: const Color(0xFFF6FAFB),
                            style: const TextStyle(
                              color: Color(0xFF162E35),
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Voksne',
                              filled: true,
                              fillColor: const Color(0xFFF3F8F9),
                              labelStyle: const TextStyle(
                                color: Color(0xFF27414A),
                                fontWeight: FontWeight.w700,
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                              border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                            ),
                            items: List<int>.generate(6, (i) => i + 1)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(
                                      '$v',
                                      style: const TextStyle(
                                        color: Color(0xFF162E35),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                            dropdownColor: const Color(0xFFF6FAFB),
                            style: const TextStyle(
                              color: Color(0xFF162E35),
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Barn',
                              filled: true,
                              fillColor: const Color(0xFFF3F8F9),
                              labelStyle: const TextStyle(
                                color: Color(0xFF27414A),
                                fontWeight: FontWeight.w700,
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                              border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                            ),
                            items: List<int>.generate(6, (i) => i)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(
                                      '$v',
                                      style: const TextStyle(
                                        color: Color(0xFF162E35),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                      dropdownColor: const Color(0xFFF6FAFB),
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Antall dager',
                        filled: true,
                        fillColor: const Color(0xFFF3F8F9),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                      ),
                      items: const [3, 5, 7, 10, 14, 21]
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text(
                              '$d dager',
                              style: const TextStyle(
                                color: Color(0xFF162E35),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _days = v);
                      },
                    ),
"""

new = """                    const SizedBox(height: 12),
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
                            children: const [3, 5, 7, 10, 14, 21].map((d) {
                              final selected = d == _days;
                              return ChoiceChip(
                                label: Text(
                                  '$d dager',
                                  style: TextStyle(
                                    color: Color(0xFF162E35),
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: Color(0xFFD9EEF1),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: selected
                                      ? Color(0xFF6CBCCA)
                                      : Color(0xFFD4E1E5),
                                ),
                                onSelected: (_) => setState(() => _days = d),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
"""

if old not in text:
    print("❌ Fant fortsatt ikke eksakt blokk")
    raise SystemExit(1)

text = text.replace(old, new, 1)

# const list -> remove const because _days/_setState used in closure
text = text.replace(
    "children: const [3, 5, 7, 10, 14, 21].map((d) {",
    "children: [3, 5, 7, 10, 14, 21].map((d) {",
    1,
)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 811 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
