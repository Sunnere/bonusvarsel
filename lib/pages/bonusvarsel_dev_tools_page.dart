import 'dart:convert';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';
import 'bonusvarsel_push_preview_page.dart';

class BonusvarselDevToolsPage extends StatefulWidget {
  const BonusvarselDevToolsPage({super.key});

  @override
  State<BonusvarselDevToolsPage> createState() => _BonusvarselDevToolsPageState();
}

class _BonusvarselDevToolsPageState extends State<BonusvarselDevToolsPage> {
  final _storeIdCtrl = TextEditingController(text: 'store_power');
  final _rateCtrl = TextEditingController(text: '30');
  final _rateTextCtrl = TextEditingController(text: '30 EB / 100 kr');
  final _startAtCtrl = TextEditingController();
  final _expiresCtrl = TextEditingController(
    text: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
  );

  String _level = 'boost';
  bool _campaign = true;
  bool _busy = false;
  String _output = 'Ingen handlinger kjørt enda.';
  String _lastActionTitle = 'Ingen handling enda';
  String _lastActionStatus = 'idle';
  String _lastActionAt = '-';
  Map<String, dynamic> _lastResult = const {};

  @override
  void dispose() {
    _storeIdCtrl.dispose();
    _rateCtrl.dispose();
    _rateTextCtrl.dispose();
    _startAtCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(
    String title,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (_busy) return;

    final startedAt = DateTime.now();

    setState(() {
      _busy = true;
      _output = '$title ...';
      _lastActionTitle = title;
      _lastActionStatus = 'running';
      _lastActionAt = startedAt.toIso8601String();
    });

    try {
      final result = await action();
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _output = '$title\n\n${encoder.convert(result)}';
        _lastActionTitle = title;
        _lastActionStatus = 'success';
        _lastActionAt = DateTime.now().toIso8601String();
        _lastResult = result;
      });
    } catch (e) {
      setState(() {
        _output = '$title feilet\n\n$e';
        _lastActionTitle = title;
        _lastActionStatus = 'error';
        _lastActionAt = DateTime.now().toIso8601String();
        _lastResult = const {};
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }


  void _applyPreset({
    required String storeId,
    required String rate,
    required String rateText,
    required String level,
    required String expires,
    String startAt = '',
    bool campaign = true,
  }) {
    setState(() {
      _storeIdCtrl.text = storeId;
      _rateCtrl.text = rate;
      _rateTextCtrl.text = rateText;
      _startAtCtrl.text = startAt;
      _expiresCtrl.text = expires;
      _level = level;
      _campaign = campaign;
    });
  }

  void _presetPowerBoost() {
    _applyPreset(
      storeId: 'store_power',
      rate: '30',
      rateText: '30 EB / 100 kr',
      level: 'boost',
      expires: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
    );
  }

  void _presetHotelsPremium() {
    _applyPreset(
      storeId: 'store_hotels',
      rate: '20',
      rateText: '20 EB / 100 kr',
      level: 'premium',
      expires: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    );
  }

  void _presetAppleElite() {
    _applyPreset(
      storeId: 'store_apple',
      rate: '25',
      rateText: '25 EB / 100 kr',
      level: 'elite',
      expires: DateTime.now().add(const Duration(days: 4)).toIso8601String(),
    );
  }

  void _presetFutureCampaign() {
    final start = DateTime.now().add(const Duration(hours: 2));
    final end = start.add(const Duration(days: 1));

    _applyPreset(
      storeId: 'store_power',
      rate: '18',
      rateText: '18 EB / 100 kr',
      level: 'boost',
      startAt: start.toIso8601String(),
      expires: end.toIso8601String(),
    );
  }



  Future<void> _quickSeed({
    required String title,
    required String storeId,
    required num rate,
    required String rateText,
    required String level,
    required String expires,
    String? startAt,
    bool campaign = true,
  }) async {
    await _run(
      title,
      () => ApiService.seedDevOffer(
        storeId: storeId,
        rate: rate,
        rateText: rateText,
        level: level,
        campaign: campaign,
        startAt: startAt,
        expires: expires,
      ),
    );
  }


  Future<void> _quickSeedAndOpenPushPreview({
    required String title,
    required String storeId,
    required num rate,
    required String rateText,
    required String level,
    required String expires,
    String? startAt,
    bool campaign = true,
  }) async {
    await _quickSeed(
      title: title,
      storeId: storeId,
      rate: rate,
      rateText: rateText,
      level: level,
      expires: expires,
      startAt: startAt,
      campaign: campaign,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BonusvarselPushPreviewPage(),
      ),
    );
  }

  Future<void> _seedPowerAndOpenPushPreview() async {
    await _quickSeedAndOpenPushPreview(
      title: 'Quick seed + open Push Preview: Power Boost',
      storeId: 'store_power',
      rate: 30,
      rateText: '30 EB / 100 kr',
      level: 'boost',
      expires: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
    );
  }

  Future<void> _seedHotelsAndOpenPushPreview() async {
    await _quickSeedAndOpenPushPreview(
      title: 'Quick seed + open Push Preview: Hotels Premium',
      storeId: 'store_hotels',
      rate: 20,
      rateText: '20 EB / 100 kr',
      level: 'premium',
      expires: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    );
  }


  Future<void> _quickSeedPowerBoost() async {
    await _quickSeed(
      title: 'Quick seed: Power Boost',
      storeId: 'store_power',
      rate: 30,
      rateText: '30 EB / 100 kr',
      level: 'boost',
      expires: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
    );
  }

  Future<void> _quickSeedHotelsPremium() async {
    await _quickSeed(
      title: 'Quick seed: Hotels Premium',
      storeId: 'store_hotels',
      rate: 20,
      rateText: '20 EB / 100 kr',
      level: 'premium',
      expires: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    );
  }

  Future<void> _quickSeedAppleElite() async {
    await _quickSeed(
      title: 'Quick seed: Apple Elite',
      storeId: 'store_apple',
      rate: 25,
      rateText: '25 EB / 100 kr',
      level: 'elite',
      expires: DateTime.now().add(const Duration(days: 4)).toIso8601String(),
    );
  }

  Future<void> _quickSeedFutureCampaign() async {
    final start = DateTime.now().add(const Duration(hours: 2));
    final end = start.add(const Duration(days: 1));

    await _quickSeed(
      title: 'Quick seed: Future Campaign',
      storeId: 'store_power',
      rate: 18,
      rateText: '18 EB / 100 kr',
      level: 'boost',
      startAt: start.toIso8601String(),
      expires: end.toIso8601String(),
    );
  }


  Future<Map<String, dynamic>> _seedOffer() async {
    final rate = num.tryParse(_rateCtrl.text.trim());
    if (rate == null) {
      throw Exception('Ugyldig rate');
    }

    final startAt = _startAtCtrl.text.trim().isEmpty
        ? null
        : _startAtCtrl.text.trim();

    return ApiService.seedDevOffer(
      storeId: _storeIdCtrl.text.trim(),
      rate: rate,
      rateText: _rateTextCtrl.text.trim(),
      level: _level,
      campaign: _campaign,
      startAt: startAt,
      expires: _expiresCtrl.text.trim(),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1F4D),
            Color(0xFF2F80ED),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonusvarsel Dev Tools',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.surface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seed offer, reset notifications og test push preview direkte fra appen.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }




  Widget _seedAndOpenCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seed + open Push Preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: _busy ? null : _seedPowerAndOpenPushPreview,
                child: const Text('Power → Push Preview'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _seedHotelsAndOpenPushPreview,
                child: const Text('Hotels → Push Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _quickSeedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One-tap quick seed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: _busy ? null : _quickSeedPowerBoost,
                child: const Text('Seed Power Boost'),
              ),
              FilledButton(
                onPressed: _busy ? null : _quickSeedHotelsPremium,
                child: const Text('Seed Hotels Premium'),
              ),
              FilledButton(
                onPressed: _busy ? null : _quickSeedAppleElite,
                child: const Text('Seed Apple Elite'),
              ),
              FilledButton(
                onPressed: _busy ? null : _quickSeedFutureCampaign,
                child: const Text('Seed Future Campaign'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _presetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seed presets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: _busy ? null : _presetPowerBoost,
                child: const Text('Power Boost'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _presetHotelsPremium,
                child: const Text('Hotels Premium'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _presetAppleElite,
                child: const Text('Apple Elite'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _presetFutureCampaign,
                child: const Text('Future Campaign'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seed offer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _storeIdCtrl,
            decoration: const InputDecoration(labelText: 'storeId'),
          ),
          TextField(
            controller: _rateCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'rate'),
          ),
          TextField(
            controller: _rateTextCtrl,
            decoration: const InputDecoration(labelText: 'rateText'),
          ),
          TextField(
            controller: _startAtCtrl,
            decoration: const InputDecoration(
              labelText: 'startAt (optional, ISO8601)',
            ),
          ),
          TextField(
            controller: _expiresCtrl,
            decoration: const InputDecoration(
              labelText: 'expires (ISO8601)',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _level,
            items: const [
              DropdownMenuItem(value: 'standard', child: Text('standard')),
              DropdownMenuItem(value: 'boost', child: Text('boost')),
              DropdownMenuItem(value: 'premium', child: Text('premium')),
              DropdownMenuItem(value: 'elite', child: Text('elite')),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _level = value);
                  },
            decoration: const InputDecoration(labelText: 'level'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Campaign'),
            value: _campaign,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() => _campaign = value);
                  },
          ),
        ],
      ),
    );
  }


  Widget _resetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset dev state',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                          'POST /v1/dev/reset-state',
                          () => ApiService.resetDevState(),
                        ),
                child: const Text('Reset state'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _actionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton(
            onPressed: _busy ? null : () => _run('POST /v1/dev/seed-offer', _seedOffer),
            child: const Text('Seed offer'),
          ),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _run(
                      'GET /v1/notifications/activated',
                      () => ApiService.getActivatedNotifications(),
                    ),
            child: const Text('Notifications'),
          ),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _run(
                      'GET /v1/notifications/activated?reset=1',
                      () => ApiService.getActivatedNotifications(reset: true),
                    ),
            child: const Text('Reset notifications'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                      'GET /v1/push/dispatch',
                      () => ApiService.getPushDispatchPreview(),
                    ),
            child: const Text('Push preview'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                      'GET /v1/push/dispatch?reset=1',
                      () => ApiService.getPushDispatchPreview(reset: true),
                    ),
            child: const Text('Reset push'),
          ),
        ],
      ),
    );
  }


  Widget _statusCard() {
    Color color;
    switch (_lastActionStatus) {
      case 'success':
        color = Colors.green;
        break;
      case 'error':
        color = Colors.red;
        break;
      case 'running':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Siste handling: $_lastActionTitle\n'
              'Status: $_lastActionStatus\n'
              'Tid: $_lastActionAt',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _summaryCard() {
    final entries = <String, String>{};

    void addIfPresent(String key) {
      final value = _lastResult[key];
      if (value != null) {
        entries[key] = value.toString();
      }
    }

    for (final key in const [
      'ok',
      'count',
      'offersCount',
      'devicesCount',
      'dispatchCount',
      'deviceCount',
      'notificationCount',
      'seenCount',
      'tier',
    ]) {
      addIfPresent(key);
    }

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text(
          'Ingen oppsummering tilgjengelig ennå.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Result summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...entries.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _outputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: SelectableText(
        _output,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 16),
          _seedAndOpenCard(),
          const SizedBox(height: 16),
          _quickSeedCard(),
          const SizedBox(height: 16),
          _presetCard(),
          const SizedBox(height: 16),
          _formCard(),
          const SizedBox(height: 16),
          _resetCard(),
          const SizedBox(height: 16),
          _actionsCard(),
          const SizedBox(height: 16),
          _statusCard(),
          const SizedBox(height: 16),
          _summaryCard(),
          const SizedBox(height: 16),
          _outputCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
