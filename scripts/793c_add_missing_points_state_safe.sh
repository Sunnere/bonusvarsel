#!/usr/bin/env bash
set -euo pipefail

echo "==> 793c_add_missing_points_state_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_793c")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Legg inn manglende felt etter _amountCtrl hvis de ikke finnes
if "_sasPointsCtrl" not in text:
    patterns = [
        r"(final TextEditingController _amountCtrl = TextEditingController\(text: '5000'\);\n)",
        r"(final TextEditingController _amountCtrl = TextEditingController\(\);\n)",
        r"(TextEditingController _amountCtrl = TextEditingController\(text: '5000'\);\n)",
        r"(TextEditingController _amountCtrl = TextEditingController\(\);\n)",
    ]
    inserted = False
    fields_block = (
        "\\1"
        "  final TextEditingController _sasPointsCtrl = TextEditingController(text: '36797');\n"
        "  bool _isSavingSasPoints = false;\n"
        "  int _savedSasPoints = 36797;\n"
    )
    for pat in patterns:
        new_text, n = re.subn(pat, fields_block, text, count=1)
        if n:
            text = new_text
            inserted = True
            print("✅ La inn SAS-points state-felter")
            break

    if not inserted:
        print("❌ Fant ikke _amountCtrl-feltet for å sette inn SAS-state.")
        print("Kjør og send:")
        print("  sed -n '1,120p' lib/pages/travel_page.dart")
        raise SystemExit(1)
else:
    print("ℹ️ _sasPointsCtrl finnes allerede")

# 2) Legg inn dispose for _sasPointsCtrl hvis dispose finnes og ctrl ikke allerede disponeres
if "_sasPointsCtrl.dispose();" not in text:
    new_text, n = re.subn(
        r"(void dispose\(\)\s*\{\s*)",
        r"\1\n    _sasPointsCtrl.dispose();\n",
        text,
        count=1,
    )
    if n:
        text = new_text
        print("✅ La inn dispose() for _sasPointsCtrl")
    else:
        print("ℹ️ Fant ingen dispose()-metode, hopper over dispose-patch")

# 3) Legg inn manglende hjelpefunksjoner før double _amount()
if "_formatInt(" not in text or "_saveSasPoints(" not in text or "_suggestedTargetPoints(" not in text:
    helper_anchor = "double _amount() {"
    helpers = """
  String _formatInt(int value) {
    final raw = value.toString();
    final chars = raw.split('').reversed.toList();
    final parts = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      parts.add(chars.sublist(i, end).join(''));
    }
    return parts.join(' ').split('').reversed.join('');
  }

  int _suggestedTargetPoints() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return 177500;
      case 'Hotell':
        return 95000;
      case 'Leiebil':
        return 65000;
      default:
        return 120000;
    }
  }

  Future<void> _saveSasPoints() async {
    final parsed = int.tryParse(_sasPointsCtrl.text.trim().replaceAll(' ', '')) ?? 0;
    if (!mounted) return;

    setState(() {
      _isSavingSasPoints = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    setState(() {
      _savedSasPoints = parsed;
      _isSavingSasPoints = false;
    });
  }

"""
    if helper_anchor in text:
        text = text.replace(helper_anchor, helpers + helper_anchor, 1)
        print("✅ La inn manglende hjelpefunksjoner")
    else:
        print("❌ Fant ikke ankeret double _amount()")
        print("Kjør og send:")
        print("  grep -n \"double _amount\" lib/pages/travel_page.dart")
        raise SystemExit(1)
else:
    print("ℹ️ Hjelpefunksjoner finnes allerede")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 793c ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
