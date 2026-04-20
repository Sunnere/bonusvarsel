#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_778.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) sikre state-felt
state_anchor = "  bool _loadingHealth = false;\n"
state_insert = """  bool _loadingHealth = false;
  Map<String, dynamic>? _systemHealth;
"""
if "Map<String, dynamic>? _systemHealth;" not in text:
    if state_anchor not in text:
        raise SystemExit("❌ Fant ikke anker for _systemHealth")
    text = text.replace(state_anchor, state_insert, 1)

# 2) sikre at _loadSystemHealth lagrer state
old1 = """      setState(() {
        _loadingHealth = false;
      });"""
new1 = """      setState(() {
        _systemHealth = {
          'health': health,
          'feed': feed,
          'notifications': notifications,
          'loadedAt': DateTime.now().toIso8601String(),
        };
        _loadingHealth = false;
      });"""
if old1 in text and "'health': health" not in text:
    text = text.replace(old1, new1, 1)

# fallback hvis metoden har litt annen form
old2 = """      setState(() {
        _loadingHealth = false;
      });
    } catch (e) {"""
new2 = """      setState(() {
        _systemHealth = {
          'health': health,
          'feed': feed,
          'notifications': notifications,
          'loadedAt': DateTime.now().toIso8601String(),
        };
        _loadingHealth = false;
      });
    } catch (e) {"""
if old2 in text and "'health': health" not in text:
    text = text.replace(old2, new2, 1)

# 3) legg inn system health card-metode hvis den mangler
if "Widget _systemHealthPanel()" not in text:
    marker = "  Widget _alertSimulationHistoryCard() {"
    method = """
  Widget _systemHealthPanel() {
    final health = _systemHealth?['health'] as Map<String, dynamic>?;
    final feed = _systemHealth?['feed'];
    final notifications = _systemHealth?['notifications'];
    final pipeline = health?['pipeline'] is Map<String, dynamic>
        ? health?['pipeline'] as Map<String, dynamic>
        : (health?['pipeline'] is Map
            ? Map<String, dynamic>.from(health?['pipeline'] as Map)
            : null);

    final apiUp = health?['ok'] == true || health?['api'] == 'up';
    final version = health?['version']?.toString() ?? '-';
    final devRoutesEnabled = health?['devRoutesEnabled']?.toString() ?? '-';
    final source = pipeline?['source']?.toString() ?? '-';
    final lastSimulationId = pipeline?['lastSimulationId']?.toString() ?? '-';

    int notificationCount = 0;
    if (notifications is List) {
      notificationCount = notifications.length;
    } else if (notifications is Map && notifications['count'] is num) {
      notificationCount = (notifications['count'] as num).toInt();
    }

    int feedCount = 0;
    if (feed is List) {
      feedCount = feed.length;
    } else if (feed is Map && feed['count'] is num) {
      feedCount = (feed['count'] as num).toInt();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System health',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingHealth)
            const Text(
              'Laster system health...',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('API', apiUp ? 'up' : 'down'),
                _metricChip('Version', version),
                _metricChip('Dev routes', devRoutesEnabled),
                _metricChip('Pipeline source', source),
                _metricChip('Feed count', '$feedCount'),
                _metricChip('Notifications', '$notificationCount'),
                _metricChip('Last sim', lastSimulationId),
                _metricChip(
                  'Loaded at',
                  _systemHealth?['loadedAt']?.toString() ?? '-',
                ),
              ],
            ),
        ],
      ),
    );
  }

"""
    if marker not in text:
        raise SystemExit("❌ Fant ikke anker for _systemHealthPanel()")
    text = text.replace(marker, method + marker, 1)

# 4) koble card inn i build hvis det ikke allerede finnes
build_anchor = "          // AI_ANCHOR: DEV_HUB_BUILD_SYSTEM_HEALTH\n"
build_insert = """          // AI_ANCHOR: DEV_HUB_BUILD_SYSTEM_HEALTH
          _systemHealthPanel(),
          const SizedBox(height: 16),
"""
if build_anchor in text and "_systemHealthPanel()," not in text[text.index(build_anchor):text.index(build_anchor)+200]:
    text = text.replace(build_anchor, build_insert, 1)

p.write_text(text)
print("✅ La inn ekte system health-kort i Dev Hub")
PY

flutter analyze
echo "✅ 778 ferdig"
