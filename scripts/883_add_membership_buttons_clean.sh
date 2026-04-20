#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

cp "$FILE" "$FILE.bak_883.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()

# legg til url_launcher import hvis mangler
if "url_launcher" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';"
    )

# legg til widget funksjon
if "_membershipButtons(" not in text:
    insert = """

  Widget _membershipButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse('https://www.sas.no/register/eurobonus')),
            child: const Text('SAS EuroBonus'),
          ),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse('https://www.trumf.no/bli-medlem')),
            child: const Text('Trumf'),
          ),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse('https://www.skyteam.com/en/frequent-flyers/programs')),
            child: const Text('SkyTeam'),
          ),
        ],
      ),
    );
  }
"""
    text = text.replace("class _EbShoppingPageState", insert + "\nclass _EbShoppingPageState")

# plasser under filter
text = text.replace(
    "_buildSourceFilter(context),",
    "_buildSourceFilter(context),\n_membershipButtons(),"
)

p.write_text(text)
print("✅ Medlemsknapper lagt inn")
PY

flutter analyze
echo "✅ 883 ferdig"
