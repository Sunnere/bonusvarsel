#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_837.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

# 1. Finn stedet etter "Recent campaigns"
anchor = "Recent campaigns"

if anchor not in text:
    raise SystemExit("❌ Fant ikke 'Recent campaigns'")

insert_block = """

          const SizedBox(height: 16),
          const Text(
            'Selected for dispatch',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          if (_recentCampaigns.isEmpty)
            const Text(
              'Ingen kandidater valgt.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._recentCampaigns
                .where((c) => c['shouldNotify'] == true)
                .take(3)
                .map((campaign) {
              final title = campaign['title']?.toString() ?? '-';
              final multiplier = campaign['multiplier']?.toString() ?? '-';
              final score = campaign['score']?.toString() ?? '-';
              final reason = campaign['reason']?.toString() ?? '-';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${multiplier}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _infoChip('Score', score),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
"""

# sett inn etter første forekomst av "Recent campaigns"
parts = text.split(anchor, 1)
text = parts[0] + anchor + parts[1].replace(
    "const SizedBox(height: 8),",
    "const SizedBox(height: 8)," + insert_block,
    1,
)

if text == original:
    raise SystemExit("❌ Ingen endring gjort")

p.write_text(text)
print("✅ La til 'Selected for dispatch' i UI")
PY

flutter analyze
echo "✅ 837 ferdig"
