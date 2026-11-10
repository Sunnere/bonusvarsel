import 'package:flutter/material.dart';

/// Felles info om programmer i Bonusvarsel. Brukes i Varsler-fanen,
/// på Poeng-forsiden og i onboarding, slik at teksten alltid er lik.
const String programsInfoTitle = '💸 Spenn og flere programmer';

const String programsInfoText =
    '✅ Du kan følge nå\n'
    '• Trumf Netthandel – ekstra bonus i favorittbutikkene dine\n'
    '• SAS Online Shopping – ekstra EuroBonus-poeng\n'
    '• Spenn – Superspenn-dager og ekstra Spenn hos REMA 1000, Norwegian m.fl.\n'
    '• Avios og Amex MR – overføringsbonus og kampanjer (Premium)\n\n'
    '💸 Slik får du Spenn-varsler\n'
    '1. Gå til Varsler-fanen og slå på «Spenn-kampanjer»\n'
    '2. Legg inn e-post eller koble til Telegram\n'
    '3. Legg gjerne inn Spenn-saldoen din under Reis\n\n'
    '🔜 Kommer snart\n'
    '• Flying Blue (Air France-KLM)\n'
    '• Miles & More (Lufthansa m.fl.)';

const String aviosInfoTitle = '🛩️ Avios og Amex MR';

const String aviosInfoText =
    'Avios er poengene i British Airways Club (brukes også hos Iberia, Finnair m.fl.). '
    'Avios kan ikke overføres til EuroBonus.\n\n'
    'Amex Membership Rewards (MR) er poeng fra enkelte Amex-kort. '
    'SAS EuroBonus-kortene fra Amex gir EuroBonus direkte. '
    'MR kan i noen tilfeller overføres til Avios og andre programmer, men forhold og kampanjer varierer. '
    'Sjekk alltid gjeldende vilkår hos Amex.\n\n'
    'Slik bruker du det i appen:\n'
    '1. Reis-fanen → Flere programmer → slå på Avios og/eller Amex MR og skriv inn saldoen\n'
    '2. Varsler-fanen → slå på Avios- og MR-varsler (Premium) for å få beskjed om overføringsbonus\n'
    '3. Spør Flying Agent (✈️ i AI-chatten) om flyreiser på Avios.';

Widget _programsStep(String num, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(right: 8, top: 1),
          decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(999)),
          child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white))),
        ),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4))),
      ]),
    );

void showProgramsInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0B1728),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFFFDBA74)),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Programmer i Bonusvarsel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            const Text('✅ Du kan følge nå',
                style: TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
                '• Trumf Netthandel – ekstra bonus i favorittbutikkene dine\n'
                '• SAS Online Shopping – ekstra EuroBonus-poeng\n'
                '• Spenn – Superspenn-dager og ekstra Spenn hos REMA 1000, Norwegian m.fl.\n'
                '• Avios og Amex MR – overføringsbonus og kampanjer (Premium)',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.5)),
            const SizedBox(height: 16),
            const Text('💸 Slik får du Spenn-varsler',
                style: TextStyle(
                    color: Color(0xFFFDBA74),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            _programsStep('1', 'Gå til Varsler-fanen og slå på «Spenn-kampanjer»'),
            _programsStep('2', 'Legg inn e-post eller koble til Telegram'),
            _programsStep('3', 'Legg gjerne inn Spenn-saldoen din under Reis'),
            const SizedBox(height: 16),
            const Text('🔜 Kommer snart',
                style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
                '• Flying Blue (Air France-KLM)\n'
                '• Miles & More (Lufthansa m.fl.)',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.5)),
          ],
        ),
      ),
    ),
  );
}

const String eurobonusInfoTitle = '✈️ Slik tjener du EuroBonus';
const String eurobonusInfoText =
    'I nettbutikk:\n'
    '• SAS Online Shopping: du handler via lenken og får EuroBonus-poeng direkte.\n'
    '• Trumf Netthandel: du får Trumf-bonus (opptil 10 %), som du kan overføre til EuroBonus.\n\n'
    'I butikk (KIWI, MENY, SPAR, Joker, Nærbutikken):\n'
    '• Registrer bankkortet i Trumf-appen og få 1 % bonus, eller vis QR-koden og få 2 %.\n'
    '• Automatisk overføring til EuroBonus gir 13,5 poeng per krone Trumf-bonus (engangsoverføring gir 10).\n\n'
    'Butikkene finner du under Varsler-fanen. Regn ut hva det blir på Spar-fanen.';

const String comingInfoTitle = '🔜 Kommer snart';
const String comingInfoText =
    'Flying Blue og Miles & More kommer i en senere oppdatering.\n\n'
    'Du kan allerede følge Spenn, Avios og Amex Membership Rewards i appen.';
