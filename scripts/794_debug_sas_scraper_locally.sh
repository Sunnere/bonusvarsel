#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="tmp/sas_debug"
HTML_FILE="$OUT_DIR/sas_campaigns.html"
REPORT_FILE="$OUT_DIR/report.txt"

mkdir -p "$OUT_DIR"

echo "🌐 Laster ned SAS kampanjeside..."
curl -L --silent --show-error \
  -A "BonusVarsel/1.0 (Local Debug)" \
  "https://onlineshopping.flysas.com/nb-NO/kampanjer/1" \
  -o "$HTML_FILE"

echo "✅ Lagret HTML i $HTML_FILE"

python3 <<'PY'
from pathlib import Path
import re

html_path = Path("tmp/sas_debug/sas_campaigns.html")
report_path = Path("tmp/sas_debug/report.txt")
html = html_path.read_text(errors="ignore")

lines = []
lines.append("=== SAS SCRAPER DEBUG REPORT ===")
lines.append(f"HTML size: {len(html)} bytes")
lines.append("")

needles = [
    "poeng", "bonus", "kampanj", "campaign", "offers",
    "__NUXT__", "_nuxt", "graphql", "api", "store", "merchant"
]

lines.append("=== KEYWORD HITS ===")
for needle in needles:
    count = html.lower().count(needle.lower())
    lines.append(f"{needle}: {count}")
lines.append("")

lines.append("=== TITLE TAG ===")
m = re.search(r"<title>(.*?)</title>", html, re.I | re.S)
lines.append(m.group(1).strip() if m else "No title found")
lines.append("")

lines.append("=== TOP 40 TEXT SNIPPETS THAT LOOK INTERESTING ===")
text = re.sub(r"<script[\s\S]*?</script>", " ", html, flags=re.I)
text = re.sub(r"<style[\s\S]*?</style>", " ", text, flags=re.I)
text = re.sub(r"<[^>]+>", "\n", text)
text = re.sub(r"\s+", " ", text)

raw_candidates = re.findall(
    r"[^.]{0,80}(?:poeng|bonus|\b\d+\s*x\b)[^.]{0,120}",
    text,
    flags=re.I
)

seen = set()
count = 0
for c in raw_candidates:
    cleaned = " ".join(c.split()).strip()
    if len(cleaned) < 8:
        continue
    if cleaned.lower() in seen:
        continue
    seen.add(cleaned.lower())
    lines.append(f"- {cleaned}")
    count += 1
    if count >= 40:
        break
if count == 0:
    lines.append("No candidate text snippets found.")
lines.append("")

lines.append("=== TOP 60 LINKS WITH INTERESTING TEXT OR URL ===")
anchor_pattern = re.compile(
    r"<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>([\s\S]*?)</a>",
    re.I
)

anchors = []
for href, inner in anchor_pattern.findall(html):
    inner_text = re.sub(r"<[^>]+>", " ", inner)
    inner_text = " ".join(inner_text.split())
    hay = f"{href} {inner_text}".lower()
    if any(k in hay for k in ["poeng", "bonus", "kamp", "campaign"]) or re.search(r"\b\d+\s*x\b", hay):
        anchors.append((href, inner_text))

seen = set()
for href, txt in anchors[:200]:
    key = (href, txt)
    if key in seen:
        continue
    seen.add(key)
    lines.append(f"- href={href} | text={txt}")
    if len(seen) >= 60:
        break
if not seen:
    lines.append("No interesting anchors found.")
lines.append("")

lines.append("=== NUXT / JSON-LIKE HINTS ===")
jsonish = re.findall(r"__NUXT__|_nuxt|application/ld\+json|\"multiplier\"|\"campaign\"|\"store\"|\"merchant\"", html, flags=re.I)
if jsonish:
    for j in sorted(set(jsonish), key=str.lower):
        lines.append(f"- {j}")
else:
    lines.append("No obvious JSON hints found.")
lines.append("")

lines.append("=== FIRST 20 _nuxt ASSET REFERENCES ===")
nuxt_refs = re.findall(r"/_nuxt/[^\"'> ]+", html)
for ref in nuxt_refs[:20]:
    lines.append(f"- {ref}")
if not nuxt_refs:
    lines.append("No _nuxt refs found.")
lines.append("")

report_path.write_text("\n".join(lines))
print(report_path.read_text())
PY

echo
echo "📄 Åpne filene hvis du vil:"
echo "  - $HTML_FILE"
echo "  - $REPORT_FILE"
