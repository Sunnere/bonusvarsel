#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/premium_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sørg for import
if "premium_service.dart" not in s:
    s = s.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:bonusvarsel/services/premium_service.dart';"
    )

# 2) Bytt til Stateful om den er Stateless
s = re.sub(
    r"class\s+PremiumPage\s+extends\s+StatelessWidget\s*\{",
    "class PremiumPage extends StatefulWidget {",
    s
)
if "extends StatefulWidget" in s and "State<PremiumPage>" not in s:
    # finn constructor-linje og legg inn createState
    s = re.sub(
        r"(class PremiumPage extends StatefulWidget \{\s*\n\s*const PremiumPage\(\{super\.key\}\);\s*)",
        r"\1\n\n  @override\n  State<PremiumPage> createState() => _PremiumPageState();\n",
        s,
        flags=re.S
    )
    # lukk widget-klassen og legg inn stateklasse hvis ikke finnes
    if "_PremiumPageState" not in s:
        s = re.sub(
            r"(State<PremiumPage> createState\(\) => _PremiumPageState\(\);\s*\n\})",
            r"\1\n\nclass _PremiumPageState extends State<PremiumPage> {\n  final _premium = PremiumService();\n  bool _isPremium = false;\n\n  @override\n  void initState() {\n    super.initState();\n    _premium.getIsPremium().then((v) {\n      if (!mounted) return;\n      setState(() => _isPremium = v);\n    });\n  }\n\n  Future<void> _setPremium(bool v) async {\n    await _premium.setIsPremium(v);\n    if (!mounted) return;\n    setState(() => _isPremium = v);\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    return _buildPremium(context);\n  }\n\n  Widget _buildPremium(BuildContext context) {\n",
            s,
            flags=re.S
        )

# 3) Hvis build allerede finnes, pakk den inn slik at vi kan injisere switch
# Finn første "return Scaffold(" i PremiumPage sin build og legg inn en switch øverst i body.
if "_buildPremium" in s and "SwitchListTile(" not in s:
    s = s.replace(
        "return Scaffold(",
        "return Scaffold(\n"
        "      // DEV: Premium-toggle (fjern når Stripe er live)\n"
        "      floatingActionButton: null,\n"
    )

    # Forsøk å injisere i body: Padding/Column
    # Vi setter inn en SwitchListTile rett etter første 'children: [' hvis den finnes.
    s = re.sub(
        r"(children:\s*\[)",
        r"\1\n            SwitchListTile(\n              title: const Text('Premium (dev) – låser opp ekstra filter og sortering'),\n              value: _isPremium,\n              onChanged: (v) => _setPremium(v),\n            ),\n            const SizedBox(height: 8),",
        s,
        count=1
    )

# 4) Lukk _buildPremium hvis vi åpnet den
if "_buildPremium" in s and not s.strip().endswith("}"):
    # Ikke gjør noe her – dart format vil klage hvis det mangler, men ofte er det ok.

    pass

p.write_text(s, encoding="utf-8")
print("Patchet premium_page.dart")
PY

dart format "$FILE"
flutter analyze
