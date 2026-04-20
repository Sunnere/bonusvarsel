#!/usr/bin/env bash
set -euo pipefail

echo "==> 795_add_live_points_status_panel_safe"

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
bak = path.with_name(path.name + f".bak_{stamp}_795")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) controller hvis mangler
amount_anchor = "  final TextEditingController _amountCtrl = TextEditingController(text: '5000');\n"
if "_sasPointsCtrl" not in text:
    if amount_anchor not in text:
        print("❌ Fant ikke _amountCtrl-ankeret.")
        print("Kjør og send:")
        print("  sed -n '1,40p' lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(
        amount_anchor,
        amount_anchor + "  final TextEditingController _sasPointsCtrl = TextEditingController(text: '36797');\n",
        1,
    )
    print("✅ La inn _sasPointsCtrl")

# 2) dispose hvis mangler
dispose_anchor = "  @override\n  void dispose() {\n"
if "_sasPointsCtrl.dispose();" not in text and dispose_anchor in text:
    text = text.replace(
        dispose_anchor,
        dispose_anchor + "    _sasPointsCtrl.dispose();\n",
        1,
    )
    print("✅ La inn _sasPointsCtrl.dispose()")

# 3) hjelpefunksjoner hvis mangler
helper_anchor = "double _amount() {"
helpers = """
  String _formatInt(int value) {
    final s = value.toString();
    final chunks = <String>[];
    for (int i = s.length; i > 0; i -= 3) {
      final start = (i - 3 < 0) ? 0 : i - 3;
      chunks.insert(0, s.substring(start, i));
    }
    return chunks.join(' ');
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

"""
if "_formatInt(" not in text or "_suggestedTargetPoints(" not in text:
    if helper_anchor not in text:
        print("❌ Fant ikke double _amount()-ankeret.")
        print("Kjør og send:")
        print("  grep -n \"double _amount\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(helper_anchor, helpers + helper_anchor, 1)
    print("✅ La inn hjelpefunksjoner")

# 4) build-variabler hvis mangler
old_build = "    final estPoints = _estimatePoints(amount);\n"
new_build = """    final estPoints = _estimatePoints(amount);
    final currentSasPoints =
        int.tryParse(_sasPointsCtrl.text.trim().replaceAll(' ', '')) ?? 0;
    final projectedSasPoints = currentSasPoints + estPoints;
    final targetPoints = _suggestedTargetPoints();
    final int pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31).toInt();
"""
if "final currentSasPoints =" not in text:
    if old_build not in text:
        print("❌ Fant ikke estPoints-linjen i build().")
        print("Kjør og send:")
        print("  grep -n \"final estPoints\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(old_build, new_build, 1)
    print("✅ La inn live points-variabler i build()")

# 5) nytt panel før TravelValueCard
widget_anchor = """              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""
panel = """              Container(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Legg inn poengene du har nå. Resten av planen regnes ut fortløpende.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B7077),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Premium: bedre forslag',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF2957A4),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Elite: beste prioritering',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8B6500),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nåværende saldo: ${_formatInt(currentSasPoints)} poeng',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4E6168),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimert opptjening: +${_formatInt(estPoints)} poeng',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4E6168),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mulig saldo etter kjøpet: ${_formatInt(projectedSasPoints)} poeng',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Forsiktig familie-estimat for mål: ${_formatInt(targetPoints)} poeng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF596E75),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pointsGap > 0
                          ? 'Manglende poeng til målet: ${_formatInt(pointsGap)}'
                          : 'Du er på eller over målpoeng for denne planen.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""
if "Din poengstatus" not in text:
    if widget_anchor not in text:
        print("❌ Fant ikke TravelValueCard-ankeret.")
        print("Kjør og send:")
        print("  grep -n \"TravelValueCard\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(widget_anchor, panel, 1)
    print("✅ La inn live poengstatus-panel")
else:
    print("ℹ️ Poengstatus-panel finnes allerede")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 795 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
