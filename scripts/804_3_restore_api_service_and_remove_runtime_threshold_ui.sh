#!/usr/bin/env bash
set -euo pipefail

API_FILE="lib/services/api_service.dart"
PANEL_FILE="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_FILE" ]] || { echo "❌ Fant ikke $API_FILE"; exit 1; }
[[ -f "$PANEL_FILE" ]] || { echo "❌ Fant ikke $PANEL_FILE"; exit 1; }

cp "$API_FILE" "$API_FILE.bak_recovery_804_3.$(date +%s)"
cp "$PANEL_FILE" "$PANEL_FILE.bak_recovery_804_3.$(date +%s)"
echo "✅ Recovery-backup laget"

python3 <<'PY'
from pathlib import Path
import shutil
import re

api_file = Path("lib/services/api_service.dart")

# Finn beste backup som faktisk ser ut som en gyldig ApiService
candidates = []
for pat in ["api_service.dart.bak_*", "api_service.dart.bak.*"]:
    candidates.extend(api_file.parent.glob(pat))

required = [
    "class ApiService",
    "_uri(",
    "getActivatedNotifications",
    "sendTestPush",
    "clearPushQueue",
    "seedDevOffer",
    "resetDevState",
    "getPushDispatchPreview",
    "simulateCampaignPipeline",
]

def score(path: Path):
    try:
        txt = path.read_text()
    except Exception:
        return -1
    s = 0
    for r in required:
        if r in txt:
            s += 1
    return s

scored = sorted(
    [(score(p), p.stat().st_mtime, p) for p in candidates],
    reverse=True,
)

best = None
for s, _, p in scored:
    if s >= len(required) - 1:
        best = p
        break

if best is None:
    raise SystemExit("❌ Fant ingen god api_service-backup med nødvendige metoder")

shutil.copyfile(best, api_file)
print(f"✅ Gjenopprettet ApiService fra backup: {best.name}")

panel_file = Path("lib/widgets/dev_pipeline_panel.dart")
text = panel_file.read_text()

# Fjern threshold state-felter
text = text.replace(
    "  final TextEditingController _thresholdController = TextEditingController();\n  bool _savingThreshold = false;\n",
    "",
)

# Fjern dispose-linje for threshold controller
text = text.replace("    _thresholdController.dispose();\n", "")

# Fjern oppdatering av threshold-controller fra _refreshStatus/_apply state
text = re.sub(
    r"""
    \n\s*final\s+pipeline\s*=\s*result\['pipeline'\];
    \n\s*if\s*\(pipeline\s+is\s+Map\)\s*\{
    [\s\S]*?
    \n\s*\}
    \n
    """,
    "\n",
    text,
    count=1,
    flags=re.VERBOSE,
)

# Fjern _saveThreshold-metoden
text = re.sub(
    r"""
    \n\s*Future<void>\s+_saveThreshold\(\)\s+async\s*\{
    [\s\S]*?
    \n\s*\}
    \n
    """,
    "\n",
    text,
    count=1,
    flags=re.VERBOSE,
)

# Fjern Threshold-chip
text = text.replace(
    """                                        _infoChip(
                                          'Threshold',
                                          (pipeline['threshold'] ?? '-').toString(),
                                        ),
""",
    "",
)

# Fjern Threshold control UI
text = re.sub(
    r"""
    \n\s*const\s+SizedBox\(height:\s*10\),
    \n\s*const\s+Text\(
    \n\s*'Threshold control',
    [\s\S]*?
    \n\s*\),
    \n\s*const\s+SizedBox\(height:\s*6\),
    \n\s*Row\(
    [\s\S]*?
    \n\s*\),
    """,
    "",
    text,
    count=1,
    flags=re.VERBOSE,
)

panel_file.write_text(text)
print("✅ Fjernet runtime threshold UI fra DevPipelinePanel")
PY

flutter analyze
echo "✅ 804.3 ferdig"
