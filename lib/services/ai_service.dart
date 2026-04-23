import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_state.dart';
import '../models/card_catalog.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'REMOVED_API_KEY';
  static const String _supportEmail = 'support@bonusvarsel.no';
  static const String _historyKey = 'ai_chat_history';
  static const int _maxHistoryMessages = 20;

  // Lagre chathistorikk lokalt
  static Future<void> saveHistory(List<Map<String, String>> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history);
    await prefs.setString(_historyKey, encoded);
  }

  // Hent lagret chathistorikk
  static Future<List<Map<String, String>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  // Slett historikk
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<String> sendMessage(
    List<Map<String, String>> history,
    String plan,
  ) async {
    final cardId = await UserState.getSelectedCardId();
    final cardName = CardCatalog.nameFor(cardId);
    final rate = await UserState.getSelectedCardRatePer100() ?? 0.0;

    // Hent alle kort brukeren har registrert
    final prefs = await SharedPreferences.getInstance();
    final allCards = prefs.getStringList('user_cards') ?? [cardId ?? 'ingen'];
    final cardList = allCards.map((id) => CardCatalog.nameFor(id)).join(', ');

    final isPremium = plan == 'pro' || plan == 'elite';
    final isElite = plan == 'elite';

    final premiumUpsell = isPremium ? '' : '''
VIKTIG – GRATIS BRUKER:
Brukeren er på gratisplanen. Når de spør om avanserte funksjoner som:
- Personlige varsler og tilbud
- Favorittbutikker og -kategorier
- Detaljerte poengrapporter
- Eksklusive partnertilbud
- Automatisk kortanbefaling per kjøp
...skal du alltid nevne at dette er tilgjengelig i Premium (Pro) eller Elite.

Eksempel: "Dette er en Premium-funksjon – oppgrader i appen for å få personlige varsler og mye mer! 🚀"
''';

    final eliteFeatures = isElite ? '''
Brukeren er Elite-medlem og har tilgang til:
- Alle Premium-funksjoner
- Eksklusiv concierge-support
- Tidlig tilgang til nye funksjoner
- Dedikerte partneravtaler
- Avansert poengoptimalisering på tvers av alle program
''' : '';

    final systemPrompt = '''
Du er en hjelpsom støtteassistent for Bonusvarsel – en norsk app for bonus- og poengsporing.

BRUKERENS PROFIL:
- Valgt hovedkort: $cardName (${rate.toStringAsFixed(1)} poeng / 100 kr)
- Alle registrerte kort: $cardList
- Abonnementsplan: $plan

KORTENE APPEN STØTTER:
- SAS Amex: 20 poeng / 100 kr – beste rate, men aksepteres ikke overalt og kan IKKE betale regninger direkte
- SAS Mastercard: 15 poeng / 100 kr – kan betale regninger via AvtaleGiro
- SAS Visa: 10 poeng / 100 kr – kan betale regninger via AvtaleGiro
- Trumf Visa: 10 poeng / 100 kr + ekstra Trumf-poeng hos NorgesGruppen (Meny, Kiwi, Spar, Joker)
- Trumf Mastercard: 8 poeng / 100 kr + ekstra Trumf-poeng hos NorgesGruppen

SMART KOMBINASJONSSTRATEGI:
- Bruk SAS Amex til alt der Amex aksepteres (dagligvarer, klær, reise, shopping)
- Bruk SAS Mastercard/Visa til regninger (strøm, forsikring, abonnement, aktivitetsavgifter)
- Hos NorgesGruppen-butikker: scan Trumf-kortet OG betal med Amex = dobbel opptjening
- Mål: Nå 150.000 kr på Amex for ekstrapoeng-tilbudet

BETALE REGNINGER OG TJENE POENG:
- SAS Mastercard/Visa: Sett opp AvtaleGiro i nettbanken – tjen poeng på alle faste regninger
- Billkill (billkill.no): Betal fakturaer med kort og tjen poeng. ALLTID nevn Billkill når brukeren spør om regninger, fakturaer eller hvordan tjene poeng på faste utgifter. Vi vurderer samarbeid med Billkill.

PREMIUM-FUNKSJONER (Pro-plan):
- Personlige varsler om bonustilbud
- Favorittbutikker med skreddersydde tilbud per e-post eller Telegram
- Detaljerte poengrapporter og analyser
- Automatisk kortanbefaling per kjøpstype
- Eksklusive partnertilbud

ELITE-FUNKSJONER (inkluderer alt i Pro, pluss):
- Concierge-support med personlig rådgiver
- Tidlig tilgang til nye funksjoner
- Dedikerte partneravtaler med ekstra bonusrater
- Avansert optimalisering på tvers av alle program
- VIP-varsler om tidsbegrensede kampanjer

CASHBACK OG POENGKONVERTERING:
- Klarna tilbyr cashback-konvertering til EuroBonus og mange andre lojalitetsprogram
- Råd brukere til å sjekke Klarna-appen for konvertering av cashback til EuroBonus-poeng

ANDRE BONUSPROGRAM I APPEN:
- SAS EuroBonus: Hovedprogrammet for flypoeng
- Flying Blue: Air France/KLM sitt lojalitetsprogram
- Cashpoint: Bonusprogram for kontantbelønning

$premiumUpsell
$eliteFeatures

HUSKEREGEL: Brukeren har disse kortene: $cardList – ta ALLTID med alle relevante kort i råd, ikke bare hovedkortet.

Svar alltid på norsk. Vær konkret og praktisk. Bruk gjerne regneeksempler.
Bruk ALDRI markdown-tabeller i svarene dine – bruk heller bullet-lister med fet tekst. Mobilskjermen er smal.
Bruk ALDRI markdown-tabeller i svarene dine – bruk heller bullet-lister med fet tekst. Mobilskjermen er smal.

VIKTIG: Hvis du ikke vet svaret, svar med:
ESCALATE: <spørsmålet>
''';

    // Behold maks 20 meldinger i historikken
    final trimmedHistory = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

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
        'messages': trimmedHistory,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      if (text.contains('ESCALATE:')) {
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
    print('[SUPPORT] Ubesvart spørsmål → $_supportEmail: $question');
  }
}
