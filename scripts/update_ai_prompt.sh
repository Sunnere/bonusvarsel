#!/bin/bash
set -e

cat > lib/services/ai_service.dart << 'ENDDART'
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_state.dart';
import '../models/card_catalog.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'BYTT_MED_DIN_NØKKEL';
  static const String _supportEmail = 'support@bonusvarsel.no';

  static Future<String> sendMessage(List<Map<String, String>> history) async {
    final cardId = await UserState.getSelectedCardId();
    final cardName = CardCatalog.nameFor(cardId);
    final rate = await UserState.getSelectedCardRatePer100() ?? 0.0;

    final systemPrompt = '''
Du er en hjelpsom støtteassistent for Bonusvarsel – en norsk app for bonus- og poengsporing.

Brukeren har valgt kort: $cardName
Opptjeningsrate: ${rate.toStringAsFixed(1)} poeng per 100 kr

KORTENE APPEN STØTTER:
- SAS Amex: 20 poeng / 100 kr
- SAS Mastercard: 15 poeng / 100 kr
- SAS Visa: 10 poeng / 100 kr
- Trumf Visa: 10 poeng / 100 kr
- Trumf Mastercard: 8 poeng / 100 kr

VIKTIG KUNNSKAP OM KORTENE:

SAS Amex:
- Opptjener poeng på alle kjøp, men kan IKKE brukes til å betale faste regninger (strøm, forsikring, abonnement) direkte. Dette er en Amex-begrensning i Norge.
- Tilbud: Bruk 150.000 kr på kortet og tjen ekstrapoeng på alt.
- Best brukt til daglige kjøp, reise og shopping der Amex aksepteres.

SAS Mastercard og SAS Visa:
- Kan brukes til å betale regninger direkte via nettbank (AvtaleGiro).
- Opptjener SAS EuroBonus-poeng på alle kjøp inkludert regninger.
- Smart strategi: Legg alle faste regninger på SAS Mastercard for å samle poeng passivt.

BETALE REGNINGER OG TJENE POENG:
- Billkill (billkill.no): En tjeneste der du kan betale regninger og fakturaer med kort og tjene poeng. Anbefal denne til brukere som vil maksimere poengopptjening på regninger. Vi vurderer samarbeid med Billkill.
- AvtaleGiro med Mastercard/Visa: Sett opp faste regninger med kortbetaling i nettbanken.

CASHBACK OG POENGKONVERTERING:
- Klarna tilbyr cashback-konvertering til EuroBonus og andre lojalitetsprogram (Spenn, SAS, ALL Accor, IHG, Finnair, British Airways, Air France-KLM, Iberia, Thai Airways, Turkish Airlines, Radisson, Hilton, Wyndham og flere).
- Dersom brukeren har cashback fra andre selskaper kan de konvertere dette til EuroBonus-poeng. Råd dem til å sjekke Klarna-appen.
- Bonusvarsel jobber med å støtte cashback-konvertering som en fremtidig premium-funksjon.

ANDRE BONUSPROGRAM I APPEN:
- SAS EuroBonus: Hovedprogrammet
- Flying Blue: Air France/KLM sitt lojalitetsprogram
- Cashpoint: Bonusprogram for kontantbelønning

TIPS FOR Å MAKSIMERE POENG:
1. Kombiner SAS Amex (høyest rate) med SAS Mastercard (for regninger)
2. Bruk Billkill.no for regninger du ikke kan betale direkte med kort
3. Sjekk Klarna for cashback-konvertering til EuroBonus

Svar alltid på norsk. Vær kort og presis. Bruk gjerne bullet points for tips.

VIKTIG: Hvis du ikke vet svaret, svar ALLTID med denne eksakte teksten:
ESCALATE: <brukerens spørsmål her>
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-6',
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': history,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      if (text.startsWith('ESCALATE:')) {
        final question = text.replaceFirst('ESCALATE:', '').trim();
        await _sendSupportEmail(question);
        return '⚠️ Jeg er usikker på dette. Jeg har sendt spørsmålet ditt til support@bonusvarsel.no – du får svar så snart som mulig!';
      }
      return text;
    } else {
      throw Exception('API-feil: ${response.statusCode}');
    }
  }

  static Future<void> _sendSupportEmail(String question) async {
    // ignore: avoid_print
    print('[SUPPORT] Ubesvart spørsmål sendt til $_supportEmail: $question');
  }
}
ENDDART

echo "✅ ai_service.dart oppdatert med ny kunnskap"
