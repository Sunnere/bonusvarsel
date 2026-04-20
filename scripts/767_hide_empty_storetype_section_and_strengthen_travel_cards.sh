#!/usr/bin/env bash
set -euo pipefail

echo "==> 767_hide_empty_storetype_section_and_strengthen_travel_cards"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_767")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1) Skjul tom butikktype-seksjon midlertidig
text = text.replace(
"""                      Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),""",
"""                      if (storeSuggestions.isNotEmpty)
                        Text(
                          'Butikktyper som passer best',
                          style: _sectionTitleStyle(context),
                        ),"""
)

text = text.replace(
"""                      const SizedBox(height: 12),
                      for (final s in storeSuggestions.take(5)) ...[
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.title)),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        'Live-blokken viser anbefalte butikker basert på planen din.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),""",
"""                      if (storeSuggestions.isNotEmpty) ...[
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
                                color: const Color(0xFF4A5F67),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],"""
)

# 2) Gjør Reiseprofil-card tydeligere
text = text.replace(
"border: Border.all(color: const Color(0xFFDCE7ED)),",
"border: Border.all(color: const Color(0xFFD7E4EA), width: 1.2),"
)

text = text.replace(
"""boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],""",
"""boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],"""
)

# 3) Gjør Poengplan til en sterkere highlight
text = text.replace(
"""                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE9A8),
                      Color(0xFFF6D772),
                    ],""",
"""                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE7A0),
                      Color(0xFFF3CB57),
                    ],"""
)

text = text.replace(
"""                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],""",
"""                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],"""
)

text = text.replace(
"""                      Text(
                        'Poengplan for familien',
                        style: _travelSectionTitleStyle(context),
                      ),""",
"""                      Text(
                        'Poengplan for familien',
                        style: _travelSectionTitleStyle(context).copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F2230),
                        ),
                      ),"""
)

text = text.replace(
"""style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),""",
"""style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: const Color(0xFF0F2230),
                            ),"""
)

text = text.replace(
"""style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),""",
"""style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: const Color(0xFF0F2230),
                            ),"""
)

# 4) Gjør svak tekst i Poengplan mye tydeligere
text = text.replace(
"color: const Color(0xFF20353D),",
"color: const Color(0xFF1D3138),"
)

# 5) Gjør hjelpetekst under budsjett mer synlig
text = text.replace(
"color: const Color(0xFF4A5F67),",
"color: const Color(0xFF60747C),"
)

if text == orig:
    print("Ingen endringer gjort.")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Patched: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
