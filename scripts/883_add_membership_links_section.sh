#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_883.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

if "package:url_launcher/url_launcher.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';\n",
        1,
    )

if "_openExternalLink(" not in text:
    marker = "class _EbShoppingPageState extends State<EbShoppingPage> {"
    insert = marker + """

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne lenken')),
      );
    }
  }

  Widget _buildMembershipLinksCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kom i gang',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bli medlem og få mer ut av poeng, bonus og allianser.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openExternalLink('https://www.sas.no/register/eurobonus'),
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Bli medlem i EuroBonus'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openExternalLink('https://www.trumf.no/bli-medlem'),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Bli medlem i Trumf'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openExternalLink('https://www.skyteam.com/en/frequent-flyers/programs'),
                icon: const Icon(Icons.public),
                label: const Text('Se SkyTeam-programmer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
"""
    if marker not in text:
        raise SystemExit("❌ Fant ikke state-klassen i eb_shopping_page.dart")
    text = text.replace(marker, insert, 1)

old = """          const SizedBox(height: 12),
        _buildSourceFilter(context),

          Expanded(
"""
new = """          const SizedBox(height: 12),
        _buildSourceFilter(context),
          _buildMembershipLinksCard(context),

          Expanded(
"""
if old not in text:
    raise SystemExit("❌ Fant ikke stedet etter source-filteret")
text = text.replace(old, new, 1)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn medlemslenker under filterseksjonen")
PY

flutter analyze
echo "✅ 883 ferdig"
