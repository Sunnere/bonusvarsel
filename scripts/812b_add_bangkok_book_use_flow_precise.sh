#!/usr/bin/env bash
set -euo pipefail

echo "==> 812b_add_bangkok_book_use_flow_precise"

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
bak = path.with_name(path.name + f".bak_{stamp}_812b")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

helper_anchor = "  Widget _buildTravelStoreModule(BuildContext context) {"
helper_block = r"""
  Widget _buildBangkokBookUseFlow(BuildContext context) {
    final theme = Theme.of(context);
    final destination = _destinationCtrl.text.trim().isEmpty
        ? 'Bangkok'
        : _destinationCtrl.text.trim();

    final isBangkok =
        destination.toLowerCase().contains('bangkok') ||
        destination.toLowerCase().contains('bkk') ||
        destination.toLowerCase().contains('thailand');

    final partyText = _children > 0
        ? '$_adults voksne og $_children barn'
        : '$_adults voksne';

    final stayText = '$_days dager';

    String flowTitle;
    String flowBody;
    String partnerLine;
    String primaryCta;
    String secondaryCta;

    switch (_selectedTravelUse) {
      case 'Fly':
        flowTitle = isBangkok
            ? 'Book flyreisen til $destination'
            : 'Book flyreisen smart';
        flowBody =
            'Start med fly for $partyText i $stayText. Sammenlign direkte, 1 stopp og partnerfly ut fra poengsaldo og totalverdi.';
        partnerLine = _selectedProgram == 'SAS EuroBonus'
            ? 'SAS først, deretter relevante partnere hvis tilgjengelighet eller poengbruk er bedre.'
            : 'Sammenlign SAS og relevante partnere før du bruker poeng.';
        primaryCta = 'Sjekk SAS-fly';
        secondaryCta = 'Se partnerlogikk';
        break;
      case 'Hotell':
        flowTitle = isBangkok
            ? 'Velg hotell i $destination'
            : 'Velg hotell smart';
        flowBody =
            'For $partyText i $stayText bør du sammenligne poengbruk mot kontantpris og hva som gir best verdi per natt.';
        partnerLine =
            'Bruk poeng bare når hotellverdien er god. Ellers betal med kort som gir best opptjening.';
        primaryCta = 'Se hotellvalg';
        secondaryCta = 'Sammenlign poeng vs kort';
        break;
      case 'Leiebil':
        flowTitle = isBangkok
            ? 'Planlegg leiebil rundt $destination'
            : 'Planlegg leiebil smart';
        flowBody =
            'For $partyText i $stayText bør du sammenligne fleksibilitet, pris og om poeng heller bør brukes på fly eller hotell.';
        partnerLine =
            'Bruk poeng der verdien er høyest, og la leiebil gå på kort hvis fleksibilitet og opptjening er bedre.';
        primaryCta = 'Se leiebilvalg';
        secondaryCta = 'Sammenlign med kortbruk';
        break;
      default:
        flowTitle = 'Planlegg bruk av poengene';
        flowBody =
            'Se hva som gir mest verdi først, og bygg videre med partnere og kortbruk.';
        partnerLine =
            'Sammenlign poengbruk og kortopptjening før du bestemmer deg.';
        primaryCta = 'Se valg';
        secondaryCta = 'Sammenlign partnere';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F9),
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
              _selectedProgram == 'SAS EuroBonus'
                  ? 'SAS EuroBonus + partnerlogikk'
                  : 'Partnerlogikk aktiv',
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
          const SizedBox(height: 10),
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
                  color: Colors.white,
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
        print("❌ Fant ikke _buildTravelStoreModule-ankeret")
        raise SystemExit(1)
    text = text.replace(helper_anchor, helper_block + helper_anchor, 1)
    print("✅ La inn _buildBangkokBookUseFlow()")

old_call = """              _buildTravelUseModule(context),
              const SizedBox(height: 14),
              _buildTravelStoreModule(context),
"""
new_call = """              _buildTravelUseModule(context),
              _buildBangkokBookUseFlow(context),
              _buildTravelStoreModule(context),
"""

if old_call not in text:
    print("❌ Fant ikke eksakt call-blokk")
    print("Kjør og send:")
    print("  sed -n '1438,1448p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_call, new_call, 1)
print("✅ La inn book/bruk-flyt mellom use og store")

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 812b ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
