#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_766_inspect_overflow_modal_sources"
echo

echo "==> Søker etter teksten fra overflow-dialogen"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nE "Lås opp Elite-fordeler|Elite gir tilgang|Du kan gå glipp av bedre rate|Alt i Premium|locked_ad" || true

echo
echo "==> Søker etter dialog/bottomsheet-kode"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nE "showDialog|AlertDialog|Dialog\(|showModalBottomSheet|bottomSheet|SingleChildScrollView|RenderFlex|overflow" || true

echo
echo "✅ Ferdig"
echo "Lim inn outputen her, så lager jeg en presis fix-cat for akkurat den modalen."
