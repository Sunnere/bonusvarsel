#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_845.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old = """          if (_recentCampaigns.isEmpty)
            const Text(
              'Ingen recent campaigns ennå.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._recentCampaigns.take(5).map((campaign) {
"""

new = """          final visibleRecentCampaigns = _recentCampaigns
              .where((campaign) =>
                  campaign['dispatchEligible'] == true ||
                  campaign['shouldNotify'] == true)
              .take(5)
              .toList();

          if (visibleRecentCampaigns.isEmpty)
            const Text(
              'Ingen dispatch-relevante kampanjer ennå.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...visibleRecentCampaigns.map((campaign) {
"""

if old not in text:
    raise SystemExit("❌ Fant ikke recent campaigns-starten")
text = text.replace(old, new, 1)

old2 = """                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: shouldNotify
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: shouldNotify
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            shouldNotify ? 'SEND' : 'SKIP',
                            style: TextStyle(
                              color: shouldNotify
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
"""

new2 = """                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: shouldNotify
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: shouldNotify
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            shouldNotify ? 'SEND' : 'SKIP',
                            style: TextStyle(
                              color: shouldNotify
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (!dispatchEligible)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: const Text(
                              'Ikke valgt',
                              style: TextStyle(
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
"""

if old2 not in text:
    raise SystemExit("❌ Fant ikke SEND/SKIP-blokken")
text = text.replace(old2, new2, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Reduserte støy i Recent campaigns")
PY

flutter analyze
echo "✅ 845 ferdig"
