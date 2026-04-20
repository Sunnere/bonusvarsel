#!/usr/bin/env bash
set -euo pipefail

echo "==> 817_make_store_cards_clickable_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_817")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) url_launcher import hvis den mangler
if "import 'package:url_launcher/url_launcher.dart';" not in text:
    needle = "import 'package:flutter/material.dart';\n"
    repl = "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';\n"
    if needle not in text:
        print("❌ Fant ikke flutter-import")
        raise SystemExit(1)
    text = text.replace(needle, repl, 1)
    print("✅ La inn url_launcher import")

# 2) booking helper-metoder hvis de mangler, legg også inn store helper
anchor = "  List<Map<String, dynamic>> _travelStoreCardsForUse() {"

if "_openExternalBookingUrl(" not in text:
    helpers = """
  Future<void> _openExternalBookingUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke åpne lenken akkurat nå.'),
        ),
      );
    }
  }

"""
    if anchor not in text:
        print("❌ Fant ikke anker for helper-metoder")
        raise SystemExit(1)
    text = text.replace(anchor, helpers + anchor, 1)
    print("✅ La inn _openExternalBookingUrl()")

if "_storeCardUrlForCurrentUse()" not in text:
    store_helper = """
  String _storeCardUrlForCurrentUse() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return 'https://www.sas.no/eurobonus/partnere/';
      case 'Hotell':
        return 'https://www.sas.no/eurobonus/hotels/';
      case 'Leiebil':
        return 'https://www.sas.no/eurobonus/partnere/bakketransport/hertz';
      default:
        return 'https://www.sas.no/eurobonus/';
    }
  }

"""
    if anchor not in text:
        print("❌ Fant ikke anker for _storeCardUrlForCurrentUse")
        raise SystemExit(1)
    text = text.replace(anchor, store_helper + anchor, 1)
    print("✅ La inn _storeCardUrlForCurrentUse()")

# 3) Rydd evt. opp i dobbel subtitle
text = text.replace(
    "                Text(\n                  subtitle,\n                  subtitle,\n",
    "                Text(\n                  subtitle,\n",
)

# 4) Gjør hele butikk-kortet klikkbart
old_block = """    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF9FCFC),
            Color(0xFFF1F8F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD5E4E7),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
"""

new_block = """    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openExternalBookingUrl(_storeCardUrlForCurrentUse()),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF9FCFC),
              Color(0xFFF1F8F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD5E4E7),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
"""

if old_block not in text:
    print("❌ Fant ikke starten på _travelStoreCard-blokken")
    print("Kjør og send:")
    print("  sed -n '700,830p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_block, new_block, 1)

# 5) Lukk InkWell riktig på slutten av _travelStoreCard
old_tail = """          ),
        ],
      ),
    );
  }
"""

new_tail = """          ),
        ],
      ),
    ),
    );
  }
"""

if old_tail not in text:
    print("❌ Fant ikke slutten på _travelStoreCard-blokken")
    print("Kjør og send:")
    print("  sed -n '830,900p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_tail, new_tail, 1)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 817 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
