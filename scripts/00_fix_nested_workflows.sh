#!/usr/bin/env bash
set -euo pipefail

SRC=".github/workflows/.github/workflows"
DST=".github/workflows"
TS="$(date +%s)"
BAK=".github/workflows/_bak_nested_$TS"

echo "== Fix nested workflows =="
echo "SRC: $SRC"
echo "DST: $DST"

if [[ ! -d "$SRC" ]]; then
  echo "Ingen nested workflows funnet. Ferdig."
  exit 0
fi

mkdir -p "$DST" "$BAK"

echo "1) Backup av hele nested-mappa -> $BAK"
cp -a "$SRC" "$BAK/"

echo "2) Flytter YAML-filer til riktig mappe:"
shopt -s nullglob
for f in "$SRC"/*.yml "$SRC"/*.yaml; do
  base="$(basename "$f")"

  if [[ -f "$DST/$base" ]]; then
    echo "  - Finnes allerede: $DST/$base"
    echo "    -> Beholder eksisterende, og legger nested som: $DST/${base%.yml}.nested.$TS.yml"
    # håndter både .yml og .yaml
    if [[ "$base" == *.yaml ]]; then
      mv "$f" "$DST/${base%.yaml}.nested.$TS.yaml"
    else
      mv "$f" "$DST/${base%.yml}.nested.$TS.yml"
    fi
  else
    echo "  - Flytter: $base -> $DST/"
    mv "$f" "$DST/"
  fi
done

echo "3) Sletter nested .github-mappe inne i workflows (hvis den finnes)"
rm -rf "$DST/.github" 2>/dev/null || true

echo "4) Sletter nå tomme nested-mapper"
rm -rf "$SRC"

echo
echo "✅ Ferdig."
echo "Sjekk nå:"
echo "  ls -la .github/workflows"
echo "  rg -n \"\\.github/workflows/\\.github/workflows\" -S .github/workflows || true"
echo
echo "Tips: Hvis du fikk *.nested.$TS.yml, sammenlign de to filene og slett den du ikke vil ha."
