#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781_4.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

old_score = """              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),"""

new_score = """              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),"""

if old_score not in text:
    raise SystemExit("❌ Fant ikke label-blokken i _scoreMeter()")

text = text.replace(old_score, new_score, 1)

old_momentum = """    final momentum = int.tryParse('${evaluation['momentum'] ?? 0}') ?? 0;

    if (cooldown > 0) {
      return (label: 'BLOCKED BY COOLDOWN', color: Colors.red);
    }

    if (shouldNotify || timing == 'buy_now' || momentum >= 25) {
      return (label: 'STRONG SIGNAL', color: Colors.green);
    }
"""

new_momentum = """    final momentumRaw = '${evaluation['momentum'] ?? ''}'.toLowerCase();
    final momentum = momentumRaw == 'high'
        ? 30
        : momentumRaw == 'medium'
            ? 20
            : momentumRaw == 'low'
                ? 10
                : (int.tryParse('${evaluation['momentum'] ?? 0}') ?? 0);

    if (cooldown > 0) {
      return (label: 'BLOCKED BY COOLDOWN', color: Colors.red);
    }

    if (shouldNotify || timing == 'buy_now' || momentum >= 25) {
      return (label: 'STRONG SIGNAL', color: Colors.green);
    }
"""

if old_momentum not in text:
    raise SystemExit("❌ Fant ikke momentum-blokken i _alertSummary()")

text = text.replace(old_momentum, new_momentum, 1)

p.write_text(text)
print("✅ Fikset _scoreMeter-kontrast og momentum-logikk i _alertSummary()")
PY

flutter analyze
echo "✅ 781.4 ferdig"
