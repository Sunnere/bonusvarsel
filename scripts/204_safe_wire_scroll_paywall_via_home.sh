#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

for FILE in lib/pages/home_page.dart; do
  if [ ! -f "$FILE" ]; then
    echo "Fant ikke $FILE"
    exit 1
  fi
  cp "$FILE" "${FILE}.bak.${STAMP}"
  echo "Backup laget: ${FILE}.bak.${STAMP}"
done

mkdir -p lib/services
mkdir -p lib/widgets

cat > lib/services/paywall_trigger_service.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/premium_page.dart';
import '../widgets/premium_paywall_sheet.dart';

class PaywallTriggerService {
  static const _scrollDepthSeenKey = 'paywall_scroll_depth_seen_v1';
  static const _paywallShownCountKey = 'paywall_shown_count_v1';
  static const _lastPaywallSourceKey = 'paywall_last_source_v1';

  static Future<void> markScrollDepthSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scrollDepthSeenKey, true);
    await prefs.setString(_lastPaywallSourceKey, 'scroll_depth');
  }

  static Future<bool> hasSeenScrollDepth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_scrollDepthSeenKey) ?? false;
  }

  static Future<void> markPaywallShown(String source) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_paywallShownCountKey) ?? 0;
    await prefs.setInt(_paywallShownCountKey, count + 1);
    await prefs.setString(_lastPaywallSourceKey, source);
  }

  static Future<int> paywallShownCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_paywallShownCountKey) ?? 0;
  }

  static Future<String?> lastSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPaywallSourceKey);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scrollDepthSeenKey);
    await prefs.remove(_paywallShownCountKey);
    await prefs.remove(_lastPaywallSourceKey);
  }

  static Future<void> showPaywall(
    BuildContext context, {
    required String source,
    String title = 'Få mer ut av bonusen',
    String subtitle =
        'Typisk +1 500–4 000 ekstra poeng per måned med bedre oversikt, boosts og høyere rater.',
  }) async {
    await markPaywallShown(source);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PremiumPaywallSheet(
        source: source,
        title: title,
        subtitle: subtitle,
        onPrimary: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremiumPage()),
          );
        },
      ),
    );
  }
}
DART

cat > lib/widgets/premium_paywall_sheet.dart <<'DART'
import 'package:flutter/material.dart';

class PremiumPaywallSheet extends StatelessWidget {
  final String source;
  final String title;
  final String subtitle;
  final VoidCallback onPrimary;

  const PremiumPaywallSheet({
    super.key,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0E1C31);
    const card = Color(0xFF152742);
    const blue = Color(0xFF60A5FA);
    const green = Color(0xFF22C55E);
    const gold = Color(0xFFD4AF37);
    const elite = Color(0xFF7C5CFF);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold.withValues(alpha: 0.28)),
                      ),
                      child: const Icon(Icons.workspace_premium, color: gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _pill('Kilde: $source', blue),
                const SizedBox(height: 16),
                _featureCard(
                  title: 'Premium',
                  accent: green,
                  bullets: const [
                    'Alle SAS Shopping-butikker',
                    'Høyere poengrate',
                    'Boost og kampanjer',
                    'Smartere valg',
                  ],
                  price: '49 kr/mnd',
                  note: 'Typisk +1 500–4 000 poeng/mnd',
                ),
                const SizedBox(height: 12),
                _featureCard(
                  title: 'Elite',
                  accent: elite,
                  bullets: const [
                    'Alt i Premium',
                    'Flere programmer',
                    'Enda flere boosts',
                    'Mer prioritert oversikt',
                  ],
                  price: '89 kr/mnd',
                  note: 'Opptil 8 000+ poeng/mnd',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onPrimary,
                    child: const Text(
                      'Prøv Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Senere',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _pill(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget _featureCard({
    required String title,
    required Color accent,
    required List<String> bullets,
    required String price,
    required String note,
  }) {
    const card = Color(0xFF152742);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DART

cat > lib/widgets/paywall_scroll_wrapper.dart <<'DART'
import 'package:flutter/material.dart';

import '../services/paywall_trigger_service.dart';

class PaywallScrollWrapper extends StatefulWidget {
  final Widget child;

  const PaywallScrollWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PaywallScrollWrapper> createState() => _PaywallScrollWrapperState();
}

class _PaywallScrollWrapperState extends State<PaywallScrollWrapper> {
  final ScrollController _controller = ScrollController();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() async {
      if (_controller.offset > 600 && !_triggered) {
        _triggered = true;

        final seen = await PaywallTriggerService.hasSeenScrollDepth();

        if (!seen && context.mounted) {
          await PaywallTriggerService.markScrollDepthSeen();

          await PaywallTriggerService.showPaywall(
            context,
            source: 'shopping_scroll',
            title: 'Få mer ut av bonusen',
            subtitle:
                'Premium gir høyere poengrate og smartere valg – så du tjener mer per kjøp.',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
  }
}
DART

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/home_page.dart")
src = path.read_text(encoding="utf-8")
original = src

import_line = "import '../widgets/paywall_scroll_wrapper.dart';"
if import_line not in src:
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line)
    src = "\n".join(lines) + ("\n" if original.endswith("\n") else "")

src = src.replace(
    "    EbShoppingPage(),",
    "    PaywallScrollWrapper(child: EbShoppingPage()),",
)

if src == original:
    print("Ingen endring nødvendig i home_page.dart")
else:
    path.write_text(src, encoding="utf-8")
    print("Oppdaterte lib/pages/home_page.dart")
PY

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
