#!/bin/bash
set -e

cat > lib/pages/ai_chat_page.dart << 'ENDDART'
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
                            final content = msg['content'] ?? '';
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
                                      MediaQuery.of(context).size.width * 0.85,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF1A1A2E)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: isUser
                                    ? Text(
                                        content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      )
                                    : MarkdownBody(
                                        data: content,
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                          strong: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          h2: const TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                          h3: const TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          listBullet: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                          tableBody: const TextStyle(
                                            fontSize: 13,
                                          ),
                                          tableBorder: TableBorder.all(
                                            color: Colors.grey,
                                            width: 0.5,
                                          ),
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

echo "✅ ai_chat_page.dart oppdatert med markdown-rendering"
