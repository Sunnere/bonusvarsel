#!/usr/bin/env bash
set -euo pipefail

echo "==> 815_wire_booking_ctas_and_smart_recommendation"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_815")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) url_launcher import
if "package:url_launcher/url_launcher.dart" not in text:
    flutter_import = "import 'package:flutter/material.dart';\n"
    replace_with = "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';\n"
    if flutter_import not in text:
        print("❌ Fant ikke Flutter-import")
        raise SystemExit(1)
    text = text.replace(flutter_import, replace_with, 1)
    print("✅ La inn url_launcher-import")

# 2) helper methods before _travelStoreCardsForUse
anchor = "  List<Map<String, dynamic>> _travelStoreCardsForUse() {"
if anchor not in text:
    print("❌ Fant ikke anker for helper-metoder")
    print("Kjør og send:")
    print("  grep -n \"_travelStoreCardsForUse\" lib/pages/travel_page.dart")
    raise SystemExit(1)

if "_primaryBookingUrl()" not in text:
    helper = r"""
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

  String _smartRecommendationLine() {
    final currentPoints =
        int.tryParse(_sasPointsCtrl.text.trim().replaceAll(' ', '')) ?? 0;
    final amount = _amount();
    final estPoints = _estimatePoints(amount);
    final projected = currentPoints + estPoints;

    switch (_selectedTravelUse) {
      case 'Fly':
        if (projected >= 177500) {
          return 'Smart anbefaling: Du nærmer deg nok poeng til å prioritere bonusfly først.';
        }
        if (_cardRatePer100 > 0) {
          return 'Smart anbefaling: Samle fly først, men bruk valgt kort til å bygge poeng videre før booking.';
        }
        return 'Smart anbefaling: Sjekk bonusfly først, og velg partner bare hvis tilgjengelighet eller verdi er bedre.';
      case 'Hotell':
        if (_cardRatePer100 > 0) {
          return 'Smart anbefaling: Sammenlign hotell med poeng mot kortbetaling. Hotell bør bare tas med poeng når nattverdien er sterk.';
        }
        return 'Smart anbefaling: Se hotell med poeng først, men betal med kort hvis poengverdien per natt er svak.';
      case 'Leiebil':
        return 'Smart anbefaling: Bruk poeng på Hertz når det gir høy verdi. Ellers bør leiebil gå på kort og poengene spares til fly.';
      default:
        return 'Smart anbefaling: Start med alternativet som gir høyest totalverdi for reisen.';
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
    text = text.replace(anchor, helper + anchor, 1)
    print("✅ La inn booking-helpere")

# 3) add smart recommendation line after partnerLine Text block
old_reco_anchor = """          Text(
            partnerLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2C4A53),
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
"""
new_reco_anchor = """          Text(
            partnerLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2C4A53),
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _smartRecommendationLine(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF163B44),
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
"""
if old_reco_anchor in text and "_smartRecommendationLine()" not in text[text.find(old_reco_anchor):text.find(old_reco_anchor)+500]:
    text = text.replace(old_reco_anchor, new_reco_anchor, 1)
    print("✅ La inn smart anbefaling i book-blokka")

# 4) wire primary CTA
old_primary = """              Container(
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
"""
new_primary = """              InkWell(
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
"""
if old_primary not in text:
    print("❌ Fant ikke primær CTA-blokk")
    print("Kjør og send:")
    print("  sed -n '500,640p' lib/pages/travel_page.dart")
    raise SystemExit(1)
text = text.replace(old_primary, new_primary, 1)
print("✅ Koblet primær CTA")

# 5) wire secondary CTA and fix duplicated color
old_secondary = """              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
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
"""
new_secondary = """              InkWell(
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
"""
if old_secondary not in text:
    print("❌ Fant ikke sekundær CTA-blokk")
    print("Kjør og send:")
    print("  sed -n '520,660p' lib/pages/travel_page.dart")
    raise SystemExit(1)
text = text.replace(old_secondary, new_secondary, 1)
print("✅ Koblet sekundær CTA og ryddet dobbel color")

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 815 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
