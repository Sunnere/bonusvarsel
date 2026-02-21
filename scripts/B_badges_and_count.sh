#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sikre at vi har en isCampaign(...) helper i build (A-scriptet legger den inn).
# Hvis den mangler, legger vi inn en minimal versjon i nærheten av nameOf(...)
if "bool isCampaign(" not in s:
    s = re.sub(
        r"(String nameOf\(Map<String, dynamic> m\)[\s\S]*?;\n)",
        r"""\1
          bool isCampaign(Map<String, dynamic> m) {
            final v = m['isCampaign'];
            return v == true || v == 1 || v == '1' || v == 'true';
          }
""",
        s,
        count=1,
    )

# 2) Legg inn count under filterBar i A sin layout:
# Finn NestedScrollView(...) body: ListView.builder(...
# og legg inn en liten header i body (før ListView) via Column.
# Vi bytter:
# body: ListView.builder(
#   ...
# )
# til:
# body: Column(children:[countRow, Expanded(child: ListView.builder(...))])
pattern_body = r"body:\s*ListView\.builder\("
m = re.search(pattern_body, s)
if not m:
    raise SystemExit("Fant ikke 'body: ListView.builder(' (B forventer A-layout).")

# Finn startpos for body: ListView.builder(
start = m.start()

# Finn matching parentes til ListView.builder( ... );
# Vi tar fra "body: ListView.builder(" til den avsluttende ");" på samme nivå.
sub = s[start:]
# Finn første '(' etter ListView.builder
lp = sub.find("ListView.builder(")
lp = start + lp
lp_paren = s.find("(", lp)
depth = 0
end = None
in_str = False
esc = False
q = ""

for i in range(lp_paren, len(s)):
    ch = s[i]
    if in_str:
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == q:
            in_str = False
        continue
    else:
        if ch in ("'", '"'):
            in_str = True
            q = ch
            continue

    if ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
        if depth == 0:
            # forvent at neste ikke-whitespace er ';'
            j = i + 1
            while j < len(s) and s[j].isspace():
                j += 1
            if j < len(s) and s[j] == ";":
                end = j
                break

if end is None:
    raise SystemExit("Klarte ikke å finne slutten av ListView.builder(...) ;")

listview_block = s[start:end+1]

# Erstatt med Column + Expanded
# Vi bruker filtered.length og litt tekst.
replacement = """body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} butikker',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (_onlyCampaigns)
                        const Text('Kun kampanjer', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Expanded(
                  child: """ + listview_block.strip().replace("body: ", "", 1) + """
                ),
              ],
            ),"""

s = s.replace(listview_block, replacement, 1)

# 3) Legg inn Kampanje-badge i ListTile title (på kortet)
# Finn "title: Text(name)," og bytt til en Row med badge om isCampaign(m)
s = re.sub(
    r"title:\s*Text\(name\),",
    """title: Row(
                      children: [
                        Expanded(child: Text(name)),
                        if (isCampaign(m))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.35)),
                            ),
                            child: Text(
                              'Kampanje',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),""",
    s,
    count=1,
)

# 4) Gjør subtitle litt tydeligere (poeng)
s = re.sub(
    r"subtitle:\s*Text\('\$rate poeng per 100 kr'\),",
    "subtitle: Text('$rate poeng / 100 kr', style: const TextStyle(fontWeight: FontWeight.w600)),",
    s,
    count=1,
)

p.write_text(s, encoding="utf-8")
print("✅ B: Kampanje-badge + count patched")
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze

kill $(lsof -ti :8080) 2>/dev/null || true
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
