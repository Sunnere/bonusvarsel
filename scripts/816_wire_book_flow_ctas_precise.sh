#!/usr/bin/env bash
set -euo pipefail

echo "==> 816_wire_book_flow_ctas_precise"

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
bak = path.with_name(path.name + f".bak_{stamp}_816")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) url_launcher import
if "import 'package:url_launcher/url_launcher.dart';" not in text:
    needle = "import 'package:flutter/material.dart';\n"
    repl = "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';\n"
    if needle not in text:
        print("❌ Fant ikke flutter-importen")
        raise SystemExit(1)
    text = text.replace(needle, repl, 1)
    print("✅ La inn url_launcher import")

# 2) helper-metoder
anchor = "  List<Map<String, dynamic>> _travelStoreCardsForUse() {"
if "_primaryBookingUrl()" not in text:
    helpers = """
  String _primaryBookingUrl() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return 'https://www.sas.no/eurobonus/offers-and-news/award-tickets/';
      case 'Hotell':
        return 'https://www.sas.no/eurobonus/hotels/';
      case 'Leiebil':
        return 'https://www.sas.no/eurobonus/partnere/bakketransport/hertz';
      default:
        return 'https://www.sas.no/eurobonus';
    }
  }

  String _secondaryBookingUrl() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return 'https://www.sas.no/eurobonus/partnere';
      case 'Hotell':
        return 'https://www.sas.no/eurobonus/partnere/hoteller';
      case 'Leiebil':
        return 'https://www.sas.no/reservere/bilutleie/';
      default:
        return 'https://www.sas.no/eurobonus/partnere';
    }
  }

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
    print("✅ La inn booking-helperne")

# 3) bytt CTA-blokka
old = """          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3A4A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  primaryCta,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD4E1E5)),
                ),
                child: Text(
                  secondaryCta,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF162E35),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
"""

new = """          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openExternalBookingUrl(_primaryBookingUrl()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3A4A),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    primaryCta,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openExternalBookingUrl(_secondaryBookingUrl()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD4E1E5)),
                  ),
                  child: Text(
                    secondaryCta,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF162E35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
"""

if old not in text:
    print("❌ Fant ikke eksakt CTA-blokk")
    print("Kjør og send:")
    print("  sed -n '520,610p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)
print("✅ Koblet CTA-knappene")

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 816 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
