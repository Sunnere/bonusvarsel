#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

def patch_chip(label_text, flag_name):
    """
    Bytter Text('LABEL') til Text('LABEL', style: ...)
    og forsøker å legge på farge/kontrast i FilterChip.
    """
    nonlocal_s = globals()["s"]

    # 1) Label Text style (hvit når valgt)
    # Treffer både 'Text("..")' og "Text('..')"
    pat_text = re.compile(rf"Text\(\s*['\"]{re.escape(label_text)}['\"]\s*\)")
    nonlocal_s, n1 = pat_text.subn(
        rf"Text('{label_text}', style: TextStyle(color: {flag_name} ? Colors.white : Colors.black87, fontWeight: FontWeight.w700))",
        nonlocal_s,
        count=1,
    )

    # 2) I samme FilterChip: sørg for tydelige farger (selectedColor/checkmarkColor)
    # Vi finner en FilterChip(...) blokk som inneholder label_text og patcher inn props hvis de mangler
    pat_chip = re.compile(r"FilterChip\(\s*([\s\S]*?)\)\s*,", re.MULTILINE)
    def repl(m):
        body = m.group(1)
        if label_text not in body:
            return m.group(0)

        # sett inn standard props hvis de ikke finnes
        inserts = []
        if "selectedColor:" not in body:
            inserts.append("selectedColor: Theme.of(context).colorScheme.primary,")
        if "backgroundColor:" not in body:
            inserts.append("backgroundColor: Colors.grey.shade200,")
        if "checkmarkColor:" not in body:
            inserts.append("checkmarkColor: Colors.white,")
        if "side:" not in body:
            inserts.append("side: BorderSide(color: Colors.black12),")
        if inserts:
            # legg dem rett etter 'FilterChip(' start
            body = "\n      " + "\n      ".join(inserts) + "\n      " + body.lstrip()
        return "FilterChip(" + body + "),"

    nonlocal_s2, n2 = pat_chip.subn(repl, nonlocal_s, count=50)

    globals()["s"] = nonlocal_s2
    return n1, n2

s = s  # make global for patch fn
changed_any = False

# patch de to vi bryr oss om
n1a, n2a = patch_chip("Kun kampanjer", "_onlyCampaigns")
n1b, n2b = patch_chip("Favoritter først", "_favFirst")

changed_any = (n1a+n2a+n1b+n2b) > 0

p.write_text(s, encoding="utf-8")

print("✅ Patch-resultat:")
print(f"- Kun kampanjer: label patched={n1a}, chip patched={n2a}")
print(f"- Favoritter først: label patched={n1b}, chip patched={n2b}")
if not changed_any:
    print("⚠️ Fant ikke forventet chip-tekst. Sjekk at chips faktisk heter 'Kun kampanjer' og 'Favoritter først' i filen.")
PY

dart format "$FILE"
flutter analyze
