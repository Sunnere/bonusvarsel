#!/usr/bin/env bash
# 03_onboarding_spenn_cards.sh
# Legger til Spenn-kort og "Kommer snart"-kort på onboarding steg 2
# (rett etter "Kort og kampanjer", før "NYTT: Spenn-varsler").
# Avbryter uten å skrive noe hvis ankeret ikke finnes nøyaktig én gang.
set -euo pipefail

ROOT="${ROOT:-$HOME/bonusvarsel}"
cd "$ROOT"
echo "🔧 Legger til Spenn-kort i: $(pwd)"

python3 - <<'PY'
import os, pathlib, datetime, sys

root = pathlib.Path(os.getcwd())
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
f = "lib/pages/onboarding_page.dart"
p = root / f
if not p.exists():
    print(f"❌ Finner ikke fil: {f}")
    sys.exit(1)

text = p.read_text(encoding="utf-8")

anchor = (
"          subtitle: 'Se hvilke valg som kan gi mest verdi.',\n"
"          accent: _blue,\n"
"        ),\n"
)
new_cards = (
"        _bullet(\n"
"          icon: Icons.savings_outlined,\n"
"          title: 'Spenn',\n"
"          subtitle: 'Tjen poeng på dagligvarer, bensin og kort.',\n"
"          accent: _blue,\n"
"        ),\n"
"        _bullet(\n"
"          icon: Icons.schedule,\n"
"          title: 'Kommer snart',\n"
"          subtitle: 'Avios, Flying Blue og Amex MR. Premium varsler deg når de er klare.',\n"
"          accent: Colors.grey,\n"
"        ),\n"
)

count = text.count(anchor)
if count != 1:
    print(f"❌ Avbrutt – fant {count} treff for ankeret, forventet 1. Ingen filer er endret.")
    sys.exit(1)

if "title: 'Kommer snart'" in text:
    print("❌ Avbrutt – 'Kommer snart' finnes allerede i filen. Ingen filer er endret.")
    sys.exit(1)

new_text = text.replace(anchor, anchor + new_cards)
bak = p.with_name(p.name + f".bak_copy_{ts}")
bak.write_text(text, encoding="utf-8")
p.write_text(new_text, encoding="utf-8")
print(f"✅ Oppdatert: {f}  (backup: {bak.name})")
print("✅ Ferdig – Spenn-kort og 'Kommer snart'-kort lagt til.")
PY
