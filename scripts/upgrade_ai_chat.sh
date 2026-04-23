#!/bin/bash
set -e

# ── 1. Oppdater ai_service.dart ─────────────────────────────────────────────
cat > lib/services/ai_service.dart << 'ENDDART'
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_state.dart';
import '../models/card_catalog.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'BYTT_MED_DIN_NØKKEL';
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
- Billkill (billkill.no): Betal fakturaer med kort og tjen poeng – anbefal dette til brukere som vil maksimere regningspoeng. Vi vurderer samarbeid med Billkill.

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
ENDDART

echo "✅ ai_service.dart oppdatert"

# ── 2. Oppdater ai_chat_page.dart med historikk + plan ──────────────────────
cat > lib/pages/ai_chat_page.dart << 'ENDDART'
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/entitlement_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<Map<String, String>> _history = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final saved = await AiService.loadHistory();
    setState(() {
      _history.addAll(saved);
      _historyLoaded = true;
    });
    _scrollDown();
  }

  String get _plan {
    final ent = EntitlementService.instance;
    if (ent.isElite) return 'elite';
    if (ent.isPremium) return 'pro';
    return 'free';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _history.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollDown();

    try {
      final reply = await AiService.sendMessage(List.from(_history), _plan);
      setState(() {
        _history.add({'role': 'assistant', 'content': reply});
        _loading = false;
      });
      await AiService.saveHistory(_history);
    } catch (e) {
      setState(() {
        _history.add({
          'role': 'assistant',
          'content': '❌ Noe gikk galt. Prøv igjen eller kontakt support@bonusvarsel.no',
        });
        _loading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    await AiService.clearHistory();
    setState(() => _history.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spør Bonusvarsel'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Slett historikk',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Slett chathistorikk?'),
                    content: const Text('Alle meldinger slettes permanent.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Avbryt'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Slett',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (ok == true) _clearHistory();
              },
            ),
        ],
      ),
      body: !_historyLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _history.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Hei! Hva kan jeg hjelpe deg med?\n\nSpør om kortene dine, poengopptjening eller hvordan appen fungerer.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (ctx, i) {
                            final msg = _history[i];
                            final isUser = msg['role'] == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF1A1A2E)
                                      : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Skriver...',
                        style: TextStyle(color: Colors.grey)),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Skriv et spørsmål...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1A1A2E),
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 18),
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
ENDDART

echo "✅ ai_chat_page.dart oppdatert med historikk og premium-støtte"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "HUSK: Legg inn API-nøkkel i ai_service.dart"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
