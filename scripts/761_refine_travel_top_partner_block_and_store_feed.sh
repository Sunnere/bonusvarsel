#!/usr/bin/env bash
set -euo pipefail

echo "==> 761_refine_travel_top_partner_block_and_store_feed"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_761")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

def find_matching_paren(src: str, open_idx: int) -> int:
    depth = 0
    in_single = False
    in_double = False
    i = open_idx
    while i < len(src):
        ch = src[i]
        prev = src[i - 1] if i > 0 else ""
        if ch == "'" and not in_double and prev != "\\":
            in_single = not in_single
        elif ch == '"' and not in_single and prev != "\\":
            in_double = not in_double
        elif not in_single and not in_double:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1

def replace_card_by_title(src: str, title: str, replacement: str) -> str:
    title_idx = src.find(f"'{title}'")
    if title_idx == -1:
        raise ValueError(f"Fant ikke tittel: {title}")

    card_start = src.rfind("Card(", 0, title_idx)
    if card_start == -1:
        raise ValueError(f"Fant ikke Card( for: {title}")

    open_idx = src.find("(", card_start)
    close_idx = find_matching_paren(src, open_idx)
    if close_idx == -1:
        raise ValueError(f"Fant ikke slutt på Card( for: {title}")

    end_idx = close_idx + 1
    while end_idx < len(src) and src[end_idx] in " \t":
        end_idx += 1
    if end_idx < len(src) and src[end_idx] == ",":
        end_idx += 1

    return src[:card_start] + replacement + src[end_idx:]

partner_block = """
              Card(
                color: const Color(0xFF0F2C33),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonuspartnere i planen din',
                        style: _travelSectionTitleStyle(context).copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inspirert av følelsen fra SAS og Trumf-universet, med tydelig bonusfokus i reiseplanleggingen.',
                        style: _travelSectionBodyStyle(context).copyWith(
                          color: Colors.white.withOpacity(0.88),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          _TravelBrandPill(
                            label: 'SAS EuroBonus',
                            textColor: Color(0xFF1D3E8A),
                          ),
                          _TravelBrandPill(
                            label: 'Trumf',
                            textColor: Color(0xFF3C7A2A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF245B88),
                              Color(0xFF4FC3D9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Slik tenker planen',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '1. Se hva familien trenger\\n'
                              '2. Finn hvilke butikktyper som passer\\n'
                              '3. Estimer poeng via SAS EuroBonus og Trumf-lignende kjøpsflyt',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
"""

store_feed_block = """
              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.travel_explore, color: Color(0xFF0F6B73)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Butikkforslag fra SAS / Trumf-inspirert feed',
                            style: _travelSectionTitleStyle(context).copyWith(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Oppdater butikkforslag',
                          onPressed: _refreshTripFeedSuggestions,
                          icon: const Icon(Icons.refresh, color: Color(0xFF7B8D97)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Live forslag med fallback når feed ikke gir direkte treff.',
                      style: _travelSectionBodyStyle(context),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<_TravelOfferSuggestion>>(
                      future: _tripFeedSuggestionsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final items = snap.data ?? const <_TravelOfferSuggestion>[];

                        if (items.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ingen direkte treff akkurat nå. Fallback vises.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF10252B),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              for (final store in storeSuggestions.take(4)) ...[
                                _TravelStoreFallbackCard(
                                  title: store.title,
                                  subtitle: 'Fallback fra familietur-planlegger',
                                  description: store.why,
                                  badge: store.pointsLabel,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fant ${items.length} relevante forslag',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10252B),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            for (final item in items.take(4)) ...[
                              _TravelStoreFallbackCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                description: (item.description ?? '').isNotEmpty
                                    ? item.description!
                                    : 'Relevant butikkategori for familiens tur.',
                                badge: 'Score ${item.score}',
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
"""

helpers = r"""
class _TravelBrandPill extends StatelessWidget {
  final String label;
  final Color textColor;

  const _TravelBrandPill({
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff, size: 22, color: Color(0xFF0F6B73)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelStoreFallbackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String badge;

  const _TravelStoreFallbackCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF10252B),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF243940),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2F444B),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Color(0xFF1E4B59),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

try:
    text = replace_card_by_title(text, "Slik tenker planen", partner_block)
    text = replace_card_by_title(text, "Butikkforslag fra SAS / Trumf-inspirert feed", store_feed_block)
except ValueError as e:
    print(f"ERROR: {e}")
    raise SystemExit(1)

if "_TravelBrandPill extends StatelessWidget" not in text:
    anchor = "class _StoreSuggestionCard extends StatelessWidget {"
    if anchor in text:
        text = text.replace(anchor, helpers + "\n" + anchor, 1)
    else:
        text += "\n\n" + helpers + "\n"

# litt tydeligere hero-tekst uten å endre hele heroen
text = text.replace(
    "Se hva du mangler av poeng før du bestiller",
    "Se hva du mangler av poeng før du bestiller"
)
text = text.replace(
    "Text(\n                              '✈ Planlegg reisen smartere'",
    "Text(\n                              '✈ Planlegg reisen smartere'"
)

if text == original:
    print("Ingen endringer ble gjort.")
    raise SystemExit(1)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 761 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
