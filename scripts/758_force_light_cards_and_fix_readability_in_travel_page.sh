#!/usr/bin/env bash
set -euo pipefail

echo "==> 758_force_light_cards_and_fix_readability_in_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_758")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Gjør mørke hovedkort lyse
text = text.replace(
    """              Card(
                color: const Color(0xFF10252B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAS EuroBonus-saldo',""",
    """              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAS EuroBonus-saldo',"""
)

text = text.replace(
    """              Card(
                color: const Color(0xFF10252B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planlagt kjøp før reisen',""",
    """              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planlagt kjøp før reisen',"""
)

text = text.replace(
    """              Card(
                color: const Color(0xFF10252B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anbefalt pakkeliste',""",
    """              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anbefalt pakkeliste',"""
)

# 2) Gjør feed-kortene lyse i stedet for mørke
text = text.replace(
    "color: const Color(0xFF10252B),\n                                    borderRadius: BorderRadius.circular(16),",
    "color: Colors.white,\n                                    borderRadius: BorderRadius.circular(16),"
)

# 3) Mørkere og tydeligere tekst i feed-kort
text = text.replace(
    "color: const Color(0xFF243E46),",
    "color: const Color(0xFF10252B),"
)
text = text.replace(
    "color: const Color(0xFF233A41),",
    "color: const Color(0xFF243940),"
)

# 4) Fjern de altfor store fontSize: 22 der de ble satt på vanlig tekst
text = text.replace(
    "fontWeight: FontWeight.w900,\n      fontSize: 22,\n                                              color: _textDark,",
    "fontWeight: FontWeight.w800,\n                                              color: _textDark,"
)
text = text.replace(
    "fontWeight: FontWeight.w900,\n      fontSize: 22,\n                              color: const Color(0xFF183038),",
    "fontWeight: FontWeight.w800,\n                              color: const Color(0xFF183038),"
)

# 5) Gjør forklaringstekst mørkere i lyse kort
text = text.replace(
    """                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF233A41),
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),""",
    """                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF243940),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),"""
)

# 6) Gjør vanlig body-tekst i lyse kort mørk nok
text = text.replace(
    "style: Theme.of(context).textTheme.bodyMedium,",
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF10252B), fontWeight: FontWeight.w600),"
)

# 7) Gjør labelMedium/headlineSmall i planlagt kjøp mer lesbar
text = text.replace(
    "style: Theme.of(context).textTheme.labelMedium,",
    "style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF243940), fontWeight: FontWeight.w700),"
)
text = text.replace(
    """style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),""",
    """style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10252B),
                            ),"""
)

# 8) Gjør icon i feed-seksjonen mørkere og mer diskret
text = text.replace(
    "const Icon(Icons.travel_explore),",
    "const Icon(Icons.travel_explore, color: Color(0xFF0F6B73)),"
)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 758 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
