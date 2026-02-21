#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sørg for at vi har en robust categories-bygging rett etter "final filtered = ..."
#    - Unik liste (Set), 'Alle' kun én gang, og alltid først.
categories_block = r"""
    // Categories (unik + alltid 'Alle' først)
    final categoriesSet = <String>{
      'Alle',
      ...filtered
          .map((e) => (e['category'] ?? '').toString().trim())
          .where((c) => c.isNotEmpty),
    };
    final categories = categoriesSet.toList()..sort();
    // Flytt 'Alle' til toppen (og sikre at den finnes bare én gang)
    categories.remove('Alle');
    categories.insert(0, 'Alle');
"""

# Finn "final filtered = ..." og injiser categories rett etter, hvis vi ikke allerede har en 'final categories'
if "final categoriesSet" not in s:
    m = re.search(r"(\n\s*final\s+filtered\s*=.*?;\s*)", s, flags=re.DOTALL)
    if not m:
        raise SystemExit("Fant ikke 'final filtered = ...;' i eb_shopping_page.dart (klarte ikke å plassere categories-blokk).")
    insert_at = m.end(1)
    s = s[:insert_at] + categories_block + s[insert_at:]


# 2) Bytt DropdownButtonFormField<String>(...) til en safe variant som:
#    - value = categories.contains(_category) ? _category : 'Alle'
#    - items = categories (unik) => DropdownMenuItem
dropdown_re = re.compile(
    r"DropdownButtonFormField<String>\(\s*(?:.|\n)*?\)\s*,",
    flags=re.DOTALL
)

safe_dropdown = r"""DropdownButtonFormField<String>(
                      value: categories.contains(_category) ? _category : 'Alle',
                      items: categories
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _category = v);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Kategori',
                      ),
                    ),"""

# Bytt første forekomst (typisk bare én dropdown)
if dropdown_re.search(s):
    s = dropdown_re.sub(safe_dropdown, s, count=1)
else:
    # Hvis regex ikke traff, gi en tydelig feilmelding
    raise SystemExit("Fant ikke DropdownButtonFormField<String>(...) i forventet form. Send et utdrag rundt dropdownen så lager jeg en mer presis patch.")

p.write_text(s, encoding="utf-8")
print("✅ Patchet categories + safe dropdown (unngår 'Alle' duplikat / value mismatch).")
PY

dart format "$FILE" >/dev/null || true
flutter analyze
