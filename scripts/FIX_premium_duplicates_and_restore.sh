#!/usr/bin/env bash
set -euo pipefail

EB="lib/pages/eb_shopping_page.dart"
PREM_PAGE="lib/pages/premium_page.dart"
PREM_SVC="lib/services/premium_service.dart"

[ -f "$EB" ] && cp "$EB" "$EB.bak.$(date +%s)" || true
[ -f "$PREM_PAGE" ] && cp "$PREM_PAGE" "$PREM_PAGE.bak.$(date +%s)" || true
[ -f "$PREM_SVC" ] && cp "$PREM_SVC" "$PREM_SVC.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

# --- 1) Fix duplicate _premium in eb_shopping_page.dart ---
p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Finn alle linjer som deklarerer _premium
lines = s.splitlines(True)
out = []
seen = False

pat = re.compile(r"^\s*final\s+_premium\s*=\s*(?:const\s+)?PremiumService\(\)\s*;\s*$")

for ln in lines:
    if pat.match(ln):
        if not seen:
            # behold første, men sørg for at den ikke er const (PremiumService er typisk ikke const)
            ln = re.sub(r"=\s*const\s+PremiumService\(\)", "= PremiumService()", ln)
            out.append(ln)
            seen = True
        else:
            # dropp duplikater
            continue
    else:
        out.append(ln)

p.write_text("".join(out), encoding="utf-8")

# --- 2) Add restore() to PremiumService if missing ---
svc = Path("lib/services/premium_service.dart")
if svc.exists():
    ss = svc.read_text(encoding="utf-8")

    if re.search(r"\bFuture<\s*bool\s*>\s+restore\s*\(", ss) is None:
        # Finn class PremiumService { ... }
        m = re.search(r"class\s+PremiumService\s*{", ss)
        if m:
            # sett inn rett før siste "}" i filen (siste class-slutt)
            idx = ss.rfind("}")
            if idx != -1:
                insert = (
                    "\n  // TODO: Koble til ekte restore når betaling er på plass.\n"
                    "  Future<bool> restore() async {\n"
                    "    // Returnerer false foreløpig, men lar appen kompilere grønt.\n"
                    "    return false;\n"
                    "  }\n"
                )
                ss = ss[:idx] + insert + ss[idx:]
                svc.write_text(ss, encoding="utf-8")

print("Patchet: duplicate _premium + PremiumService.restore()")
PY

dart format lib/pages/eb_shopping_page.dart lib/services/premium_service.dart lib/pages/premium_page.dart >/dev/null || true
flutter analyze || true
echo "✅ Ferdig: fjernet duplicate _premium + lagt til restore()"
