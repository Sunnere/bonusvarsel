#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/ad_slot.dart"

if [ ! -f "$FILE" ]; then
  echo "Fant ikke $FILE"
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${FILE}.bak.${STAMP}"
cp "$FILE" "$BACKUP"
echo "Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/widgets/ad_slot.dart")
src = path.read_text(encoding="utf-8")
original = src

def must_replace(pattern, repl, text, flags=re.MULTILINE | re.DOTALL, desc=""):
    new_text, count = re.subn(pattern, repl, text, count=1, flags=flags)
    if count == 0:
        print(f"ADVARSEL: fant ikke mønster for: {desc or pattern[:80]}")
        return text, False
    print(f"OK: {desc or pattern[:80]}")
    return new_text, True

# 1) Legg inn hjelpefunksjoner i _AdSlotCardState før @override
helpers = r"""
  bool get _isPremiumPlacement {
    final p = widget.placement.toLowerCase();
    return p.contains('premium') || p.contains('elite');
  }

  String _normalizedTitle(String input) {
    final raw = input.trim();
    if (!_isPremiumPlacement) return raw;
    final lower = raw.toLowerCase();

    if (lower.contains('amex') and ('høy poeng' in lower or raw.endswith('...'))) {
      return 'American Express Platinum';
    }
    if (lower == 'amex' or lower == 'american express') {
      return 'American Express Platinum';
    }
    return raw;
  }

  String _normalizedBody(String input) {
    final raw = input.trim();
    if (!_isPremiumPlacement) return raw;
    final lower = raw.toLowerCase();

    if (
      lower.contains('bruk amex på hverdagskjøp') or
      lower.contains('bygg poeng raskere') or
      lower.contains('relevant kort eller tilbud')
    ) {
      return 'Bruk kortet på hverdagskjøp og bygg poeng raskere.';
    }
    return raw;
  }

  String _normalizedCta(String input) {
    final raw = input.trim();
    if (!_isPremiumPlacement) return raw;
    if (raw.isEmpty || raw.toLowerCase() == 'se tilbud') {
      return 'Se kort & fordeler';
    }
    return raw;
  }

  String get _disclaimerText {
    if (!_isPremiumPlacement) return '';
    return 'Eksempelplassering – ikke et aktivt partnerskap';
  }

  TextStyle _premiumDisclaimerStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: Colors.white.withOpacity(0.72),
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          fontSize: 11,
          color: Colors.white.withOpacity(0.72),
          fontWeight: FontWeight.w500,
        );
  }

"""
src, _ = must_replace(
    r"(class _AdSlotCardState extends State<AdSlotCard>\s*\{\s*bool _counted = false;\s*)",
    r"\1" + helpers + "\n",
    src,
    desc="sett inn premium helper-metoder",
)

# 2) Legg inn normaliserte lokale variabler i build()
build_injection = r"""
  @override
  Widget build(BuildContext context) {
    final title = _normalizedTitle(widget.slot.title);
    final body = _normalizedBody(
      (widget.slot.description).trim().isEmpty
          ? widget.slot.title
          : widget.slot.description,
    );
    final ctaLabel = _normalizedCta(
      ((widget.slot.ctaText ?? '').trim().isEmpty)
          ? 'Se tilbud'
          : widget.slot.ctaText!,
    );
"""
src, _ = must_replace(
    r"@override\s+Widget build\(BuildContext context\)\s*\{",
    build_injection,
    src,
    desc="legg inn premium lokale variabler i build",
)

# 3) Bytt ut direkte title/description/cta-bruk med normaliserte variabler
replacements = [
    (r"\bwidget\.slot\.title\b", "title", "erstatt widget.slot.title"),
    (r"\bwidget\.slot\.description\b", "body", "erstatt widget.slot.description"),
    (r"\bwidget\.slot\.ctaText\b", "ctaLabel", "erstatt widget.slot.ctaText"),
]

for pattern, repl, desc in replacements:
    src, count = re.subn(pattern, repl, src)
    print(f"{desc}: {count}")

# 4) Gjør badge mer diskret hvis filen bruker Chip med teksten Annonse
src, count = re.subn(
    r"Chip\s*\(\s*label:\s*Text\(\s*'Annonse'([^)]*)\)\s*,",
    r"Chip(label: Text('Annonse'\1), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),",
    src,
    count=1,
    flags=re.MULTILINE | re.DOTALL,
)
print(f"badge-oppstramming: {count}")

# 5) Legg inn disclaimer under premium/elite-annonsen dersom vi finner CTA-knappen
# Forsøker å hekte på etter første forekomst av ElevatedButton/TextButton/OutlinedButton i build-treet.
button_patterns = [
    (
        r"(\bElevatedButton(?:\.icon)?\s*\([^;]*?\)\s*,?)",
        r"""\1
                          if (_disclaimerText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _disclaimerText,
                              style: _premiumDisclaimerStyle(context),
                            ),
                          ],""",
        "legg disclaimer etter ElevatedButton",
    ),
    (
        r"(\bTextButton(?:\.icon)?\s*\([^;]*?\)\s*,?)",
        r"""\1
                          if (_disclaimerText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _disclaimerText,
                              style: _premiumDisclaimerStyle(context),
                            ),
                          ],""",
        "legg disclaimer etter TextButton",
    ),
    (
        r"(\bOutlinedButton(?:\.icon)?\s*\([^;]*?\)\s*,?)",
        r"""\1
                          if (_disclaimerText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _disclaimerText,
                              style: _premiumDisclaimerStyle(context),
                            ),
                          ],""",
        "legg disclaimer etter OutlinedButton",
    ),
]

inserted = False
for pattern, repl, desc in button_patterns:
    new_src, count = re.subn(pattern, repl, src, count=1, flags=re.MULTILINE | re.DOTALL)
    if count:
        src = new_src
        inserted = True
        print(f"OK: {desc}")
        break

if not inserted:
    print("ADVARSEL: fant ikke knappemønster for disclaimer. Hopper over disclaimer-injeksjon.")

# 6) Sikre import av material.dart fortsatt finnes
if "import 'package:flutter/material.dart';" not in src:
    print("FEIL: flutter material import mangler etter patch")
    sys.exit(1)

if src == original:
    print("Ingen endringer ble gjort.")
    sys.exit(1)

path.write_text(src, encoding="utf-8")
print("Patch skrevet til fil.")
PY

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
