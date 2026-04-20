#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_903.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# 1) Skjul programseksjonene helt foreløpig
old_section = """Widget _buildProgramCards(BuildContext context) {
"""
if old_section in text:
    start = text.find(old_section)
    # finn slutten på _buildCardSection() ved å lete etter neste dobbeltlinjeskift + Widget/void/class
    marker = "\n  // --- ELITE_V2_SECTION ---"
    alt_marker = "\n@override\n  Widget build(BuildContext context) {"
    end = text.find(marker, start)
    if end == -1:
        end = text.find(alt_marker, start)
    if end != -1:
        replacement = """Widget _buildProgramCards(BuildContext context) {
  return const SizedBox.shrink();
}

"""
        text = text[:start] + replacement + text[end:]
    else:
        raise SystemExit("❌ Fant ikke slutten på _buildProgramCards/_buildCardSection-blokken")

# 2) Fjern visning i body hvis den ligger der
text = text.replace(
"""_buildProgramCards(context),
          const SizedBox(height: 8),

          Expanded(
""",
"""Expanded(
""",
1)

# 3) Krymp hero-boksen tydelig
text = text.replace(
    "padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),",
    "padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),"
)
text = text.replace(
    "padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),",
    "padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),"
)
text = text.replace(
    "borderRadius: BorderRadius.circular(14),",
    "borderRadius: BorderRadius.circular(12),"
)
text = text.replace(
    "constraints: const BoxConstraints(maxWidth: 760),",
    "constraints: const BoxConstraints(maxWidth: 760, minHeight: 0),"
)

# 4) Tighter spacing i hero
text = text.replace("const SizedBox(height: 8),", "const SizedBox(height: 6),")
text = text.replace("const SizedBox(height: 6),", "const SizedBox(height: 4),")

# 5) Litt mindre hero-tekst
text = text.replace(
"""                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.2,
                      ),
""",
"""                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.1,
                      ),
""",
1)

# 6) Gjør CTA-knapper mindre visuelt
text = text.replace(
"""                    OutlinedButton.icon(
                      onPressed: () => _showFreeVsPremium(context),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Se gratis'),
                    ),
""",
"""                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _showFreeVsPremium(context),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Gratis'),
                    ),
""",
1)

text = text.replace(
"""                    OutlinedButton.icon(
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Se Premium'),
                    ),
""",
"""                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                      label: const Text('Premium'),
                    ),
""",
1)

text = text.replace(
"""                    OutlinedButton.icon(
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Se Elite'),
                    ),
""",
"""                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('Elite'),
                    ),
""",
1)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Krympet hero og skjulte SAS/Trumf-seksjoner")
PY

flutter analyze
echo "✅ 903 ferdig"
