import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

class DevPipelinePanel extends StatefulWidget {
  const DevPipelinePanel({super.key});

  @override
  State<DevPipelinePanel> createState() => _DevPipelinePanelState();
}

class _DevPipelinePanelState extends State<DevPipelinePanel> {
  Timer? _timer;

  bool _loading = false;
  bool _refreshing = false;
  bool _processingQueue = false;
  bool _clearingQueue = false;

  String? _message;
  String? _error;

  bool _scanActive = false;
  bool _detectActive = false;
  bool _enqueueActive = false;
  bool _queueActive = false;
  bool _dispatchActive = false;

  int _eventsCount = 0;
  int _queueCount = 0;
  int _dispatchCount = 0;
  int _currentOfferCount = 0;

  String _provider = '-';
  String _deliveryMode = '-';

  final TextEditingController _deviceController =
      TextEditingController(text: 'dev_simulator');
  bool _broadcastMode = false;
  String _selectedPreset = 'simulator';

  static const Map<String, List<String>> _presets = {
    'simulator': ['dev_simulator'],
    'pair': ['dev_a', 'dev_b'],
    'triple': ['dev_a', 'dev_b', 'dev_c'],
  };

  List<Map<String, dynamic>> _pendingItems = const [];
  List<Map<String, dynamic>> _processedItems = const [];

  DateTime? _lastUpdated;

  static const Color _bg = Color(0xFF07121F);
  static const Color _panel = Color(0xFF0B1728);
  static const Color _panel2 = Color(0xFF122033);
  static const Color _border = Color(0xFF2F435C);

  static const Color _text = Color(0xFFF8FAFC);
  static const Color _textSoft = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFFCBD5E1);

  static const Color _blue = Color(0xFF60A5FA);
  static const Color _blueDark = Color(0xFF1D4ED8);
  static const Color _green = Color(0xFF34D399);
  static const Color _greenDark = Color(0xFF047857);
  static const Color _amber = Color(0xFFFBBF24);
  static const Color _amberDark = Color(0xFFB45309);
  static const Color _purpleDark = Color(0xFF7C3AED);
  static const Color _red = Color(0xFFF87171);
  static const Color _redDark = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    _applyPreset('simulator', syncText: true);
    _refreshStatus();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshStatus(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deviceController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset, {bool syncText = true}) {
    setState(() {
      _selectedPreset = preset;

      if (preset == 'broadcast') {
        _broadcastMode = true;
        return;
      }

      _broadcastMode = false;

      if (preset == 'manual') {
        return;
      }

      if (syncText) {
        final values = _presets[preset] ?? const <String>[];
        _deviceController.text = values.join(', ');
      }
    });
  }

  void _handleBroadcastChanged(bool value) {
    setState(() {
      _broadcastMode = value;
      if (value) {
        _selectedPreset = 'broadcast';
      } else if (_selectedPreset == 'broadcast') {
        _selectedPreset = 'manual';
      }
    });
  }

  void _handleManuellTextChanged(String _) {
    if (_broadcastMode) return;

    final current = _selectedDeviceIds();
    final matchedPreset = _matchPreset(current);

    setState(() {
      _selectedPreset = matchedPreset ?? 'manual';
    });
  }

  String? _matchPreset(List<String> current) {
    for (final entry in _presets.entries) {
      if (_sameList(entry.value, current)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> _selectedDeviceIds() {
    if (_broadcastMode) return const [];

    final raw = _deviceController.text.trim();
    if (raw.isEmpty) return const [];

    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String _targetingSummary() {
    if (_broadcastMode) return 'broadcast';
    final ids = _selectedDeviceIds();
    if (ids.isEmpty) return 'ingen valgt';
    return ids.join(', ');
  }

  Future<void> _simulateCampaign() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/v1/dev/seed-offer');
      final deviceIds = _selectedDeviceIds();

      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'storeId': 'store_test',
          'rate': 20,
          'rateText': '20 EB / 100 kr',
          'campaign': true,
          'expires': '2026-12-31',
          'level': 'boost',
          'deviceIds': deviceIds,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('POST /v1/dev/seed-offer failed: ${response.statusCode}');
      }

      if (!mounted) return;

      setState(() {
        _message = deviceIds.isEmpty
            ? 'Fake campaign opprettet for broadcast'
            : 'Fake campaign opprettet for ${deviceIds.join(', ')}';
      });

      await _refreshStatus(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _processQueueNow() async {
    if (_processingQueue) return;

    setState(() {
      _processingQueue = true;
      _message = null;
      _error = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/v1/push/queue/process');
      final response = await http.post(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('POST /v1/push/queue/process failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final map = _asMap(decoded);

      final processedCount = _readInt(map['processedCount']);
      final remainingCount = _readInt(map['remainingCount']);
      final rateLimited = map['rateLimited'] == true;

      if (!mounted) return;

      setState(() {
        _message = rateLimited
            ? 'Queue prosessert: $processedCount sendt, $remainingCount igjen (rate limited)'
            : 'Queue prosessert: $processedCount sendt, $remainingCount igjen';
      });

      await _refreshStatus(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingQueue = false;
        });
      }
    }
  }

  Future<void> _clearQueueNow() async {
    if (_clearingQueue) return;

    setState(() {
      _clearingQueue = true;
      _message = null;
      _error = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/v1/push/queue/clear');
      final response = await http.post(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('POST /v1/push/queue/clear failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final map = _asMap(decoded);
      final cleared = _readInt(map['cleared']);

      if (!mounted) return;

      setState(() {
        _message = 'Queue tømt: $cleared item(s) fjernet';
      });

      await _refreshStatus(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _clearingQueue = false;
        });
      }
    }
  }

  Future<void> _refreshStatus({bool silent = false}) async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
      if (!silent) {
        _error = null;
      }
    });

    try {
      final stateUri = Uri.parse('${ApiService.baseUrl}/v1/dev/campaign-push-state');
      final queueUri = Uri.parse('${ApiService.baseUrl}/v1/push/queue');

      final responses = await Future.wait([
        http.get(stateUri).timeout(const Duration(seconds: 4)),
        http.get(queueUri).timeout(const Duration(seconds: 4)),
      ]);

      final stateRes = responses[0];
      final queueRes = responses[1];

      if (stateRes.statusCode < 200 || stateRes.statusCode >= 300) {
        throw Exception('GET /v1/dev/campaign-push-state failed: ${stateRes.statusCode}');
      }
      if (queueRes.statusCode < 200 || queueRes.statusCode >= 300) {
        throw Exception('GET /v1/push/queue failed: ${queueRes.statusCode}');
      }

      final decodedState = jsonDecode(stateRes.body);
      final decodedQueue = jsonDecode(queueRes.body);

      final stateMap = _asMap(decodedState);
      final queueMap = _asMap(decodedQueue);
      final queueSummary = _asMap(queueMap['summary']);

      final queueItems =
          _extractQueueItems(decodedQueue).map((e) => _asMap(e)).toList();
      final events = _extractEvents(stateMap);
      final currentOfferIds = _extractCurrentOfferIds(stateMap);

      final pendingItems =
          queueItems.where((item) => !_isProcessed(item)).toList(growable: false);
      final processedItems =
          queueItems.where(_isProcessed).toList(growable: false);

      if (!mounted) return;

      setState(() {
        _scanActive = true;
        _detectActive = currentOfferIds.isNotEmpty;
        _enqueueActive = events.isNotEmpty;
        _queueActive = pendingItems.isNotEmpty;
        _dispatchActive = processedItems.isNotEmpty;

        _eventsCount = events.length;
        _queueCount = pendingItems.length;
        _dispatchCount = processedItems.length;
        _currentOfferCount = currentOfferIds.length;

        _provider = queueSummary['provider']?.toString() ?? '-';
        _deliveryMode = queueSummary['deliveryMode']?.toString() ?? '-';

        _pendingItems = pendingItems;
        _processedItems = processedItems;

        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _scanActive = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return <String, dynamic>{};
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  List<dynamic> _extractQueueItems(dynamic decodedQueue) {
    if (decodedQueue is List) return decodedQueue;

    final map = _asMap(decodedQueue);
    final candidates = [
      map['items'],
      map['queue'],
      map['entries'],
      map['data'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) return candidate;
    }

    return const [];
  }

  List<dynamic> _extractEvents(Map<String, dynamic> stateMap) {
    final direct = stateMap['events'];
    if (direct is List) return direct;
    return const [];
  }

  List<String> _extractCurrentOfferIds(Map<String, dynamic> stateMap) {
    final nestedState = _asMap(stateMap['state']);
    final ids = nestedState['lastSeenOfferIds'];
    if (ids is List) return ids.map((e) => '$e').toList();
    return const [];
  }

  bool _isProcessed(dynamic raw) {
    final item = _asMap(raw);
    return item['processed'] == true;
  }

  List<String> _extractDeviceIds(Map<String, dynamic> item) {
    final direct = item['deviceIds'];
    if (direct is List) {
      return direct.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    }

    final data = _asMap(item['data']);
    final nested = data['deviceIds'];
    if (nested is List) {
      return nested.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    }

    return const [];
  }

  Color _activeColor(String step) {
    switch (step) {
      case 'SCAN':
        return _blueDark;
      case 'DETECT':
        return _purpleDark;
      case 'ENQUEUE':
        return _amberDark;
      case 'QUEUE':
        return const Color(0xFF475569);
      case 'DISPATCH':
        return _greenDark;
      default:
        return const Color(0xFF334155);
    }
  }

  Widget _timelineStep({
    required String label,
    required bool active,
    bool isLast = false,
  }) {
    final color = active ? _activeColor(label) : const Color(0xFF243244);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? color : _border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? _text : _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward,
            size: 16,
            color: _textMuted,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: _text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _presetButton({
    required String preset,
    required String label,
  }) {
    final selected = _selectedPreset == preset;

    return OutlinedButton(
      onPressed: () => _applyPreset(preset),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: selected ? _blue : _border,
        ),
        foregroundColor: selected ? _text : _textSoft,
        backgroundColor: selected ? const Color(0xFF183250) : _panel2,
      ),
      child: Text(label),
    );
  }

  Widget _queueItemCard(Map<String, dynamic> item) {
    final data = _asMap(item['data']);
    final deviceIds = _extractDeviceIds(item);

    final id = item['id']?.toString() ?? '-';
    final offerId = item['offerId']?.toString() ?? data['offerId']?.toString() ?? '-';
    final title = item['title']?.toString() ?? data['title']?.toString() ?? '-';
    final body = item['body']?.toString() ?? data['body']?.toString() ?? '-';
    final provider = item['provider']?.toString() ?? data['provider']?.toString() ?? '-';
    final deliveryMode =
        item['deliveryMode']?.toString() ?? data['deliveryMode']?.toString() ?? '-';
    final processed = item['processed'] == true;
    final processedAt = item['processedAt']?.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: processed ? _greenDark : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            processed ? 'prosessert · $id' : 'venter · $id',
            style: TextStyle(
              color: processed ? _green : _text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'offerId: $offerId',
            style: const TextStyle(
              color: _textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'provider: $provider · mode: $deliveryMode',
            style: const TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'deviceIds: ${deviceIds.isEmpty ? 'broadcast' : deviceIds.join(', ')}',
            style: const TextStyle(
              color: _amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (processedAt != null && processedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'prosessert: $processedAt',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _targetingBlock() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device-targeting',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetButton(preset: 'broadcast', label: 'Broadcast'),
              _presetButton(preset: 'simulator', label: 'Simulator'),
              _presetButton(preset: 'pair', label: '2 devices'),
              _presetButton(preset: 'triple', label: '3 devices'),
              _presetButton(preset: 'manual', label: 'Manuell'),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _broadcastMode,
            onChanged: _handleBroadcastChanged,
            title: const Text(
              'Broadcast',
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text(
              'Når på, sendes simulate uten deviceIds',
              style: TextStyle(color: _textMuted),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deviceController,
            enabled: !_broadcastMode,
            style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
            onChanged: _handleManuellTextChanged,
            decoration: InputDecoration(
              labelText: 'Device IDs',
              labelStyle: const TextStyle(color: _textSoft),
              hintText: 'dev_a, dev_b, dev_c',
              helperText: 'Kommaseparer flere device IDs',
              helperStyle: const TextStyle(color: _textMuted),
              hintStyle: const TextStyle(color: _textMuted),
              filled: true,
              fillColor: _panel2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aktiv targeting: ${_targetingSummary()}',
            style: const TextStyle(
              color: _amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorBlock() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kø-inspektør',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('provider', _provider),
              _metricChip('mode', _deliveryMode),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _processingQueue ? null : _processQueueNow,
                icon: _processingQueue
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow, size: 16),
                label: Text(_processingQueue ? 'Prosesserer...' : 'Prosesser kø'),
                style: FilledButton.styleFrom(
                  backgroundColor: _greenDark,
                  foregroundColor: _text,
                ),
              ),
              FilledButton.icon(
                onPressed: _clearingQueue ? null : _clearQueueNow,
                icon: _clearingQueue
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.clear_all, size: 16),
                label: Text(_clearingQueue ? 'Tømmer...' : 'Tøm kø'),
                style: FilledButton.styleFrom(
                  backgroundColor: _redDark,
                  foregroundColor: _text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pending items',
            style: TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_pendingItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ingen pending items',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ..._pendingItems.take(6).map(_queueItemCard),
          const SizedBox(height: 14),
          const Text(
            'Processed items',
            style: TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_processedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ingen processed items',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ..._processedItems.take(6).map(_queueItemCard),
        ],
      ),
    );
  }

  Widget _timelineBlock() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live pipeline-tidslinje',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _timelineStep(label: 'SCAN', active: _scanActive),
                _timelineStep(label: 'DETECT', active: _detectActive),
                _timelineStep(label: 'ENQUEUE', active: _enqueueActive),
                _timelineStep(label: 'QUEUE', active: _queueActive),
                _timelineStep(
                  label: 'DISPATCH',
                  active: _dispatchActive,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('offers', '$_currentOfferCount'),
              _metricChip('events', '$_eventsCount'),
              _metricChip('queue', '$_queueCount'),
              _metricChip('dispatch', '$_dispatchCount'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _lastUpdated == null
                ? 'Ingen live-data ennå'
                : 'Sist oppdatert: ${_lastUpdated!.toIso8601String()}',
            style: const TextStyle(
              color: _textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: _text),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Campaign push pipeline',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                onPressed: _refreshing ? null : () => _refreshStatus(),
                icon: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: _text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Live dev pipeline med backend-status for scan, queue og dispatch.',
            style: TextStyle(color: _textSoft, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _simulateCampaign,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science, size: 16),
            label: Text(_loading ? 'Simulerer...' : 'Simuler kampanje'),
            style: FilledButton.styleFrom(
              backgroundColor: _blueDark,
              foregroundColor: _text,
            ),
          ),
          _targetingBlock(),
          _timelineBlock(),
          _inspectorBlock(),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2A22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _greenDark),
              ),
              child: Text(
                _message!,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF34161A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _redDark),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: _red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
