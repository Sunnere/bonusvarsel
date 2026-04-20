#!/usr/bin/env bash
set -euo pipefail

echo "==> 769_center_field_labels_fix_budget_text_and_hide_empty_storetypes"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_769")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1) Flytt label litt ned i mørke inputfelt
text = text.replace(
    "contentPadding: const EdgeInsets.fromLTRB(18, 22, 18, 16),",
    "contentPadding: const EdgeInsets.fromLTRB(18, 24, 18, 14),"
)

text = text.replace(
    "height: 1.15,",
    "height: 1.25,"
)

# 2) Gjør hjelpertekst under planlagt kjøp mørkere
text = text.replace(
"""                      Text(
                        cardLabel,
                        style: _travelMutedTextStyle(context),
                      ),""",
"""                      Text(
                        cardLabel,
                        style: _travelMutedTextStyle(context).copyWith(
                              color: const Color(0xFF465B63),
                              fontWeight: FontWeight.w700,
                            ),
                      ),"""
)

# 3) Gjør "Foreløpig estimat" og "0 poeng" tydeligere
text = text.replace(
"""                      Text(
                        'Foreløpig estimat',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),""",
"""                      Text(
                        'Foreløpig estimat',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF35515A),
                              fontWeight: FontWeight.w800,
                            ),
                      ),"""
)

text = text.replace(
"""                      Text(
                        '$estPoints poeng',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),
                      ),""",
"""                      Text(
                        '$estPoints poeng',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              color: const Color(0xFF0A6E78),
                            ),
                      ),"""
)

# 4) Gjør label i saldo/budsjett-feltene litt mer lesbar
text = text.replace(
    "color: Color(0xFFD6E5EE),",
    "color: Color(0xFFE3EEF4),"
)
text = text.replace(
    "color: Color(0xFFEAF5FA),",
    "color: Color(0xFFF3FAFD),"
)

# 5) Skjul hele "Butikktyper som passer best"-seksjonen når den bare er tom ikonliste
pattern = re.compile(
    r"""
(?P<block>
\s*const\s+SizedBox\(height:\s*14\),\s*
\s*Card\(
.*?
'Butikktyper\s+som\s+passer\s+best'
.*?
'Live-blokken\s+viser\s+anbefalte\s+butikker\s+basert\s+på\s+planen\s+din\.'
.*?
\s*\),\s*
)
""",
    re.DOTALL | re.VERBOSE,
)

m = pattern.search(text)
if m:
    block = m.group('block')
    replacement = """
              if (storeSuggestions.any((s) => (s.title).trim().isNotEmpty))
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butikktyper som passer best',
                          style: _sectionTitleStyle(context),
                        ),
                        const SizedBox(height: 12),
                        for (final s in storeSuggestions.take(5)) ...[
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF20353D),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          'Live-blokken viser anbefalte butikker basert på planen din.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF60747C),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
"""
    text = text[:m.start()] + replacement + text[m.end():]

# 6) Hvis feltverdier fortsatt virker litt for høyt oppe, gi dem litt mer luft optisk
text = text.replace(
    "fontSize: 15,\n      fontWeight: FontWeight.w800,",
    "fontSize: 15,\n      fontWeight: FontWeight.w800,\n      height: 1.15,"
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Patched: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
