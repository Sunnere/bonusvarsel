#!/bin/bash
set -e

# ── 1. ai_service.dart ──────────────────────────────────────────────────────
cat > lib/services/ai_service.dart << 'ENDDART'
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_state.dart';
import '../models/card_catalog.dart';

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'DIN_ANTHROPIC_API_NØKKEL';
  static const String _supportEmail = 'support@bonusvarsel.no';

  static Future<String> sendMessage(List<Map<String, String>> history) async {
    final cardId = await UserState.getSelectedCardId();
    final cardName = CardCatalog.nameFor(cardId);
    final rate = await UserState.getSelectedCardRatePer100() ?? 0.0;

    final systemPrompt = '''
Du er en hjelpsom støtteassistent for Bonusvarsel – en norsk app for bonus- og poengsporing.

Brukeren har valgt kort: $cardName
Opptjeningsrate: ${rate.toStringAsFixed(1)} poeng per 100 kr

Kortene appen støtter:
- SAS Amex: 20 poeng / 100 kr
- SAS Mastercard: 15 poeng / 100 kr
- SAS Visa: 10 poeng / 100 kr
- Trumf Visa: 10 poeng / 100 kr
- Trumf Mastercard: 8 poeng / 100 kr

Hjelp brukeren med spørsmål om appen, kortene, poengopptjening og bonuser.
Svar alltid på norsk. Vær kort og presis.

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
    // Bruker mailto-lenke som fallback – kan byttes til SMTP-tjeneste senere
    // For nå logges det bare slik at du ser det under utvikling
    // ignore: avoid_print
    print('[SUPPORT] Ubesvart spørsmål sendt til $_supportEmail: $question');
  }
}
ENDDART

echo "✅ ai_service.dart opprettet"

# ── 2. ai_chat_page.dart ─────────────────────────────────────────────────────
cat > lib/pages/ai_chat_page.dart << 'ENDDART'
import 'package:flutter/material.dart';
import '../services/ai_service.dart';

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
      final reply = await AiService.sendMessage(List.from(_history));
      setState(() {
        _history.add({'role': 'assistant', 'content': reply});
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spør Bonusvarsel'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Hei! Hva kan jeg hjelpe deg med?\n\nSpør om kortene dine, poengopptjening eller hvordan appen fungerer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
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
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
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
                              color: isUser ? Colors.white : Colors.black87,
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
              child: Text('Skriver...', style: TextStyle(color: Colors.grey)),
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
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
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

echo "✅ ai_chat_page.dart opprettet"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NESTE STEG:"
echo "1. Legg inn API-nøkkel i lib/services/ai_service.dart"
echo "   (bytt ut DIN_ANTHROPIC_API_NØKKEL)"
echo "2. Legg til AiChatPage i navigasjonen din"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
