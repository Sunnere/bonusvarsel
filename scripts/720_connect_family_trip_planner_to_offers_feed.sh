#!/usr/bin/env bash
set -euo pipefail

echo "==> 720_connect_family_trip_planner_to_offers_feed"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re
import os

travel_path = Path("lib/pages/travel_page.dart")
if not travel_path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

repo_candidates = []
for p in Path("lib").rglob("*.dart"):
    try:
        text = p.read_text()
    except Exception:
        continue
    if re.search(r"\bclass\s+OffersFeedRepository\b", text):
        repo_candidates.append((p, text))

if not repo_candidates:
    print("ERROR: Could not find OffersFeedRepository in lib/")
    raise SystemExit(1)

repo_path, repo_text = repo_candidates[0]

preferred_methods = [
    "fetchOffersFeed",
    "getOffersFeed",
    "loadOffersFeed",
    "fetchFeed",
    "loadFeed",
]
method_name = None
for name in preferred_methods:
    if re.search(rf"\b{name}\s*\(", repo_text):
        method_name = name
        break

if method_name is None:
    public_methods = re.findall(r"(?:Future<[^>]+>|Future|Stream<[^>]+>|Stream|[A-Za-z_][A-Za-z0-9_<>,? ]+)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", repo_text)
    public_methods = [m for m in public_methods if not m.startswith("_")]
    if public_methods:
        method_name = public_methods[0]

if method_name is None:
    print("ERROR: Could not determine repository method name.")
    raise SystemExit(1)

relative_import = os.path.relpath(repo_path, travel_path.parent).replace(os.sep, "/")
repo_import = f"import '{relative_import}';"

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = travel_path.with_name(travel_path.name + f".bak_{stamp}_720")
shutil.copy2(travel_path, bak)
print(f"Backup: {bak}")
print(f"Repository: {repo_path}")
print(f"Method    : {method_name}")

text = travel_path.read_text()
original = text

# 1) Ensure repository import exists
if repo_import not in text:
    imports = list(re.finditer(r"^import\s+['\"].*?['\"];\s*$", text, flags=re.MULTILINE))
    if not imports:
        print("ERROR: Could not find import section in travel_page.dart")
        raise SystemExit(1)
    last = imports[-1]
    text = text[:last.end()] + "\n" + repo_import + text[last.end():]

# 2) Insert state field
field_snippet = "  Future<List<_TravelOfferSuggestion>>? _tripFeedSuggestionsFuture;\n"
if "_tripFeedSuggestionsFuture" not in text:
    anchor = "  int _savedSasPoints = 0;\n"
    if anchor not in text:
        print("ERROR: Could not find state field anchor.")
        raise SystemExit(1)
    text = text.replace(anchor, anchor + field_snippet, 1)

# 3) Initialize in initState
init_anchor = "    _loadSavedSasPoints();\n"
if "_tripFeedSuggestionsFuture = _loadTripFeedSuggestions();" not in text:
    if init_anchor not in text:
        print("ERROR: Could not find initState anchor.")
        raise SystemExit(1)
    text = text.replace(
        init_anchor,
        init_anchor + "    _tripFeedSuggestionsFuture = _loadTripFeedSuggestions();\n",
        1,
    )

# 4) Insert methods before build()
methods_block = f"""
  void _refreshTripFeedSuggestions() {{
    setState(() {{
      _tripFeedSuggestionsFuture = _loadTripFeedSuggestions();
    }});
  }}

  Future<List<_TravelOfferSuggestion>> _loadTripFeedSuggestions() async {{
    try {{
      final response = await OffersFeedRepository().{method_name}();
      final items = _extractTripFeedItems(response);
      final keywords = _buildTripFeedKeywords();

      final ranked = <_TravelOfferSuggestion>[];

      for (final item in items) {{
        final map = _feedItemAsMap(item);
        if (map == null || map.isEmpty) continue;

        final score = _scoreTripFeedItem(map, keywords);
        if (score <= 0) continue;

        final suggestion = _mapTripFeedItemToSuggestion(map, score);
        if (suggestion != null) {{
          ranked.add(suggestion);
        }}
      }}

      ranked.sort((a, b) => b.score.compareTo(a.score));

      final deduped = <_TravelOfferSuggestion>[];
      final seen = <String>{{}};
      for (final item in ranked) {{
        final key = (item.title + '|' + item.subtitle).toLowerCase().trim();
        if (seen.add(key)) {{
          deduped.add(item);
        }}
        if (deduped.length >= 6) break;
      }}

      return deduped;
    }} catch (_) {{
      return const <_TravelOfferSuggestion>[];
    }}
  }}

  List<dynamic> _extractTripFeedItems(dynamic response) {{
    if (response == null) return const <dynamic>[];

    try {{
      final items = response.items;
      if (items is List) return items;
    }} catch (_) {{}}

    try {{
      final offers = response.offers;
      if (offers is List) return offers;
    }} catch (_) {{}}

    try {{
      final json = response.toJson();
      if (json is Map<String, dynamic>) {{
        final items = json['items'];
        if (items is List) return items;
        final offers = json['offers'];
        if (offers is List) return offers;
      }}
    }} catch (_) {{}}

    return const <dynamic>[];
  }}

  Map<String, dynamic>? _feedItemAsMap(dynamic item) {{
    if (item is Map<String, dynamic>) return item;
    try {{
      final json = item.toJson();
      if (json is Map<String, dynamic>) return json;
    }} catch (_) {{}}
    return null;
  }}

  Set<String> _buildTripFeedKeywords() {{
    final needs = _buildPackingNeeds();
    final keywords = <String>{{
      _destinationCtrl.text.trim().toLowerCase(),
      _selectedTripType.toLowerCase(),
      _selectedProgram.toLowerCase(),
      'reise',
      'travel',
      'family',
      'familie',
    }};

    for (final need in needs) {{
      keywords.add(need.label.toLowerCase());
      keywords.add(need.category.toLowerCase());
      for (final part in need.storeHint.toLowerCase().split(',')) {{
        final value = part.trim();
        if (value.isNotEmpty) {{
          keywords.add(value);
        }}
      }}
    }}

    final expanded = <String>{{}};
    for (final keyword in keywords) {{
      if (keyword.isEmpty) continue;
      expanded.add(keyword);
      for (final token in keyword.split(RegExp(r'\\s+'))) {{
        final value = token.trim();
        if (value.length >= 3) expanded.add(value);
      }}
    }}

    if (_children > 0) {{
      expanded.addAll(const {{
        'barn',
        'family',
        'familie',
      }});
    }}

    if (_selectedTripType == 'Strandferie') {{
      expanded.addAll(const {{
        'strand',
        'beach',
        'sol',
        'badetøy',
      }});
    }}

    if (_selectedTripType == 'Vintertur') {{
      expanded.addAll(const {{
        'vinter',
        'ski',
        'ull',
      }});
    }}

    return expanded.where((e) => e.trim().length >= 3).toSet();
  }}

  int _scoreTripFeedItem(Map<String, dynamic> map, Set<String> keywords) {{
    final haystack = [
      map['title'],
      map['name'],
      map['headline'],
      map['subtitle'],
      map['description'],
      map['body'],
      map['details'],
      map['merchantName'],
      map['merchant'],
      map['brand'],
      map['category'],
      map['vertical'],
      map['placement'],
      map['type'],
      map['pointsText'],
      map['rewardText'],
      map['bonusText'],
      map['tags'],
      map['channel'],
      map['surface'],
      map['program'],
    ].where((e) => e != null).join(' ').toLowerCase();

    if (haystack.trim().isEmpty) return 0;

    int score = 0;
    for (final keyword in keywords) {{
      if (keyword.isEmpty) continue;
      if (haystack.contains(keyword)) {{
        score += keyword.length > 6 ? 3 : 2;
      }}
    }}

    if (haystack.contains('shopping')) score += 1;
    if (haystack.contains('travel') || haystack.contains('reise')) score += 2;
    if (haystack.contains('bagasje') || haystack.contains('koffert')) score += 3;
    if (haystack.contains('sport')) score += 2;
    if (haystack.contains('apotek') || haystack.contains('helse')) score += 2;
    if (haystack.contains('barn') || haystack.contains('family')) score += 2;

    return score;
  }}

  _TravelOfferSuggestion? _mapTripFeedItemToSuggestion(
    Map<String, dynamic> map,
    int score,
  ) {{
    final title =
        (map['title'] ??
                map['name'] ??
                map['headline'] ??
                map['merchantName'] ??
                map['merchant'] ??
                map['brand'])
            ?.toString()
            .trim();

    if (title == null || title.isEmpty) return null;

    final merchant =
        (map['merchantName'] ?? map['merchant'] ?? map['brand'])
            ?.toString()
            .trim();

    final bonus =
        (map['pointsText'] ?? map['rewardText'] ?? map['bonusText'])
            ?.toString()
            .trim();

    final category =
        (map['category'] ?? map['vertical'] ?? map['type'])
            ?.toString()
            .trim();

    final description =
        (map['subtitle'] ?? map['description'] ?? map['body'] ?? map['details'])
            ?.toString()
            .trim();

    final subtitleParts = <String>[];
    if (merchant != null && merchant.isNotEmpty) subtitleParts.add(merchant);
    if (bonus != null && bonus.isNotEmpty) subtitleParts.add(bonus);
    if (category != null && category.isNotEmpty) subtitleParts.add(category);

    final subtitle = subtitleParts.isNotEmpty
        ? subtitleParts.join(' • ')
        : (description ?? 'Relevans fra offers feed');

    return _TravelOfferSuggestion(
      title: title,
      subtitle: subtitle,
      score: score,
      description: description,
    );
  }}
"""

if "_loadTripFeedSuggestions()" not in text:
    build_anchor = "  @override\n  Widget build(BuildContext context) {\n"
    if build_anchor not in text:
        print("ERROR: Could not find build() anchor.")
        raise SystemExit(1)
    text = text.replace(build_anchor, methods_block + "\n" + build_anchor, 1)

# 5) Insert live feed card after existing store suggestion card
insert_anchor = """              const SizedBox(height: 10),
              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""
live_card = """
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Live butikkforslag fra offers feed',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Oppdater butikkforslag',
                            onPressed: _refreshTripFeedSuggestions,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                  'Fant ingen direkte treff i live feed akkurat nå. Bruk butikktypene over som fallback.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: storeSuggestions
                                      .map(
                                        (store) => Chip(
                                          label: Text(store.title),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              for (final item in items) ...[
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.local_offer_outlined),
                                  title: Text(item.title),
                                  subtitle: Text(item.subtitle),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'score ${item.score}',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ),
                                ),
                                if ((item.description ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item.description!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                const Divider(height: 1),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
"""
if "Live butikkforslag fra offers feed" not in text:
    if insert_anchor not in text:
        print("ERROR: Could not find insertion anchor near TravelValueCard.")
        raise SystemExit(1)
    text = text.replace(insert_anchor, live_card + "\n" + insert_anchor, 1)

# 6) Append helper class if missing
helper_class = """
class _TravelOfferSuggestion {
  final String title;
  final String subtitle;
  final int score;
  final String? description;

  const _TravelOfferSuggestion({
    required this.title,
    required this.subtitle,
    required this.score,
    this.description,
  });
}
"""
if "class _TravelOfferSuggestion" not in text:
    text = text.rstrip() + "\n\n" + helper_class + "\n"

if text == original:
    print("No changes made.")
    raise SystemExit(0)

travel_path.write_text(text)
print(f"Patched: {travel_path}")
PY

echo
echo "✅ 720 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
