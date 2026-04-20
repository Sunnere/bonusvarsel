#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_836.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

# 1) Utvid refresh til å lese url/score/type videre uten endring i struktur
old = """      final notificationsRoot = pipeline['notifications'];
      final notifications = notificationsRoot is Map
          ? (notificationsRoot['items'] is List
              ? (notificationsRoot['items'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[])
          : <Map<String, dynamic>>[];
"""
new = """      final notificationsRoot = pipeline['notifications'];
      final notifications = notificationsRoot is Map
          ? (notificationsRoot['items'] is List
              ? (notificationsRoot['items'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[])
          : <Map<String, dynamic>>[];
"""
if old in text:
    text = text.replace(old, new, 1)

# 2) Gjør Activated-seksjonen tydeligere
old2 = """          const Text(
            'Activated notifications',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
"""
new2 = """          Text(
            'Activated notifications (${_activatedNotifications.length})',
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
"""
if old2 not in text:
    raise SystemExit("❌ Fant ikke Activated notifications-overskriften")
text = text.replace(old2, new2, 1)

# 3) Bytt notification-card til mer synlig variant
old3 = """            ..._activatedNotifications.take(2).map((item) {
              final title = item['title']?.toString() ?? '-';
              final body = item['body']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';

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
                            border: Border.all(color: const Color(0xFF86EFAC)),
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
                        _infoChip('Rate', rate),
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
                  ],
                ),
              );
            }),
"""
new3 = """            ..._activatedNotifications.take(5).map((item) {
              final title = item['title']?.toString() ?? '-';
              final body = item['body']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';
              final activatedAt = item['activatedAt']?.toString() ?? '-';
              final url = item['url']?.toString() ?? '';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
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
                            border: Border.all(color: const Color(0xFF86EFAC)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            '${rate}x',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
                        _infoChip('Activated', activatedAt),
                      ],
                    ),
                    if (url.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SelectableText(
                        url,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
"""
if old3 not in text:
    raise SystemExit("❌ Fant ikke activated notification-card-blokken")
text = text.replace(old3, new3, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")
p.write_text(text)
print("✅ Gjorde Activated notifications tydelig i UI")
PY

flutter analyze
echo "✅ 836 ferdig"
