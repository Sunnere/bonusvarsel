#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sørg for PremiumService import (vi legger den kun inn hvis den mangler)
if "premium_service.dart" not in s:
    # Prøv å legge den nær de andre imports
    lines = s.splitlines(True)
    out = []
    inserted = False
    for i, line in enumerate(lines):
        out.append(line)
        if (not inserted) and line.startswith("import") and "url_launcher" in line:
            out.append("import '../services/premium_service.dart';\n")
            inserted = True
    if not inserted:
        # fallback: etter første import
        for i, line in enumerate(out):
            if line.startswith("import"):
                out.insert(i+1, "import '../services/premium_service.dart';\n")
                inserted = True
                break
    s = "".join(out)

# 2) Sørg for at vi har premium-instans i State (kun hvis den ikke finnes fra før)
if re.search(r"\bPremiumService\b", s) and "_premiumSvc" not in s:
    # finn class _EbShoppingPageState åpning
    s = re.sub(
        r"(class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{\s*)",
        r"\1  final PremiumService _premiumSvc = PremiumService();\n",
        s,
        count=1,
        flags=re.M,
    )

# 3) Patch inne i builder: finn "final filtered" (eller lignende) og legg til gating
# Vi prøver flere mønstre for å være robuste.
anchors = [
    r"final\s+filtered\s*=\s*[^;]+;\s*",
    r"final\s+items\s*=\s*[^;]+;\s*",
]
m = None
for pat in anchors:
    m = re.search(pat, s)
    if m:
        anchor_pat = pat
        break

if not m:
    print("⚠️ Fant ikke et sted å sette gating (mangler 'final filtered = ...;'). Ingen endringer gjort.")
    p.write_text(s, encoding="utf-8")
    raise SystemExit(0)

insert_at = m.end()

# Ikke legg inn to ganger
if "FREE_LIMIT" in s or "Oppgrader til PRO" in s:
    print("✅ Gating ser allerede ut til å være lagt inn. Ingen endringer.")
    raise SystemExit(0)

gating_code = """
    const FREE_LIMIT = 30;

    return FutureBuilder<bool>(
      future: _premiumSvc.isPremium(),
      builder: (context, premiumSnap) {
        final isPremium = premiumSnap.data == true;

        final limited = isPremium ? filtered : filtered.take(FREE_LIMIT).toList();

        final upgradeBanner = (!isPremium)
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Se alle butikker + flere varsler: Oppgrader til PRO',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        // Naviger til Premium-siden (du har den allerede)
                        Navigator.of(context).pushNamed('/premium');
                      },
                      child: const Text('PRO'),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink();
"""

# Vi må også bytte ut videre bruk av "filtered" til "limited" i ListView.builder
# For å minimere risiko: vi patcher kun de vanligste: itemCount: filtered.length og filtered[i]
s2 = s[:insert_at] + gating_code + s[insert_at:]

s2 = re.sub(r"itemCount\s*:\s*filtered\.length", "itemCount: limited.length", s2)
s2 = re.sub(r"filtered\[\s*i\s*\]", "limited[i]", s2)

# Og vi må sørge for at banneret faktisk vises. Vi prøver å finne Column(children:[ ... ListView.builder ... ])
# Vi putter upgradeBanner som første child i en Column hvis det finnes.
if "upgradeBanner" in s2:
    s2 = re.sub(
        r"(children\s*:\s*\[\s*)",
        r"\\1upgradeBanner,\n",
        s2,
        count=1
    )

p.write_text(s2, encoding="utf-8")
print("✅ La inn free-vs-pro gating i eb_shopping_page.dart (FREE_LIMIT=30 + banner).")
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze
