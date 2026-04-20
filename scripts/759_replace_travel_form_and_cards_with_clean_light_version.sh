#!/usr/bin/env bash
set -euo pipefail

echo "==> 759_replace_travel_form_and_cards_with_clean_light_version"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_759")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

def find_matching_paren(src: str, open_idx: int) -> int:
    depth = 0
    in_single = False
    in_double = False
    i = open_idx
    while i < len(src):
      ch = src[i]
      prev = src[i - 1] if i > 0 else ""
      if ch == "'" and not in_double and prev != "\\":
          in_single = not in_single
      elif ch == '"' and not in_single and prev != "\\":
          in_double = not in_double
      elif not in_single and not in_double:
          if ch == "(":
              depth += 1
          elif ch == ")":
              depth -= 1
              if depth == 0:
                  return i
      i += 1
    return -1

def replace_card_by_title(src: str, title: str, replacement: str) -> str:
    title_idx = src.find(f"'{title}'")
    if title_idx == -1:
        raise ValueError(f"Fant ikke tittel: {title}")

    card_start = src.rfind("Card(", 0, title_idx)
    if card_start == -1:
        raise ValueError(f"Fant ikke Card( for: {title}")

    open_idx = src.find("(", card_start)
    close_idx = find_matching_paren(src, open_idx)
    if close_idx == -1:
        raise ValueError(f"Fant ikke slutt på Card( for: {title}")

    end_idx = close_idx + 1
    while end_idx < len(src) and src[end_idx] in " \t":
        end_idx += 1
    if end_idx < len(src) and src[end_idx] == ",":
        end_idx += 1

    return src[:card_start] + replacement + src[end_idx:]

helpers = r"""
  TextStyle _travelSectionTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF10252B),
    );
  }

  TextStyle _travelSectionBodyStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: const Color(0xFF243940),
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
  }

  InputDecoration _travelInputDecoration(
    String label, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        color: Color(0xFF243940),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF10252B),
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8FB8C5), width: 1.3),
      ),
    );
  }

  Widget _travelLightCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

"""

if "_travelInputDecoration(" not in text:
    anchor = "  @override\n  Widget build(BuildContext context) {"
    if anchor not in text:
        print("ERROR: Fant ikke build()-anker for helper-metoder")
        raise SystemExit(1)
    text = text.replace(anchor, helpers + "\n" + anchor, 1)

reiseprofil_replacement = """
              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
                      style: _travelSectionTitleStyle(context),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      initialValue: _selectedProgram,
                      decoration: _travelInputDecoration('Bonusprogram'),
                      items: _programs
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Color(0xFF10252B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedProgram = v);
                        _refreshTripFeedSuggestions();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _destinationCtrl,
                      decoration: _travelInputDecoration(
                        'Reisemål',
                        hintText: 'f.eks Thailand, Spania, Trysil',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF10252B),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _refreshTripFeedSuggestions();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      initialValue: _selectedTripType,
                      decoration: _travelInputDecoration('Type tur'),
                      items: _tripTypes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFF10252B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedTripType = v);
                        _refreshTripFeedSuggestions();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            dropdownColor: Colors.white,
                            initialValue: _adults,
                            decoration: _travelInputDecoration('Voksne'),
                            items: _countOptions
                                .where((v) => v >= 1)
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(
                                      '$v',
                                      style: const TextStyle(
                                        color: Color(0xFF10252B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _adults = v);
                              _refreshTripFeedSuggestions();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            dropdownColor: Colors.white,
                            initialValue: _children,
                            decoration: _travelInputDecoration('Barn'),
                            items: _countOptions
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(
                                      '$v',
                                      style: const TextStyle(
                                        color: Color(0xFF10252B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _children = v);
                              _refreshTripFeedSuggestions();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      dropdownColor: Colors.white,
                      initialValue: _days,
                      decoration: _travelInputDecoration('Antall dager'),
                      items: _dayOptions
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text(
                                '$d dager',
                                style: const TextStyle(
                                  color: Color(0xFF10252B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _days = v);
                        _refreshTripFeedSuggestions();
                      },
                    ),
                  ],
                ),
              ),
"""

saldo_replacement = """
              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAS EuroBonus-saldo',
                      style: _travelSectionTitleStyle(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Legg inn poengene du allerede har. Senere kan dette byttes til automatisk sync hvis Bonusvarsel får avtale med SAS.',
                      style: _travelSectionBodyStyle(context),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _travelInputDecoration(
                        'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 125000',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF10252B),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      runSpacing: 8,
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _isSavingSasPoints ? null : _saveSasPoints,
                          icon: _isSavingSasPoints
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSavingSasPoints ? 'Lagrer...' : 'Lagre poengsaldo',
                          ),
                        ),
                        Text(
                          'Lagret: ${_formatInt(_savedSasPoints)} poeng',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF10252B),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
"""

budsjett_replacement = """
              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planlagt kjøp før reisen',
                      style: _travelSectionTitleStyle(context),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _travelInputDecoration(
                        'Reisebeløp / handlebudsjett (NOK)',
                        hintText: 'f.eks 5000',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF10252B),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cardLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF10252B),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Foreløpig estimat',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF243940),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$estPoints poeng',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10252B),
                          ),
                    ),
                  ],
                ),
              ),
"""

poengplan_replacement = """
              Card(
                color: const Color(0xFFF2E4B9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poengplan for familien',
                        style: _travelSectionTitleStyle(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nåværende saldo: ${_formatInt(currentSasPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF10252B),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Estimert opptjening: +${_formatInt(estPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF10252B),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mulig saldo etter kjøpet: ${_formatInt(projectedSasPoints)} poeng',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Forsiktig familie-estimat for mål: ${_formatInt(targetPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF243940),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pointsGap > 0
                            ? 'Manglende poeng til målet: ${_formatInt(pointsGap)}'
                            : 'Du er på eller over målpoeng for denne enkle planen.',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
"""

try:
    text = replace_card_by_title(text, "Reiseprofil", reiseprofil_replacement)
    text = replace_card_by_title(text, "SAS EuroBonus-saldo", saldo_replacement)
    text = replace_card_by_title(text, "Planlagt kjøp før reisen", budsjett_replacement)
    text = replace_card_by_title(text, "Poengplan for familien", poengplan_replacement)
except ValueError as e:
    print(f"ERROR: {e}")
    raise SystemExit(1)

if text == original:
    print("Ingen endringer ble gjort.")
    raise SystemExit(1)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 759 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
