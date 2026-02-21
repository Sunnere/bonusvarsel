#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

echo "== 0) Forbered =="
mkdir -p scripts

echo "== 1) Finn backup (.bak*) hvis den finnes =="
BACKUP="$(ls -1t "${FILE}".bak* 2>/dev/null | head -n 1 || true)"

if [[ -n "${BACKUP}" ]]; then
  echo "Fant backup: ${BACKUP}"
  cp "${BACKUP}" "${FILE}"
  echo "✅ Restored fra backup"
else
  echo "Ingen .bak* funnet. Prøver Git restore..."
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # git restore (nyere git)
    if git restore "${FILE}" >/dev/null 2>&1; then
      echo "✅ Restored med: git restore ${FILE}"
    else
      # fallback (eldre git)
      git checkout -- "${FILE}"
      echo "✅ Restored med: git checkout -- ${FILE}"
    fi
  else
    echo "❌ Ikke et git-repo (eller git ikke tilgjengelig)."
    echo "   Da må vi ha en backup eller du må paste inn fila."
    exit 1
  fi
fi

echo "== 2) Sjekk at fila kan parses (dart format) =="
if ! dart format "${FILE}" >/dev/null 2>&1; then
  echo "❌ Fila kan fortsatt ikke parses etter restore."
  echo "   Kjør: sed -n '1,220p' ${FILE} | nl -ba | tail -n 40"
  echo "   (så tar vi en kirurgisk fiks)"
  exit 1
fi
echo "✅ dart format OK"

echo "== 3) Patch FilterChip label-tekst: aldri 'const Text' når fargen avhenger av state =="
python3 - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

def deconst_dynamic_text(block: str) -> str:
    # Bytt "label: const Text(" -> "label: Text(" ONLY if block contains "_onlyCampaigns ?" or "_favFirst ?"
    # (dvs dynamisk farge)
    return block.replace("label: const Text(", "label: Text(")

# Patch i to omganger ved å målrette chip-blokker som inneholder de to flaggene
# Vi tar litt bred regex rundt FilterChip(...) for å ikke ødelegge parenteser.
def patch_chip(flag_name: str, label_text: str, s: str) -> str:
    # Finn FilterChip-blokk som refererer flagget, og inneholder label teksten
    pattern = re.compile(r"(FilterChip\([\s\S]*?\))", re.M)
    out = []
    pos = 0
    changed = False
    for m in pattern.finditer(s):
        chunk = s[m.start():m.end()]
        if flag_name in chunk and label_text in chunk:
            new_chunk = chunk
            if "label: const Text(" in new_chunk and f"{flag_name} ?" in new_chunk:
                new_chunk = deconst_dynamic_text(new_chunk)
                changed = True
            out.append(s[pos:m.start()])
            out.append(new_chunk)
            pos = m.end()
        # else: do nothing
    if changed:
        out.append(s[pos:])
        return "".join(out)
    return s

s2 = s
s2 = patch_chip("_onlyCampaigns", "Kun kampanjer", s2)
s2 = patch_chip("_favFirst", "Favoritter først", s2)

if s2 != s:
    p.write_text(s2, encoding="utf-8")
    print("✅ Patch: fjernet const fra dynamiske chip-labels (ved behov)")
else:
    print("ℹ️ Ingen dynamiske const Text funnet (ingenting å endre)")
PY

echo "== 4) Format + analyze =="
dart format "${FILE}"
flutter analyze
echo "✅ Ferdig"
