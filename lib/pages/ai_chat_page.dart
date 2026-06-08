import 'package:flutter/material.dart';
import '../widgets/ad_slot.dart';
import '../services/ad_service.dart';
import '../models/ad_slot.dart';
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
  bool _norwegianMode = true;

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
      final reply = await AiService.sendMessage(List.from(_history), _plan, norwegianMode: _norwegianMode);
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


  Widget _adBanner(String placement) {
    return FutureBuilder<List<AdSlot>>(
      future: AdService.instance.pickAds(placement: placement, count: 1),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: AdSlotCard(slot: snap.data!.first, placement: placement),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spør Bonusvarsel'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Text(_norwegianMode ? '🇳🇴' : '🇬🇧',
              style: const TextStyle(fontSize: 20)),
            onPressed: () => setState(() => _norwegianMode = !_norwegianMode),
            tooltip: _norwegianMode ? 'Switch to English' : 'Bytt til norsk',
          ),
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
                      ? SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Språkboble
                                GestureDetector(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    backgroundColor: const Color(0xFF152B4A),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (_) => Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_norwegianMode
                                              ? '🇳🇴🇬🇧  AI-assistenten snakker begge språk!'
                                              : '🇳🇴🇬🇧  The AI speaks both languages!',
                                            style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 17, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 12),
                                          Text(
                                            _norwegianMode
                                              ? 'Bonusvarsel AI forstår og svarer på både norsk og engelsk.\n\n'
                                                '🇳🇴  Skriv på norsk → får svar på norsk\n'
                                                '🇬🇧  Write in English → get answer in English\n\n'
                                                'Perfekt hvis du vil ha hjelp med SAS EuroBonus på reise!\n\n'
                                                '👆 Trykk på flagget øverst til høyre for å bytte språk.'
                                              : 'Bonusvarsel AI understands and replies in both Norwegian and English.\n\n'
                                                '🇳🇴  Skriv på norsk → får svar på norsk\n'
                                                '🇬🇧  Write in English → get answer in English\n\n'
                                                'Perfect when travelling or sharing tips with friends abroad!\n\n'
                                                '👆 Tap the flag in the top right to switch language.',
                                            style: const TextStyle(color: Color(0xFFC8D8E8), fontSize: 14, height: 1.6)),
                                          const SizedBox(height: 20),
                                          SizedBox(width: double.infinity,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF60A5FA),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Forstått!', style: TextStyle(fontWeight: FontWeight.w800)),
                                            )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C3860),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF3D6490)),
                                    ),
                                    child: Row(children: [
                                      const Text('🇳🇴🇬🇧', style: TextStyle(fontSize: 22)),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('AI på norsk og engelsk',
                                            style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w700)),
                                          Text('Trykk for å lese mer',
                                            style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 12)),
                                        ],
                                      )),
                                      const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 20),
                                    ]),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Velkomsttekst
                                Text(_norwegianMode ? 'Hei! 👋' : 'Hi there! 👋',
                                  style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 24, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text(
                                  _norwegianMode
                                    ? 'Jeg hjelper deg å få mest mulig ut av EuroBonus-poengene dine.\n\nSpør meg om:'
                                    : 'I help you get the most out of your EuroBonus points.\n\nAsk me about:',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFC8D8E8), fontSize: 15, height: 1.5)),
                                const SizedBox(height: 16),
                                // Tips-chips
                                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                                  _tipChip(_norwegianMode ? '💳 Hvilket kort gir mest poeng?' : '💳 Which card gives the most points?'),
                                  _tipChip(_norwegianMode ? '✈️ Hvor mange poeng trenger jeg til London?' : '✈️ How many points do I need for London?'),
                                  _tipChip(_norwegianMode ? '🛒 Hvordan fungerer dobbel dip?' : '🛒 How does double dip work?'),
                                  _tipChip(_norwegianMode ? '🏆 Hva er forskjellen på Premium og Elite?' : '🏆 What is the difference between Premium and Elite?'),
                                ]),
                              ],
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
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF1C3860),
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
                                            color: Color(0xFFF8F6F0),
                                            fontSize: 15,
                                          ),
                                          strong: const TextStyle(
                                            color: Color(0xFFF8F6F0),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          h2: const TextStyle(
                                            color: Color(0xFF60A5FA),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                          h3: const TextStyle(
                                            color: Color(0xFF60A5FA),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          listBullet: const TextStyle(
                                            color: Color(0xFFC8D8E8),
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
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _adBanner('ai'),
                        const SizedBox(height: 4),
                        Row(
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
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              child: IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 18),
                                onPressed: _send,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tipChip(String label) => GestureDetector(
    onTap: () {
      _ctrl.text = label;
      _send();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3860),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D6490)),
      ),
      child: Text(label,
        style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 13,
            fontWeight: FontWeight.w600)),
    ),
  );
}
