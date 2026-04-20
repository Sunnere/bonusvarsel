#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_783.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

old = """          if (_recentCampaigns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent campaigns from simulation',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
"""

new = """          if (_lastState != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live pipeline state',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip('Source', '${_lastState?['source'] ?? '-'}'),
                      _infoChip(
                        'Scanned',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['scanned'] ?? '-'}',
                      ),
                      _infoChip(
                        'Queued',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['queued'] ?? '-'}',
                      ),
                      _infoChip(
                        'Dispatched',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['dispatched'] ?? '-'}',
                      ),
                      _infoChip('Simulation', '${_lastState?['id'] ?? '-'}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_recentCampaigns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent campaigns from simulation',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke recent campaigns-seksjonen i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ La inn live pipeline state i DevPipelinePanel")
PY

flutter analyze
echo "✅ 783 ferdig"
