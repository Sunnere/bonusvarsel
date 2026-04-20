#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_858.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

if "import 'package:flutter/foundation.dart';" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart';\n",
        1,
    )

marker = "class _BonusvarselDevHubPageState extends State<BonusvarselDevHubPage> {"
insert = marker + "\n  static const bool _devHubEnabled = bool.fromEnvironment('ENABLE_DEV_HUB', defaultValue: false);\n"

if "_devHubEnabled" not in text:
    if marker not in text:
        raise SystemExit("❌ Fant ikke state-klassen")
    text = text.replace(marker, insert, 1)

old = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
"""

new = """  @override
  Widget build(BuildContext context) {
    if (!_devHubEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dev Hub'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Dev Hub er deaktivert i denne byggen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
"""

if old not in text:
    raise SystemExit("❌ Fant ikke build()-starten")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Dev Hub skjules nå når ENABLE_DEV_HUB ikke er satt til true")
PY

flutter analyze
echo "✅ 858 ferdig"
