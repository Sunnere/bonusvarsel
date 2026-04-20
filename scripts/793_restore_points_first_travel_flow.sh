#!/usr/bin/env bash
set -euo pipefail

echo "==> 793_restore_points_first_travel_flow"

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
bak = path.with_name(path.name + f".bak_{stamp}_793")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Sørg for at hjelpevariabler finnes i build()
build_anchor = """  @override
  Widget build(BuildContext context) {
    final amount = _amount();
    final estPoints = _estimatePoints(amount);

    final cardName = CardCatalog.nameFor(_selectedCardId);
    final cardLabel = (_selectedCardId == null)
        ? 'Gå til "Kort" og velg et kort'
        : 'Valgt kort: $cardName • $_cardRatePer100 poeng per 100 kr';
"""

build_replacement = """  @override
  Widget build(BuildContext context) {
    final amount = _amount();
    final estPoints = _estimatePoints(amount);

    final currentSasPoints =
        int.tryParse(_sasPointsCtrl.text.trim().replaceAll(' ', '')) ?? _savedSasPoints;
    final projectedSasPoints = currentSasPoints + estPoints;
    final targetPoints = _suggestedTargetPoints();
    final pointsGap = (targetPoints - projectedSasPoints).clamp(0, 1 << 31);

    final cardName = CardCatalog.nameFor(_selectedCardId);
    final cardLabel = (_selectedCardId == null)
        ? 'Gå til "Kort" og velg et kort'
        : 'Valgt kort: $cardName • $_cardRatePer100 poeng per 100 kr';
"""

if build_anchor in text:
    text = text.replace(build_anchor, build_replacement, 1)
else:
    print("❌ Fant ikke build-ankeret.")
    print("Kjør og send:")
    print("  sed -n '380,430p' lib/pages/travel_page.dart")
    raise SystemExit(1)

# 2) Erstatt den mørke topplogikken etter hero med points-first blokker
start_anchor = """              const SizedBox(height: 14),
              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
              const SizedBox(height: 14),
              _buildTravelUseModule(context),
              _buildTravelStoreModule(context),
"""

replacement_block = """              const SizedBox(height: 14),
              Container(
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
                      'Legg inn poengene du allerede har. Dette er grunnlaget for beregningene videre i reisen.',
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
                          label: Text(_isSavingSasPoints ? 'Lagrer...' : 'Lagre poengsaldo'),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planlagt kjøp før reisen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Reisebeløp / handlebudsjett (NOK)',
                        hintText: 'f.eks 5000',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cardLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4F6770),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Foreløpig estimat',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF4E6670),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$estPoints poeng',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF162E35),
                            fontWeight: FontWeight.w900,
                          ),
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
                  border: Border.all(color: const Color(0xFFE7D38A)),
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
                            color: const Color(0xFF41575F),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimert opptjening: +${_formatInt(estPoints)} poeng',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF41575F),
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
                            color: const Color(0xFF566D75),
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
              const SizedBox(height: 14),
              _buildTravelUseModule(context),
              _buildTravelStoreModule(context),
"""

if start_anchor in text:
    text = text.replace(start_anchor, replacement_block, 1)
else:
    print("❌ Fant ikke blokka med TravelValueCard + premiummoduler.")
    print("Kjør og send:")
    print("  sed -n '440,540p' lib/pages/travel_page.dart")
    raise SystemExit(1)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Gjenopprettet points-first reiseflyt med premium/elite under")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
