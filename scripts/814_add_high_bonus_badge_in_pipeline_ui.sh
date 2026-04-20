#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_814.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old = """                  ..._recentCampaigns.take(5).map((campaign) {
                    final title = campaign['title']?.toString() ?? '-';
                    final multiplier = campaign['multiplier']?.toString() ?? '-';
                    final score = campaign['score']?.toString() ?? '-';
                    final shouldNotify = campaign['shouldNotify'];
                    final reason = campaign['reason']?.toString() ?? '-';

                    final decisionText = shouldNotify == true
                        ? 'SEND'
                        : shouldNotify == false
                            ? 'SKIP'
                            : '-';

                    final decisionTone = shouldNotify == true
                        ? _Tone.success
                        : shouldNotify == false
                            ? _Tone.danger
                            : _Tone.neutral;

                    final toneData = _toneData(decisionTone);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: toneData.bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: toneData.border),
                                ),
                                child: Text(
                                  decisionText,
                                  style: TextStyle(
                                    color: toneData.text,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
"""

new = """                  ..._recentCampaigns.take(5).map((campaign) {
                    final title = campaign['title']?.toString() ?? '-';
                    final multiplierValue = (campaign['multiplier'] is num)
                        ? (campaign['multiplier'] as num).toDouble()
                        : double.tryParse('${campaign['multiplier'] ?? ''}') ?? 0;
                    final multiplier = campaign['multiplier']?.toString() ?? '-';
                    final score = campaign['score']?.toString() ?? '-';
                    final shouldNotify = campaign['shouldNotify'];
                    final reason = campaign['reason']?.toString() ?? '-';

                    final isHighBonus = multiplierValue >= 2.0;

                    final decisionText = shouldNotify == true
                        ? 'SEND'
                        : shouldNotify == false
                            ? 'SKIP'
                            : '-';

                    final decisionTone = shouldNotify == true
                        ? _Tone.success
                        : shouldNotify == false
                            ? _Tone.danger
                            : _Tone.neutral;

                    final toneData = _toneData(decisionTone);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isHighBonus)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.orange.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: const Text(
                                    '🔥 Høy bonus',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: toneData.bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: toneData.border),
                                ),
                                child: Text(
                                  decisionText,
                                  style: TextStyle(
                                    color: toneData.text,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke recentCampaigns-renderblokken i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn 🔥 Høy bonus-badge i pipeline UI")
PY

flutter analyze
echo "✅ 814 ferdig"
