#!/usr/bin/env bash
set -euo pipefail

echo "==> 808_replace_reiseprofil_dropdowns_with_choice_chips_safe"

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
bak = path.with_name(path.name + f".bak_{stamp}_808")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

old = """                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      dropdownColor: const Color(0xFFEFF7F8),
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
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF7F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    color: Color(0xFF162E35),
                                    fontWeight: FontWeight.w700,
                                  ),
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
                      items: _dayOptions
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
                    _TravelProfileChoiceSection<String>(
                      title: 'Type tur',
                      value: _selectedTripTheme,
                      options: _tripThemes,
                      labelBuilder: (v) => v,
                      onSelected: (v) => setState(() => _selectedTripTheme = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TravelProfileChoiceSection<int>(
                            title: 'Voksne',
                            value: _adults,
                            options: List<int>.generate(6, (i) => i + 1),
                            labelBuilder: (v) => '$v',
                            onSelected: (v) => setState(() => _adults = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TravelProfileChoiceSection<int>(
                            title: 'Barn',
                            value: _children,
                            options: List<int>.generate(6, (i) => i),
                            labelBuilder: (v) => '$v',
                            onSelected: (v) => setState(() => _children = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TravelProfileChoiceSection<int>(
                      title: 'Antall dager',
                      value: _days,
                      options: _dayOptions,
                      labelBuilder: (d) => '$d dager',
                      onSelected: (d) => setState(() => _days = d),
                    ),
"""

if old not in text:
    print("❌ Fant ikke eksakt Reiseprofil-dropdown-blokk")
    print("Kjør og send:")
    print("  sed -n '900,1025p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)

insert_after = """class _TravelPageState extends State<TravelPage> {"""

helper = """class _TravelProfileChoiceSection<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _TravelProfileChoiceSection({
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E1E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF27414A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option == value;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFDAF1F4)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF6CBCCA)
                          : const Color(0xFFD4E1E5),
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x120F3A4A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    labelBuilder(option),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF162E35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TravelPageState extends State<TravelPage> {"""

if insert_after not in text:
    print("❌ Fant ikke innsats-punkt for helper-widget")
    raise SystemExit(1)

text = text.replace(insert_after, helper, 1)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 808 ferdig: Reiseprofil bruker nå chips i stedet for stygge dropdown-popups")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
