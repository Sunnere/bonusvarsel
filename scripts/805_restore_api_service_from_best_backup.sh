#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/services/api_service.dart"
DIR="lib/services"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }
[[ -d "$DIR" ]] || { echo "❌ Fant ikke $DIR"; exit 1; }

cp "$TARGET" "$TARGET.bak_805_before_restore.$(date +%s)"
echo "✅ Backup laget av ødelagt fil: $TARGET"

python3 <<'PY'
from pathlib import Path
import shutil

target = Path("lib/services/api_service.dart")
dirp = Path("lib/services")

required = [
    "class ApiService",
    "simulateCampaignPipeline",
    "getActivatedNotifications",
    "sendTestPush",
    "clearPushQueue",
    "seedDevOffer",
    "resetDevState",
    "getPushDispatchPreview",
    "_uri(",
]

candidates = []
for pat in ["api_service.dart.bak_*", "api_service.dart.bak.*"]:
    candidates.extend(dirp.glob(pat))

def score(path: Path):
    try:
        txt = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return (-1, 0, "")
    hits = sum(1 for r in required if r in txt)
    return (hits, int(path.stat().st_mtime), txt)

ranked = []
for p in candidates:
    hits, mtime, txt = score(p)
    ranked.append((hits, mtime, p, txt))

ranked.sort(reverse=True, key=lambda x: (x[0], x[1]))

if not ranked:
    raise SystemExit("❌ Fant ingen api_service-backups")

best_hits, _, best_path, best_text = ranked[0]

print("=== Backup-kandidater (topp 10) ===")
for hits, mtime, p, _ in ranked[:10]:
    print(f"{hits:>2}  {p.name}")

if best_hits < 7:
    raise SystemExit("❌ Fant ingen backup som ser frisk nok ut til trygg restore")

shutil.copyfile(best_path, target)
print(f"\n✅ Gjenopprettet {target} fra {best_path.name}")
PY

echo
echo "=== Bekreft nøkkelmetoder i gjenopprettet fil ==="
grep -n "simulateCampaignPipeline\|getActivatedNotifications\|sendTestPush\|clearPushQueue\|seedDevOffer\|resetDevState\|getPushDispatchPreview" "$TARGET" || true

echo
flutter analyze
echo "✅ 805 ferdig"
