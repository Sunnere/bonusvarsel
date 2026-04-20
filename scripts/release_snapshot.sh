#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="tmp/release_snapshot_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p tmp

{
  echo "== Bonusvarsel release snapshot =="
  echo "Dato: $(date)"
  echo
  echo "-- git status --"
  git status --short || true
  echo
  echo "-- flutter analyze --"
  flutter analyze || true
  echo
  echo "-- launch docs --"
  ls -1 docs/launch || true
  echo
  echo "-- release scripts --"
  ls -1 scripts/release_checklist_run.sh \
        scripts/run_prod_like_web.sh \
        scripts/verify_dev_hub_hidden.sh \
        scripts/release_snapshot.sh 2>/dev/null || true
} | tee "$OUT"

echo
echo "✅ Snapshot lagret i $OUT"
