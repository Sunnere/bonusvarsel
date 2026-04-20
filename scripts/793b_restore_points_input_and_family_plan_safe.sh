#!/usr/bin/env bash
set -euo pipefail

echo "==> 793b_restore_points_input_and_family_plan_safe"

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
bak = path.with_name(path.name + f".bak_{stamp}_793b")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Legg inn beregningsvariabler i build() rett etter estPoints
old_vars = "    final estPoints = _estimatePoints(amount);\n"
new_vars = """    final estPoints = _estimatePoints(amount);
    final currentSasPoints =
        int.tryParse(_sasPointsCtrl.text.trim().replaceAll(' ', '')) ?? _savedSasPoints;
    final projectedSasPoints = currentSasPoints + estPoints;
    final targetPoints = _suggestedTargetPoints();
    final pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31);
"""

if old_vars not in text:
    print("❌ Fant ikke linjen med estPoints i build().")
    print("Kjør og send:")
    print("  sed -n '385,415p' lib/pages/travel_page.dart")
    raise SystemExit(1)

if "final currentSasPoints =" not in text:
    text = text.replace(old_vars, new_vars, 1)
    print("✅ La inn points-first beregningsvariabler")
else:
    print("ℹ️ Beregningsvariabler finnes allerede")

# 2) Sett inn saldo + familieplan rett før TravelValueCard
anchor = """              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""

insert_block = """              Container(
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
                      'SAS EuroBonus-saldo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Legg inn poengene du allerede har. Dette gir mer presis beregning videre i reisen.',
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSavingSasPoints ? 'Lagrer...' : 'Lagre poengsaldo',
                          ),
                        ),
                        Text(
                          'Lagret: ${_formatInt(_savedSasPoints)} poeng',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5B7077),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E8BE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6D38C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poengplan for familien',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
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

if "SAS EuroBonus-saldo" in text or "Poengplan for familien" in text:
    print("ℹ️ Saldo-/poengplan-blokk finnes allerede. Stopper for å unngå dobbeltinnsetting.")
    raise SystemExit(0)

if anchor not in text:
    print("❌ Fant ikke TravelValueCard-ankeret.")
    print("Kjør og send:")
    print("  grep -n \"TravelValueCard\" lib/pages/travel_page.dart")
    print("  sed -n '470,540p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(anchor, insert_block, 1)
print("✅ La inn SAS-saldo + Poengplan før TravelValueCard")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 793b ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
