#!/usr/bin/env bash
set -euo pipefail

API_SERVER="api/server.js"
PANEL="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_SERVER" ]] || { echo "❌ Fant ikke $API_SERVER"; exit 1; }
[[ -f "$PANEL" ]] || { echo "❌ Fant ikke $PANEL"; exit 1; }

cp "$API_SERVER" "$API_SERVER.bak_774.$(date +%s)"
cp "$PANEL" "$PANEL.bak_774.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

api = Path("api/server.js")
text = api.read_text()

old = """  const combined = [...seeded, ...campaigns].slice(0, 20);

  const scanned = combined.length;
  const queued = Math.min(scanned, 5);
  const dispatched = Math.min(queued, 3);

  state.activatedNotifications = combined.slice(0, dispatched).map((item, i) => ({
"""
new = """  const combined = [...seeded, ...campaigns]
    .sort((a, b) => (Number(b.multiplier || 0) - Number(a.multiplier || 0)))
    .slice(0, 20);

  const scanned = combined.length;
  const queued = Math.min(scanned, 5);
  const dispatched = Math.min(queued, 3);

  state.activatedNotifications = combined.slice(0, dispatched).map((item, i) => ({
"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet combined/scanned-blokk i api/server.js")

text = text.replace(old, new, 1)

old2 = """    recentCampaigns: combined.slice(0, 5),
  };

  return {
    ok: true,
    id: simulationId,
    source: state.pipeline.source,
"""
new2 = """    recentCampaigns: combined.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
    })),
  };

  return {
    ok: true,
    id: simulationId,
    source: state.pipeline.source,
"""

if old2 not in text:
    raise SystemExit("❌ Fant ikke forventet recentCampaigns-blokk i api/server.js")

text = text.replace(old2, new2, 1)
api.write_text(text)
print("✅ Backend-simulering bruker live campaigns sortert på multiplier")
PY

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

if "List<Map<String, dynamic>> _recentCampaigns = [];" not in text:
    anchor = "  Map<String, dynamic>? _lastState;\n"
    if anchor not in text:
        raise SystemExit("❌ Fant ikke anker for _recentCampaigns i dev_pipeline_panel.dart")
    text = text.replace(anchor, anchor + "  List<Map<String, dynamic>> _recentCampaigns = [];\n", 1)

old = """    _summary = result['summary']?.toString() ??
        (summaryParts.isEmpty ? result.toString() : summaryParts.join(' • '));
    _lastState = result;
  }
"""
new = """    _summary = result['summary']?.toString() ??
        (summaryParts.isEmpty ? result.toString() : summaryParts.join(' • '));

    final recentCampaignsRaw = result['recentCampaigns'];
    if (recentCampaignsRaw is List) {
      _recentCampaigns = recentCampaignsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      _recentCampaigns = [];
    }

    _lastState = result;
  }
"""
if old not in text:
    raise SystemExit("❌ Fant ikke _applyState-slutt i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)

marker = """          _sectionCard(
            title: 'Inspector',
            body: _message,
            tone: _message.toLowerCase().contains('feilet')
                ? _Tone.danger
                : _message.toLowerCase().contains('oppdatert') ||
                        _message.toLowerCase().contains('fullført')
                    ? _Tone.success
                    : _Tone.warning,
          ),
"""
insert = """          _sectionCard(
            title: 'Inspector',
            body: _message,
            tone: _message.toLowerCase().contains('feilet')
                ? _Tone.danger
                : _message.toLowerCase().contains('oppdatert') ||
                        _message.toLowerCase().contains('fullført')
                    ? _Tone.success
                    : _Tone.warning,
          ),
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
                  ..._recentCampaigns.take(5).map((campaign) {
                    final title = campaign['title']?.toString() ?? '-';
                    final multiplier = campaign['multiplier']?.toString() ?? '-';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $title ($multiplier x)',
                        style: const TextStyle(
                          color: _textSoft,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
"""
if marker not in text:
    raise SystemExit("❌ Fant ikke Inspector-seksjonen i dev_pipeline_panel.dart")

text = text.replace(marker, insert, 1)

p.write_text(text)
print("✅ DevPipelinePanel viser recent campaigns fra ekte simulering")
PY

flutter analyze
echo "✅ 774 ferdig"
