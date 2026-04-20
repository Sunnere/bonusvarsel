#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_830.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

replacements = [
    (
"""      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(""",
"""      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column("""
    ),
    (
"""      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(""",
"""      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column("""
    ),
    (
"""      body: Column(""",
"""      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column("""
    ),
]

changed = False
for old, new in replacements:
    if old in text:
        text = text.replace(old, new, 1)
        changed = True
        break

if not changed:
    raise SystemExit("❌ Fant ikke body-mønsteret trygt nok til å gjøre scroll-fix")

# Lukk igjen SafeArea/Scrollbar/SingleChildScrollView rundt body
closing_candidates = [
    (
"""        ],
      ),
    );
  }""",
"""        ],
      ),
    ),
        ),
      ),
    );
  }"""
    ),
]

closed = False
for old, new in closing_candidates:
    if old in text:
        text = text.replace(old, new, 1)
        closed = True
        break

if not closed:
    raise SystemExit("❌ Fant ikke trygg slutt på build()-body for scroll-fix")

# Legg inn litt ekstra bunnluft før avslutning av hoved-children hvis ikke allerede finnes
needle = """          _decisionInsightCard(),
"""
if needle in text and "const SizedBox(height: 48)," not in text:
    text = text.replace(
        needle,
        needle + "          const SizedBox(height: 48),\n",
        1,
    )

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn SafeArea + Scrollbar + SingleChildScrollView i Dev Hub")
PY

echo
flutter analyze
echo "✅ 830 ferdig"
