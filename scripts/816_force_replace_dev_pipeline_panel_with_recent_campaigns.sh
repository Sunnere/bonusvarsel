#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_816.$(date +%s)"
echo "✅ Backup laget: $FILE"

cat > "$FILE" <<'DART'
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DevPipelinePanel extends StatefulWidget {
  const DevPipelinePanel({super.key});

  @override
  State<DevPipelinePanel> createState() => _DevPipelinePanelState();
}

class _DevPipelinePanelState extends State<DevPipelinePanel> {
  static const Color _bg = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _textSoft = Color(0xFF4B5563);
  static const Color _border = Color(0xFFE5E7EB);

  Map<String, dynamic>? _pipeline;
  List<Map<String, dynamic>> _recentCampaigns = const [];
  String? _inspectorText;
  bool _loading = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _inspectorText = null;
    });

    try {
      final result = await ApiService.getHealth();
      final pipelineRoot = result['pipeline'];
      final pipeline = pipelineRoot is Map<String, dynamic>
          ? pipelineRoot
          : (pipelineRoot is Map
              ? Map<String, dynamic>.from(pipelineRoot)
              : <String, dynamic>{});

      final recent = pipeline['recentCampaigns'];
      final campaigns = recent is List
          ? recent
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _pipeline = pipeline;
        _recentCampaigns = campaigns;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inspectorText = 'Refresh feilet: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: _textSoft,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nestedPipeline = _pipeline?['pipeline'];
    final pipelineNumbers = nestedPipeline is Map<String, dynamic>
        ? nestedPipeline
        : (nestedPipeline is Map
            ? Map<String, dynamic>.from(nestedPipeline)
            : <String, dynamic>{});

    final scanned =
        (pipelineNumbers['scanned'] ?? _pipeline?['scanned'] ?? '-').toString();
    final queued =
        (pipelineNumbers['queued'] ?? _pipeline?['queued'] ?? '-').toString();
    final dispatched =
        (pipelineNumbers['dispatched'] ?? _pipeline?['dispatched'] ?? '-')
            .toString();

    final source = (_pipeline?['source'] ?? '-').toString();
    final lastUpdated = (_pipeline?['lastUpdated'] ?? '-').toString();
    final summary =
        (_pipeline?['summary'] ?? 'Ingen health-summary ennå.').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: _text),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Campaign push pipeline',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _refreshStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh status',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Live data leses fra backend health og recentCampaigns.',
            style: TextStyle(
              color: _textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip('Source', source),
              _infoChip('Scanned', scanned),
              _infoChip('Queued', queued),
              _infoChip('Dispatched', dispatched),
              _infoChip('Sist oppdatert', lastUpdated),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend summary',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: const TextStyle(
                    color: _textSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_inspectorText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                _inspectorText!,
                style: const TextStyle(
                  color: _textSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Recent campaigns',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (_recentCampaigns.isEmpty)
            const Text(
              'Ingen recent campaigns ennå.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._recentCampaigns.take(5).map((campaign) {
              final title = campaign['title']?.toString() ?? '-';
              final multiplierValue = (campaign['multiplier'] is num)
                  ? (campaign['multiplier'] as num).toDouble()
                  : double.tryParse('${campaign['multiplier'] ?? ''}') ?? 0;
              final multiplier = campaign['multiplier']?.toString() ?? '-';
              final score = campaign['score']?.toString() ?? '-';
              final shouldNotify = campaign['shouldNotify'] == true;
              final reason = campaign['reason']?.toString() ?? '-';

              final isHighBonus = multiplierValue >= 2.0;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isHighBonus)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Text(
                              '🔥 Høy bonus',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: shouldNotify
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: shouldNotify
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            shouldNotify ? 'SEND' : 'SKIP',
                            style: TextStyle(
                              color: shouldNotify
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip('Multiplier', multiplier),
                        _infoChip('Score', score),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
DART

echo
echo "=== Sjekk at ny versjon faktisk ligger i fila ==="
grep -n "Recent campaigns\|Høy bonus\|recentCampaigns" "$FILE"

echo
flutter analyze
echo "✅ 816 ferdig"
