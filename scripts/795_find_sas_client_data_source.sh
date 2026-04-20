#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="tmp/sas_debug"
HTML_FILE="$OUT_DIR/sas_campaigns.html"
JS_DIR="$OUT_DIR/js"
REPORT_FILE="$OUT_DIR/client_data_source_report.txt"

mkdir -p "$OUT_DIR" "$JS_DIR"

if [[ ! -f "$HTML_FILE" ]]; then
  echo "❌ Mangler $HTML_FILE. Kjør først scripts/794_debug_sas_scraper_locally.sh"
  exit 1
fi

python3 <<'PY'
from pathlib import Path
import re
import subprocess

out_dir = Path("tmp/sas_debug")
html_path = out_dir / "sas_campaigns.html"
js_dir = out_dir / "js"
report_path = out_dir / "client_data_source_report.txt"

html = html_path.read_text(errors="ignore")

lines = []
lines.append("=== SAS CLIENT DATA SOURCE REPORT ===")
lines.append("")

# Finn JS assets
js_refs = re.findall(r'/_nuxt/[^"\'> ]+\.js', html)
js_refs = list(dict.fromkeys(js_refs))[:15]

lines.append("=== SELECTED _nuxt JS FILES ===")
for ref in js_refs:
    lines.append(f"- {ref}")
lines.append("")

# Last ned et utvalg JS-filer
downloaded = []
for ref in js_refs:
    url = f"https://onlineshopping.flysas.com{ref}"
    dest = js_dir / Path(ref).name
    try:
        subprocess.run(
            ["curl", "-L", "--silent", "--show-error", "-A", "BonusVarsel/1.0 (Local Debug)", url, "-o", str(dest)],
            check=True,
        )
        downloaded.append(dest)
    except subprocess.CalledProcessError:
        lines.append(f"FAILED_DOWNLOAD: {url}")

patterns = [
    r'https://[^"\'\s)]+',
    r'"/[^"\n]+',
    r"'/[^'\n]+",
    r'fetch\(([^)]+)\)',
    r'useFetch\(([^)]+)\)',
    r'axios\.[a-zA-Z]+\(([^)]+)\)',
    r'\$fetch\(([^)]+)\)',
]

keywords = [
    "campaign", "kampanj", "kampanjer", "offer", "offers",
    "api", "graphql", "store", "merchant", "search", "promotion", "promo"
]

hits = []
for js_file in downloaded:
    txt = js_file.read_text(errors="ignore")
    for pat in patterns:
        for m in re.findall(pat, txt, flags=re.I):
            s = m if isinstance(m, str) else str(m)
            if any(k in s.lower() for k in keywords):
                hits.append((js_file.name, s[:300]))

    # også rå keyword-snutter
    for kw in keywords:
        for m in re.finditer(kw, txt, flags=re.I):
            start = max(0, m.start() - 120)
            end = min(len(txt), m.end() + 200)
            snippet = txt[start:end].replace("\n", " ")
            if any(x in snippet.lower() for x in ["fetch", "api", "/campaign", "/kamp", "graphql", "_payload"]):
                hits.append((js_file.name, snippet[:350]))

# Dedupe
seen = set()
deduped = []
for file, snippet in hits:
    key = (file, snippet)
    if key in seen:
        continue
    seen.add(key)
    deduped.append((file, snippet))

lines.append("=== POSSIBLE CLIENT DATA SOURCES / SNIPPETS ===")
if deduped:
    for file, snippet in deduped[:80]:
        lines.append(f"[{file}] {snippet}")
else:
    lines.append("No obvious client data source hits found.")
lines.append("")

# Se etter nuxt payload hints i HTML
lines.append("=== HTML PAYLOAD HINTS ===")
payload_hits = re.findall(r'__NUXT__[\s\S]{0,500}|_payload[^"\'> ]+|application/json[\s\S]{0,300}', html, flags=re.I)
if payload_hits:
    for h in payload_hits[:20]:
        lines.append(h[:500].replace("\n", " "))
else:
    lines.append("No useful payload hints found in HTML.")
lines.append("")

report_path.write_text("\n".join(lines))
print(report_path.read_text())
PY
