#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_828.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_state = """  Map<String, dynamic>? _pipeline;
  List<Map<String, dynamic>> _recentCampaigns = const [];
  String? _inspectorText;
  bool _loading = false;
"""

new_state = """  Map<String, dynamic>? _pipeline;
  List<Map<String, dynamic>> _recentCampaigns = const [];
  List<Map<String, dynamic>> _activatedNotifications = const [];
  String? _inspectorText;
  bool _loading = false;
"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke state-blokken")
text = text.replace(old_state, new_state, 1)

old_refresh = """      final recent = pipeline['recentCampaigns'];
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
"""

new_refresh = """      final recent = pipeline['recentCampaigns'];
      final campaigns = recent is List
          ? recent
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final notificationsRoot = pipeline['notifications'];
      final notifications = notificationsRoot is Map
          ? (notificationsRoot['items'] is List
              ? (notificationsRoot['items'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[])
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _pipeline = pipeline;
        _recentCampaigns = campaigns;
        _activatedNotifications = notifications;
      });
"""

if old_refresh not in text:
    raise SystemExit("❌ Fant ikke refresh-blokken")
text = text.replace(old_refresh, new_refresh, 1)

insert_after_recent = """          else
            ..._recentCampaigns.take(5).map((campaign) {
              final title = campaign['title']?.toString() ?? '-';
              final multiplierValue = (campaign['multiplier'] is num)
                  ? (campaign['multiplier'] as num).toDouble()
                  : double.tryParse('${campaign['multiplier'] ?? ''}') ?? 0;
              final multiplier = campaign['multiplier']?.toString() ?? '-';
              final score = campaign['score']?.toString() ?? '-';
              final shouldNotify = campaign['shouldNotify'] == true;
              final dispatchEligible = campaign['dispatchEligible'] == true;
              final reason = campaign['reason']?.toString() ?? '-';
              final commissionType = campaign['commissionType']?.toString() ?? '-';

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
                        if (dispatchEligible)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                              ),
                            ),
                            child: const Text(
                              'Klar for dispatch',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
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
                        _infoChip('Type', commissionType),
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
"""

activated_block = """
          const SizedBox(height: 14),
          const Text(
            'Activated notifications',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (_activatedNotifications.isEmpty)
            const Text(
              'Ingen aktiverte notifikasjoner ennå.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._activatedNotifications.take(5).map((item) {
              final title = item['title']?.toString() ?? '-';
              final body = item['body']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final activatedAt = item['activatedAt']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          child: const Text(
                            'Aktivert',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip('Rate', rate),
                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
                        _infoChip('Activated', activatedAt),
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
"""

if insert_after_recent not in text:
    raise SystemExit("❌ Fant ikke recent-campaigns-blokken for å sette inn notifications etterpå")

text = text.replace(insert_after_recent, insert_after_recent + activated_block, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Viser activated notifications i pipeline-panelet")
PY

flutter analyze
echo "✅ 828 ferdig"
