#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_767_inspect_travel_calc_and_help_logic"
echo

echo "==> Søker etter Reisesiden og beregning"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nE "Estimert opptjening|poeng|Reisebeløp|Bonusprogram|SAS EuroBonus|250 poeng|gå til Kort|velg et kort|EB per krone|per krone" || true

echo
echo "==> Søker etter regneuttrykk"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nE "travel|reise|amount|beløp|estimate|estimated|points|earn|earning|opptjening|bonusrate|rate" || true

echo
echo "✅ Ferdig"
echo "Lim inn outputen her, så kan jeg si ærlig om beregningen ser riktig ut eller ikke."
