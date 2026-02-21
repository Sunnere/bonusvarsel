#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re

# 1) Fjern duplikat av _premium i eb_shopping_page.dart (behold første)
p = Path("lib/pages/eb_shopping_page.dart")
if p.exists():
    s = p.read_text(encoding="utf-8")
    lines = s.splitlines(True)
    out = []
    seen = 0
    for line in lines:
        if re.search(r'^\s*final\s+_premium\s*=\s*.*PremiumService\(\)\s*;\s*$', line):
            seen += 1
            if seen > 1:
                continue
        out.append(line)
    if out != lines:
        p.write_text("".join(out), encoding="utf-8")

# 2) Finn fila som inneholder class PremiumService, legg til restore() hvis den mangler
candidates = list(Path("lib").rglob("*.dart"))
svc_file = None
for f in candidates:
    try:
        txt = f.read_text(encoding="utf-8")
    except:
        continue
    if re.search(r'\bclass\s+PremiumService\b', txt):
        svc_file = f
        break

if svc_file is None:
    # lag en enkel service om den ikke finnes
    svc_file = Path("lib/services/premium_service.dart")
    svc_file.parent.mkdir(parents=True, exist_ok=True)
    txt = "import 'package:shared_preferences/shared_preferences.dart';\n\nclass PremiumService {\n  const PremiumService();\n\n  static const _k = 'is_premium';\n\n  Future<bool> isPremium() async {\n    final p = await SharedPreferences.getInstance();\n    return p.getBool(_k) ?? false;\n  }\n\n  Future<void> setPremium(bool v) async {\n    final p = await SharedPreferences.getInstance();\n    await p.setBool(_k, v);\n  }\n}\n"
else:
    txt = svc_file.read_text(encoding="utf-8")

if "restore(" not in txt:
    # legg inn restore() før siste }
    m = re.search(r'(}\s*)\Z', txt, flags=re.S)
    if m:
        insert = "\n  Future<void> restore() async {\n    // TODO: koble til App Store / Play restore når du legger inn ekte kjøp\n  }\n"
        txt = txt[:m.start()] + insert + txt[m.start():]
        svc_file.write_text(txt, encoding="utf-8")

print(f"✅ Patchet: {p} og restore() i {svc_file}")
PY

dart format lib/pages/eb_shopping_page.dart lib/pages/premium_page.dart lib/services || true
flutter analyze
