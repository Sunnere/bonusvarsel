#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_654_luxury_upgrade_ad_section"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

old = """                    const SizedBox(height: 14),
                    FutureBuilder<List<AdSlot>>(
                      future: AdService.instance.pickAds(
                        placement: 'elite_top_cards',
                        count: 1,
                      ),
                      builder: (context, snap) {
                        final ads = snap.data ?? const <AdSlot>[];
                        if (ads.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: AdSlotCard(
                            slot: ads.first,
                            placement: 'elite_top_cards',
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),"""

new = """                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B),
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.40),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selected == 'Elite'
                                          ? 'Utvalgt for Elite'
                                          : 'Utvalgt for Premium',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selected == 'Elite'
                                          ? 'Et relevant kort eller tilbud for maksimal poengverdi.'
                                          : 'Et relevant kort eller tilbud som løfter verdien av medlemskapet.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.78),
                                        fontSize: 12.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: FutureBuilder<List<AdSlot>>(
                              future: AdService.instance.pickAds(
                                placement: 'elite_top_cards',
                                count: 1,
                              ),
                              builder: (context, snap) {
                                final ads = snap.data ?? const <AdSlot>[];
                                if (ads.isEmpty) return const SizedBox.shrink();

                                return AdSlotCard(
                                  slot: ads.first,
                                  placement: 'elite_top_cards',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),"""

if old not in text:
    print("❌ Fant ikke eksisterende premium-annonseblokk. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old, new, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Gjorde premium/elite-annonsen mer luksuspreget")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
