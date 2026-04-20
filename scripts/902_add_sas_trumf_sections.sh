#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_902.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# === 1. Legg til seksjons-widget ===
insert_widget = """

Widget _buildProgramCards(BuildContext context) {
  final source = _source;

  if (source == 'SAS') {
    return _buildCardSection(context, 'SAS EuroBonus', 'sas_cards');
  }

  if (source == 'Trumf') {
    return _buildCardSection(context, 'Trumf', 'trumf_cards');
  }

  // Alle → vis begge
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildCardSection(context, 'SAS EuroBonus', 'sas_cards'),
      const SizedBox(height: 12),
      _buildCardSection(context, 'Trumf', 'trumf_cards'),
    ],
  );
}

Widget _buildCardSection(BuildContext context, String title, String placement) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      FutureBuilder<List<AdSlot>>(
        future: AdService.instance.pickAds(placement: placement),
        builder: (context, snap) {
          final list = snap.data ?? const <AdSlot>[];
          if (list.isEmpty) return const SizedBox.shrink();

          return Column(
            children: [
              for (final slot in list.take(2)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AdSlotCard(
                    slot: slot,
                    placement: placement,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    ],
  );
}
"""

if "_buildProgramCards" not in text:
    text += "\n" + insert_widget

# === 2. Sett inn i UI (over butikkliste) ===
old = "Expanded(\n            child: FutureBuilder<List<ShopOffer>>("

new = """_buildProgramCards(context),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<ShopOffer>>("

if old in text:
    text = text.replace(old, new, 1)
else:
    raise SystemExit("❌ Fant ikke riktig sted å injisere seksjon")

# === 3. Ferdig ===
if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ SAS/Trumf-seksjoner lagt til")
PY

flutter analyze
echo "✅ 902 ferdig"
