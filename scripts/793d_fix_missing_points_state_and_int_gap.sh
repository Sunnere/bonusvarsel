#!/usr/bin/env bash
set -euo pipefail

echo "==> 793d_fix_missing_points_state_and_int_gap"

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
bak = path.with_name(path.name + f".bak_{stamp}_793d")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Legg inn manglende felt rett under _amountCtrl hvis de ikke finnes
amount_decl_re = re.compile(
    r"(final TextEditingController _amountCtrl = TextEditingController\(text: '5000'\);\n)",
    re.MULTILINE,
)

if "_sasPointsCtrl" not in text or "_savedSasPoints" not in text or "_isSavingSasPoints" not in text:
    m = amount_decl_re.search(text)
    if not m:
        print("❌ Fant ikke _amountCtrl-deklarasjonen.")
        print("Kjør og send:")
        print("  sed -n '1,60p' lib/pages/travel_page.dart")
        raise SystemExit(1)

    insert = m.group(1)
    extra = ""
    if "_sasPointsCtrl" not in text:
        extra += "  final TextEditingController _sasPointsCtrl = TextEditingController(text: '36797');\n"
    if "_isSavingSasPoints" not in text:
        extra += "  bool _isSavingSasPoints = false;\n"
    if "_savedSasPoints" not in text:
        extra += "  int _savedSasPoints = 36797;\n"

    text = text.replace(insert, insert + "\n" + extra, 1)
    print("✅ La inn manglende SAS-points state-felter")
else:
    print("ℹ️ SAS-points state-felter finnes allerede")

# 2) Sørg for at pointsGap er int, ikke num
old_gap = "    final pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31);\n"
new_gap = "    final int pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31).toInt();\n"

if old_gap in text:
    text = text.replace(old_gap, new_gap, 1)
    print("✅ Gjorde pointsGap til int")
else:
    gap_re = re.compile(
        r"^\s*final\s+pointsGap\s*=\s*\(targetPoints\s*-\s*projectedSasPoints\)\.clamp\(0,\s*1\s*<<\s*31\);\s*$",
        re.MULTILINE,
    )
    text, n = gap_re.subn("    final int pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31).toInt();", text, count=1)
    if n:
        print("✅ Gjorde pointsGap til int (regex)")
    else:
        print("ℹ️ Fant ikke pointsGap-linjen eksakt, hopper over")

# 3) Legg inn _formatInt hvis den mangler
if "_formatInt(" not in text:
    anchor = "double _amount() {"
    helper = """
  String _formatInt(int value) {
    final s = value.toString();
    final out = <String>[];
    for (int i = s.length; i > 0; i -= 3) {
      final start = (i - 3 < 0) ? 0 : i - 3;
      out.insert(0, s.substring(start, i));
    }
    return out.join(' ');
  }

"""
    if anchor not in text:
        print("❌ Fant ikke anker for _formatInt().")
        print("Kjør og send:")
        print("  grep -n \"double _amount\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(anchor, helper + anchor, 1)
    print("✅ La inn _formatInt()")
else:
    print("ℹ️ _formatInt() finnes allerede")

# 4) Legg inn _suggestedTargetPoints hvis den mangler
if "_suggestedTargetPoints(" not in text:
    anchor = "double _amount() {"
    helper = """
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

"""
    if anchor not in text:
        print("❌ Fant ikke anker for _suggestedTargetPoints().")
        print("Kjør og send:")
        print("  grep -n \"double _amount\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(anchor, helper + anchor, 1)
    print("✅ La inn _suggestedTargetPoints()")
else:
    print("ℹ️ _suggestedTargetPoints() finnes allerede")

# 5) Legg inn _saveSasPoints hvis den mangler
if "_saveSasPoints(" not in text:
    anchor = "double _amount() {"
    helper = """
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
    if anchor not in text:
        print("❌ Fant ikke anker for _saveSasPoints().")
        print("Kjør og send:")
        print("  grep -n \"double _amount\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(anchor, helper + anchor, 1)
    print("✅ La inn _saveSasPoints()")
else:
    print("ℹ️ _saveSasPoints() finnes allerede")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 793d ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
