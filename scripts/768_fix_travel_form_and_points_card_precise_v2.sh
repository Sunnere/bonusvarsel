#!/usr/bin/env bash
set -euo pipefail

echo "==> 768_fix_travel_form_and_points_card_precise_v2"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_768v2")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

helpers = """
  InputDecoration _travelDarkFieldDecoration(
    String label, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFF071B34),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        color: Color(0xFFD6E5EE),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.15,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFEAF5FA),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.15,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF8FA8B7),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF254765), width: 1.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF254765), width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF58D0E0), width: 1.5),
      ),
    );
  }

  TextStyle _travelFieldValueStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle _travelMutedTextStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: const Color(0xFF60747C),
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
  }

"""

anchor = "  @override\n  Widget build(BuildContext context) {"
if helpers not in text:
    if anchor not in text:
        print("❌ Fant ikke build()-anker")
        raise SystemExit(1)
    text = text.replace(anchor, helpers + "\n" + anchor, 1)

replacements = [
(
"""                        decoration: const InputDecoration(
                          labelText: 'Bonusprogram',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration('Bonusprogram'),"""
),
(
"""                        decoration: const InputDecoration(
                          labelText: 'Reisemål',
                          hintText: 'f.eks Thailand, Spania, Trysil',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration(
                          'Reisemål',
                          hintText: 'f.eks Thailand, Spania, Trysil',
                        ),
                        style: _travelFieldValueStyle(),"""
),
(
"""                        decoration: const InputDecoration(
                          labelText: 'Type tur',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration('Type tur'),"""
),
(
"""                              decoration: const InputDecoration(
                                labelText: 'Voksne',
                                border: OutlineInputBorder(),
                              ),""",
"""                              decoration: _travelDarkFieldDecoration('Voksne'),"""
),
(
"""                              decoration: const InputDecoration(
                                labelText: 'Barn',
                                border: OutlineInputBorder(),
                              ),""",
"""                              decoration: _travelDarkFieldDecoration('Barn'),"""
),
(
"""                        decoration: const InputDecoration(
                          labelText: 'Antall dager',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration('Antall dager'),"""
),
(
"""                        decoration: const InputDecoration(
                          labelText: 'Nåværende SAS EuroBonus-poeng',
                          hintText: 'f.eks 125000',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration(
                          'Nåværende SAS EuroBonus-poeng',
                          hintText: 'f.eks 125000',
                        ),
                        style: _travelFieldValueStyle(),"""
),
(
"""                        decoration: const InputDecoration(
                          labelText: 'Reisebeløp / handlebudsjett (NOK)',
                          hintText: 'f.eks 5000',
                          border: OutlineInputBorder(),
                        ),""",
"""                        decoration: _travelDarkFieldDecoration(
                          'Reisebeløp / handlebudsjett (NOK)',
                          hintText: 'f.eks 5000',
                        ),
                        style: _travelFieldValueStyle(),"""
),
]

for old, new in replacements:
    text = text.replace(old, new)

text = text.replace("child: Text(p),", "child: Text(p, style: _travelFieldValueStyle()),")
text = text.replace("child: Text(t),", "child: Text(t, style: _travelFieldValueStyle()),")
text = text.replace("child: Text('$v'),", "child: Text('$v', style: _travelFieldValueStyle()),")
text = text.replace("child: Text('$d dager'),", "child: Text('$d dager', style: _travelFieldValueStyle()),")

text = text.replace(
"""                      Text(
                        cardLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),""",
"""                      Text(
                        cardLabel,
                        style: _travelMutedTextStyle(context),
                      ),"""
)

text = text.replace(
"""                          Text(
                            'Lagret: ${_formatInt(_savedSasPoints)} poeng',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),""",
"""                          Text(
                            'Lagret: ${_formatInt(_savedSasPoints)} poeng',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF7A8C94),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),"""
)

text = text.replace(
"""                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2E4951),
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),""",
"""                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF546870),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),"""
)

text = text.replace(
"Text('Nåværende saldo: ${_formatInt(currentSasPoints)} poeng'),",
"""Text(
                        'Nåværende saldo: ${_formatInt(currentSasPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6C7178),
                              fontWeight: FontWeight.w600,
                            ),
                      ),"""
)

text = text.replace(
"Text('Estimert opptjening: +${_formatInt(estPoints)} poeng'),",
"""Text(
                        'Estimert opptjening: +${_formatInt(estPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6C7178),
                              fontWeight: FontWeight.w600,
                            ),
                      ),"""
)

text = text.replace(
"""                      Text(
                        'Forsiktig familie-estimat for mål: ${_formatInt(targetPoints)} poeng',
                      ),""",
"""                      Text(
                        'Forsiktig familie-estimat for mål: ${_formatInt(targetPoints)} poeng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6C7178),
                              fontWeight: FontWeight.w600,
                            ),
                      ),"""
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Patched: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
