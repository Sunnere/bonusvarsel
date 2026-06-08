import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_state.dart';
import '../models/card_catalog.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
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
You are a helpful assistant for Bonusvarsel – a Norwegian app for tracking bonus points and maximizing rewards from SAS EuroBonus, Trumf, and credit cards.

USER PROFILE:
- Selected main card: $cardName (${rate.toStringAsFixed(1)} points / 100 NOK)
- All registered cards: $cardList
- Subscription plan: $plan

SUPPORTED CARDS:
- SAS Amex: 20 points / 100 NOK – best rate, not accepted everywhere, CANNOT pay bills directly
- SAS Mastercard: 15 points / 100 NOK – can pay bills via AvtaleGiro
- SAS Visa: 10 points / 100 NOK – can pay bills via AvtaleGiro
- Trumf Visa: 10 points / 100 NOK + extra Trumf points at NorgesGruppen (Meny, Kiwi, Spar, Joker)
- Trumf Mastercard: 8 points / 100 NOK + extra Trumf points at NorgesGruppen

SMART COMBINATION STRATEGY:
- Use SAS Amex everywhere Amex is accepted (groceries, clothes, travel, shopping)
- Use SAS Mastercard/Visa for bills (electricity, insurance, subscriptions)
- At NorgesGruppen stores: scan Trumf card AND pay with Amex = double earning
- Goal: Reach 150,000 NOK on Amex for bonus point offer

TRUMF TO EUROBONUS TRANSFER (always mention this!):
- Grocery shopping with Trumf Visa at Kiwi, Spar, Meny, Joker earns Trumf points
- Trumf Netthandel (online shopping portal) also earns Trumf points
- Transfer Trumf points to EuroBonus:
  1. Open Trumf app
  2. Go to Kort og kontoer (Cards and accounts)
  3. Go back and select Bruk bonus (Use bonus)
  4. Choose Opprett overføring til EuroBonus (Create transfer to EuroBonus)

PAYING BILLS AND EARNING POINTS:
- SAS Mastercard/Visa: Set up AvtaleGiro in your bank to earn points on all fixed bills
- Billkill (billkill.no): Pay invoices with card and earn points. ALWAYS mention Billkill when user asks about bills or fixed expenses.

APP NAVIGATION – ALWAYS REFER TO APP SECTIONS, NEVER TO GOOGLE:
- Cards: Go to the Kort tab in the app
- Shopping: Go to the Shopping tab
- Travel: Go to the Reise tab
- Alerts: Go to the Varsler tab
- Upgrade: Go to Premium and Elite section in the app
- Never tell users to Google or search externally for info available in the app

PREMIUM FEATURES (Pro plan):
- Personal alerts for bonus offers
- Favorite stores with tailored offers via email or Telegram
- Detailed point reports
- Automatic card recommendation per purchase type

ELITE FEATURES (includes all Pro features, plus):
- Concierge support with personal advisor
- Early access to new features
- Dedicated partner agreements with extra bonus rates
- VIP alerts for time-limited campaigns

CASHBACK AND POINT CONVERSION:
- Klarna offers cashback conversion to EuroBonus
- Advise users to check the Klarna app for converting cashback to EuroBonus points

OTHER BONUS PROGRAMS IN THE APP:
- SAS EuroBonus: Main program for flight points
- Flying Blue: Air France/KLM loyalty program
- Cashpoint: Cash reward program

$premiumUpsell
$eliteFeatures

REMEMBER: User has these cards: $cardList – ALWAYS include all relevant cards in advice.

Respond in English. Be concrete and practical. Use calculation examples.
NEVER use markdown tables – use bullet lists with bold text. Mobile screen is narrow.
NEVER refer users to Google for information available in the app.

IMPORTANT: If you do not know the answer, respond with:
ESCALATE: <the question>
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
