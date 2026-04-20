#!/usr/bin/env bash
set -euo pipefail

echo "==> 812_add_bangkok_book_use_flow_and_partner_logic"

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
bak = path.with_name(path.name + f".bak_{stamp}_812")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Sett inn helper-widget før _travelStoreCardsForUse
helper_anchor = "  List<Map<String, dynamic>> _travelStoreCardsForUse() {"
helper_block = r"""
  Widget _buildBangkokBookUseFlow(BuildContext context) {
    final theme = Theme.of(context);
    final destination = _destinationCtrl.text.trim().isEmpty
        ? 'Bangkok'
        : _destinationCtrl.text.trim();

    final partyText = _children > 0
        ? '$_adults voksne og $_children barn'
        : '$_adults voksne';

    final stayText = '$_days dager';
    final isBangkok =
        destination.toLowerCase().contains('bangkok') ||
        destination.toLowerCase().contains('bkk') ||
        destination.toLowerCase().contains('thailand');

    String flowTitle;
    String flowBody;
    String primaryCta;
    String secondaryCta;
    String partnerLine;

    switch (_selectedTravelUse) {
      case 'Fly':
        flowTitle = isBangkok
            ? 'Book flyreisen til $destination'
            : 'Book flyreisen smart';
        flowBody =
            'Start med fly for $partyText i $stayText. Vurder direkte eller 1 stopp ut fra poengsaldo, pris og hva som gir best totalverdi.';
        primaryCta = 'Sjekk SAS-flyvninger';
        secondaryCta = 'Se SkyTeam-partnere';
        partnerLine = _selectedProgram == 'SAS EuroBonus'
            ? 'Anbefalt logikk: SAS først, deretter SkyTeam-partnere hvis poeng eller tilgjengelighet er bedre.'
            : 'Anbefalt logikk: sammenlign SAS og relevante partnere før du bruker poeng.';
        break;
      case 'Hotell':
        flowTitle = isBangkok
            ? 'Velg hotellopphold i $destination'
            : 'Velg hotellopphold smart';
        flowBody =
            'For $partyText i $stayText bør du sammenligne poengbruk mot kontantpris. Hotell gir ofte best verdi når du kombinerer opphold med god kortopptjening.';
        primaryCta = 'Se hotellvalg';
        secondaryCta = 'Vurder kortbetaling';
        partnerLine =
            'Anbefalt logikk: bruk poeng bare når verdi per natt er god, ellers betal med beste kort for opptjening.';
        break;
      case 'Leiebil':
        flowTitle = isBangkok
            ? 'Planlegg leiebil rundt $destination'
            : 'Planlegg leiebil smart';
        flowBody =
            'For $partyText i $stayText er det ofte smartest å sammenligne leiebilpris, fleksibilitet og om poeng bør brukes på fly i stedet.';
        primaryCta = 'Se leiebilvalg';
        secondaryCta = 'Sammenlign med kortbetaling';
        partnerLine =
            'Anbefalt logikk: bruk poeng der verdien er høyest, og la leiebil gå på kort dersom opptjening og fleksibilitet er bedre.';
        break;
      default:
        flowTitle = 'Planlegg bruk av poengene';
        flowBody =
            'Start med det som gir størst verdi for reisen, og bygg videre med partnere og kortbruk.';
        primaryCta = 'Se alternativer';
        secondaryCta = 'Sammenlign partnere';
        partnerLine = 'Sammenlign poengbruk og kortopptjening før du bestemmer deg.';
        break;
    }

    final badgeText = _selectedProgram == 'SAS EuroBonus'
        ? 'SAS EuroBonus + partnerlogikk'
        : 'Partnerlogikk aktiv';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E1E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flowTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF162E35),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF0F3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFB9D8DE)),
            ),
            child: Text(
              badgeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF23444C),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            flowBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF486169),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            partnerLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2C4A53),
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
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
        ],
      ),
    );
  }

"""
if "_buildBangkokBookUseFlow(BuildContext context)" not in text:
    if helper_anchor not in text:
        print("❌ Fant ikke anker for helper-metode.")
        print("Kjør og send:")
        print("  grep -n \"_travelStoreCardsForUse\" lib/pages/travel_page.dart")
        raise SystemExit(1)
    text = text.replace(helper_anchor, helper_block + helper_anchor, 1)
    print("✅ La inn _buildBangkokBookUseFlow()")

# 2) Kall modulen mellom use-module og store-module
old_call = """              _buildTravelUseModule(context),
              _buildTravelStoreModule(context),
"""
new_call = """              _buildTravelUseModule(context),
              _buildBangkokBookUseFlow(context),
              _buildTravelStoreModule(context),
"""
if old_call not in text:
    print("❌ Fant ikke eksakt plassering for use/store-modulene.")
    print("Kjør og send:")
    print("  grep -n \"_buildTravelUseModule\\|_buildTravelStoreModule\" lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_call, new_call, 1)
print("✅ La inn Book/bruk-flyt mellom use og store")

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 812 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
