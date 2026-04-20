#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/services/api_service.dart"
DIR="lib/services"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }
[[ -d "$DIR" ]] || { echo "❌ Fant ikke $DIR"; exit 1; }

cp "$TARGET" "$TARGET.bak_806_broken_$(date +%s)"
echo "✅ Backup laget av nåværende ødelagte fil"

python3 <<'PY'
from pathlib import Path
import shutil

target = Path("lib/services/api_service.dart")
dirp = Path("lib/services")

required = [
    "class ApiService",
    "getActivatedNotifications",
    "sendTestPush",
    "clearPushQueue",
    "seedDevOffer",
    "resetDevState",
    "getPushDispatchPreview",
    "simulateCampaignPipeline",
]

candidates = []
for pat in ["api_service.dart.bak.*", "api_service.dart.bak_*"]:
    candidates.extend(dirp.glob(pat))

if not candidates:
    raise SystemExit("❌ Fant ingen backup-filer for api_service.dart")

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

ranked.sort(key=lambda x: (x[0], x[1]), reverse=True)

print("=== Kandidater ===")
for hits, _, p, _ in ranked[:15]:
    print(f"{hits:>2}  {p.name}")

best_hits, _, best_path, best_text = ranked[0]

if best_hits < 6:
    raise SystemExit("❌ Fant ingen backup som ser frisk nok ut")

shutil.copyfile(best_path, target)
print(f"\n✅ Gjenopprettet fra: {best_path.name}")
PY

echo
echo "=== Verifiser nøkkelmetoder ==="
grep -n "getActivatedNotifications\|sendTestPush\|clearPushQueue\|seedDevOffer\|resetDevState\|getPushDispatchPreview\|simulateCampaignPipeline" "$TARGET" || true

echo
flutter analyze
echo "✅ 806 ferdig"
