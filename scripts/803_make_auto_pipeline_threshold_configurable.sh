#!/usr/bin/env bash
set -euo pipefail

API_FILE="api/server.js"
PANEL_FILE="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_FILE" ]] || { echo "❌ Fant ikke $API_FILE"; exit 1; }
[[ -f "$PANEL_FILE" ]] || { echo "❌ Fant ikke $PANEL_FILE"; exit 1; }

cp "$API_FILE" "$API_FILE.bak_803.$(date +%s)"
cp "$PANEL_FILE" "$PANEL_FILE.bak_803.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

# 1) legg inn config hvis mangler
marker = 'const autoPipelineIntervalMs = Number(process.env.AUTO_PIPELINE_INTERVAL_MS || 60000);\n'
insert = marker + 'const autoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n'
if 'const autoPipelineThreshold =' not in text:
    if marker not in text:
        raise SystemExit("❌ Fant ikke autoPipelineIntervalMs-markør i api/server.js")
    text = text.replace(marker, insert, 1)

# 2) evaluateCampaign default threshold
old = """  const threshold = Number(reqBody.threshold || 2);"""
new = """  const threshold = Number(reqBody.threshold || autoPipelineThreshold || 2);"""
if old in text:
    text = text.replace(old, new, 1)

# 3) auto tick bruker config
old = """      const evaluation = evaluateCampaign(item, {
      threshold: 2,
      level: "premium",
      campaign: true,
    });"""
new = """      const evaluation = evaluateCampaign(item, {
      threshold: autoPipelineThreshold,
      level: "premium",
      campaign: true,
    });"""
if old in text:
    text = text.replace(old, new, 1)

# 4) eksponer threshold i pipeline state
old = """    summary,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({"""
new = """    summary,
    threshold: autoPipelineThreshold,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({"""
if old in text:
    text = text.replace(old, new, 1)

# 5) eksponer threshold i return fra tick
old = """    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
  };"""
new = """    threshold: autoPipelineThreshold,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
  };"""
if old in text:
    text = text.replace(old, new, 1)

p.write_text(text)
print("✅ Backend threshold er nå konfigurerbar")
PY

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

old = """                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _infoChip('Mode', fetchMode),
                                        _infoChip('Tick count', tickCount),
                                      ],
                                    ),"""

new = """                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _infoChip('Mode', fetchMode),
                                        _infoChip('Tick count', tickCount),
                                        _infoChip(
                                          'Threshold',
                                          (pipeline['threshold'] ?? '-').toString(),
                                        ),
                                      ],
                                    ),"""

if old not in text:
    raise SystemExit("❌ Fant ikke Feed status-chip-blokken i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ UI viser threshold i pipeline-panelet")
PY

node --check api/server.js
flutter analyze
echo "✅ 803 ferdig"
