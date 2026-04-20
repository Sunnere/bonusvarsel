#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_829.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_chips = """          Wrap(
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
"""

new_chips = """          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip('Source', source),
              _infoChip('Scanned', scanned),
              _infoChip('Queued', queued),
              _infoChip('Dispatched', dispatched),
              _infoChip('Activated', _activatedNotifications.length.toString()),
              _infoChip('Sist oppdatert', lastUpdated),
            ],
          ),
"""

if old_chips not in text:
    raise SystemExit("❌ Fant ikke top-chip-blokken")
text = text.replace(old_chips, new_chips, 1)

old_after_summary = """          if (_inspectorText != null) ...[
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
"""

new_after_summary = """          if (_inspectorText != null) ...[
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
            ..._activatedNotifications.take(2).map((item) {
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
          const SizedBox(height: 14),
          const Text(
            'Recent campaigns',
"""

if old_after_summary not in text:
    raise SystemExit("❌ Fant ikke summary→recent-overgangen")
text = text.replace(old_after_summary, new_after_summary, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Flyttet activated notifications høyere opp i panelet")
PY

flutter analyze
echo "✅ 829 ferdig"
