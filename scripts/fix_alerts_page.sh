#!/bin/bash
set -e

cat > ~/bonusvarsel/lib/pages/bonusvarsel_alerts_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/entitlement_service.dart';

class BonusvarselAlertsPage extends StatefulWidget {
  const BonusvarselAlertsPage({super.key});

  @override
  State<BonusvarselAlertsPage> createState() => _BonusvarselAlertsPageState();
}

class _BonusvarselAlertsPageState extends State<BonusvarselAlertsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _summary = '-';
  String _lastUpdated = '-';

  // Registrering
  final _emailCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  bool _emailSaved = false;
  bool _telegramSaved = false;
  String _emailValue = '';
  String _telegramValue = '';

  // Favoritter
  List<String> _favorites = [];
  final _favCtrl = TextEditingController();

  static const _kEmail = 'alert_email';
  static const _kTelegram = 'alert_telegram';
  static const _kFavorites = 'alert_favorites';

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _telegramCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmail) ?? '';
    final telegram = prefs.getString(_kTelegram) ?? '';
    final favs = prefs.getStringList(_kFavorites) ?? [];
    setState(() {
      _emailValue = email;
      _telegramValue = telegram;
      _emailSaved = email.isNotEmpty;
      _telegramSaved = telegram.isNotEmpty;
      _emailCtrl.text = email;
      _telegramCtrl.text = telegram;
      _favorites = favs;
    });
  }

  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    setState(() {
      _emailValue = email;
      _emailSaved = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-post lagret! Du vil motta bonusvarsler.')),
    );
  }

  Future<void> _saveTelegram() async {
    final telegram = _telegramCtrl.text.trim();
    if (telegram.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTelegram, telegram);
    setState(() {
      _telegramValue = telegram;
      _telegramSaved = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telegram lagret! Du vil motta bonusvarsler.')),
    );
  }

  Future<void> _addFavorite() async {
    final fav = _favCtrl.text.trim();
    if (fav.isEmpty || _favorites.contains(fav)) return;
    final newFavs = [..._favorites, fav];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, newFavs);
    setState(() {
      _favorites = newFavs;
      _favCtrl.clear();
    });
  }

  Future<void> _removeFavorite(String fav) async {
    final newFavs = _favorites.where((f) => f != fav).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, newFavs);
    setState(() => _favorites = newFavs);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final health = await ApiService.getHealth();
      final pipeline = health['pipeline'] is Map
          ? Map<String, dynamic>.from(health['pipeline'] as Map)
          : <String, dynamic>{};
      final notifications = pipeline['notifications'] is Map
          ? Map<String, dynamic>.from(pipeline['notifications'] as Map)
          : <String, dynamic>{};
      final itemsRaw = notifications['items'] is List
          ? (notifications['items'] as List)
          : const [];
      final items = itemsRaw.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _summary = (pipeline['summary'] ?? '-').toString();
        _lastUpdated = (pipeline['lastUpdated'] ?? '-').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _copyUrl(String url) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lenke kopiert')),
    );
  }

  bool get _isPremium => EntitlementService.instance.isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Varsler'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔔 Bonusvarsler',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                  const SizedBox(height: 8),
                  const Text(
                    'Få varsler når SAS og Trumf har de beste tilbudene – på e-post eller Telegram.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statChip('Varsler', _items.length.toString()),
                    const SizedBox(width: 8),
                    _statChip('Oppdatert', _lastUpdated),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Registrer e-post ──
            _sectionTitle('📧 E-postvarsler'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveEmail(),
              decoration: InputDecoration(
                labelText: 'Din e-postadresse',
                hintText: 'navn@example.com',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_emailSaved ? Icons.check_circle : Icons.save,
                    color: _emailSaved ? Colors.green : null),
                  onPressed: _saveEmail,
                ),
              ),
            ),
            if (_emailSaved) ...[
              const SizedBox(height: 6),
              Text('✅ Varsler sendes til $_emailValue',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 20),

            // ── Registrer Telegram ──
            _sectionTitle('✈️ Telegram-varsler'),
            const SizedBox(height: 4),
            const Text('Legg til @BonusvarselBot på Telegram og skriv inn brukernavn ditt:',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _telegramCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveTelegram(),
                  decoration: InputDecoration(
                    labelText: 'Telegram-brukernavn',
                    hintText: '@dittbrukernavn',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_telegramSaved ? Icons.check_circle : Icons.save,
                        color: _telegramSaved ? Colors.green : null),
                      onPressed: _saveTelegram,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => launchUrl(Uri.parse('https://t.me/BonusvarselBot')),
                child: const Text('Åpne Bot'),
              ),
            ]),
            if (_telegramSaved) ...[
              const SizedBox(height: 6),
              Text('✅ Varsler sendes til $_telegramValue',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 20),

            // ── Favorittbutikker ──
            _sectionTitle('⭐ Favorittbutikker'),
            const SizedBox(height: 4),
            Text(
              _isPremium
                ? 'Legg til butikker du handler i ofte. Du får varsel når de har bonus.'
                : 'Oppgrader til Premium for å lagre favorittbutikker og få personlige varsler.',
              style: TextStyle(
                color: _isPremium ? Colors.grey[700] : Colors.orange[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            if (_isPremium) ...[
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _favCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addFavorite(),
                    decoration: const InputDecoration(
                      labelText: 'Legg til butikk',
                      hintText: 'f.eks. Elkjøp, Zalando...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addFavorite,
                  child: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 12),
              if (_favorites.isEmpty)
                const Text('Ingen favoritter lagt til ennå.',
                  style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites.map((fav) => Chip(
                    label: Text(fav),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFavorite(fav),
                  )).toList(),
                ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/premium'),
                icon: const Icon(Icons.lock_open),
                label: const Text('Oppgrader til Premium'),
              ),
            ],
            const SizedBox(height: 24),

            // ── Aktive varsler ──
            _sectionTitle('🏆 Aktive bonusvarsler'),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _errorState()
            else if (_items.isEmpty)
              _emptyState()
            else
              ..._items.asMap().entries.map(
                (entry) => _notificationCard(entry.value, entry.key)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _notificationCard(Map<String, dynamic> item, int index) {
    final title = (item['title'] ?? '-').toString();
    final body = (item['body'] ?? '-').toString();
    final rate = (item['rate'] ?? '-').toString();
    final url = (item['url'] ?? '').toString();
    final isTop = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTop ? Colors.green : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            if (isTop) const Text('🏆', style: TextStyle(fontSize: 20)),
          ]),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text('Rate: $rate', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(url)),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Åpne tilbud'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _copyUrl(url),
                icon: const Icon(Icons.copy, size: 16),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingen aktive varsler akkurat nå.',
            style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Nye kampanjer dukker opp her automatisk.',
            style: TextStyle(color: Color(0xFF166534))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Oppdater varsler'),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text('Kunne ikke hente varsler: $_error',
        style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700)),
    );
  }
}
DART

echo "✅ Varsler-side oppdatert med e-post, Telegram og favoritter"
