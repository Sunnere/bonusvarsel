#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_896.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    decoration: BoxDecoration(
      color: cs.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.primary.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock,
          size: 14,
          color: Color(0xFFD4AF37),
        ),
        const SizedBox(width: 8),
      ],
    ),
  );"""

new = """  return FutureBuilder<List<AdSlot>>(
    future: AdService.instance.pickAds(placement: 'eb_shopping'),
    builder: (context, snap) {
      final list = snap.data ?? const <AdSlot>[];
      if (list.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: AdSlotCard(
          slot: list.first,
          placement: 'eb_shopping',
        ),
      );
    },
  );"""

if old not in text:
    raise SystemExit("❌ Fant ikke den tomme containeren å erstatte")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Byttet tom upgrade-boks med annonseplass")
PY

flutter analyze
echo "✅ 896 ferdig"
