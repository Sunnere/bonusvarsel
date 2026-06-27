#!/usr/bin/env python3
import os

# ── 1. Lag BonusWebViewPage ──────────────────────────────────────────────────
webview_path = os.path.expanduser('~/bonusvarsel/lib/pages/bonus_webview_page.dart')

dart = """import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BonusWebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final String? subtitle;
  final Color accentColor;

  const BonusWebViewPage({
    super.key,
    required this.url,
    required this.title,
    this.subtitle,
    this.accentColor = const Color(0xFF60A5FA),
  });

  @override
  State<BonusWebViewPage> createState() => _BonusWebViewPageState();
}

class _BonusWebViewPageState extends State<BonusWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  int _progress = 0;
  String _currentUrl = '';

  static const _bg = Color(0xFF06111F);
  static const _surface = Color(0xFF0B1728);
  static const _border = Color(0xFF2F435C);
  static const _text = Color(0xFFF8FAFC);
  static const _textMuted = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() { _loading = true; _currentUrl = url; }),
        onPageFinished: (url) => setState(() { _loading = false; _currentUrl = url; }),
        onProgress: (p) => setState(() => _progress = p),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
              style: const TextStyle(color: _text,
                fontWeight: FontWeight.w900, fontSize: 15)),
            if (widget.subtitle != null)
              Text(widget.subtitle!,
                style: const TextStyle(color: _textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          // Tilbake-knapp i nettleser
          IconButton(
            icon: const Icon(Icons.chevron_left, color: _text),
            onPressed: () async {
              if (await _controller.canGoBack()) _controller.goBack();
            },
          ),
          // Frem-knapp
          IconButton(
            icon: const Icon(Icons.chevron_right, color: _text),
            onPressed: () async {
              if (await _controller.canGoForward()) _controller.goForward();
            },
          ),
          // Reload
          IconButton(
            icon: const Icon(Icons.refresh, color: _text, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _loading ? PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation(widget.accentColor),
          ),
        ) : PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Info-banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: widget.accentColor.withValues(alpha: 0.1),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                color: widget.accentColor, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Klikk på en butikk – bonus registreres automatisk når du handler',
                style: TextStyle(color: widget.accentColor,
                  fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
"""

with open(webview_path, 'w') as f:
    f.write(dart)
print("✅ bonus_webview_page.dart opprettet")

# ── 2. Patch eb_shopping_page: import + åpne WebView i stedet for ekstern URL ──
shop_path = os.path.expanduser('~/bonusvarsel/lib/pages/eb_shopping_page.dart')
with open(shop_path, 'r') as f:
    shop = f.read()
with open(shop_path + '.bak_webview', 'w') as f:
    f.write(shop)

# Legg til import
shop = shop.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'bonus_webview_page.dart';",
)

# Erstatt _open-metoden med en som åpner WebView for bonus-sider
old_open = """  void _open(String url) => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );"""

new_open = """  void _open(String url, {String? title, String? subtitle, Color? accent}) {
    final isSas   = url.contains('flysas.com') || url.contains('sas.no');
    final isTrumf = url.contains('trumf');

    if (isSas || isTrumf) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BonusWebViewPage(
          url: url,
          title: isSas ? 'SAS Online Shopping' : 'Trumf Netthandel',
          subtitle: isSas
              ? 'Tjen EuroBonus-poeng på netthandel'
              : 'Tjen Trumf-bonus – overføres til EuroBonus',
          accentColor: isSas
              ? const Color(0xFF60A5FA)
              : const Color(0xFF34D399),
        ),
      ));
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }"""

if old_open in shop:
    shop = shop.replace(old_open, new_open)
    print("✅ _open erstattet med WebView-versjon")
else:
    print("❌ Fant ikke _open-metoden")

with open(shop_path, 'w') as f:
    f.write(shop)

import subprocess
r = subprocess.run(
    ['flutter', 'analyze',
     'lib/pages/bonus_webview_page.dart',
     'lib/pages/eb_shopping_page.dart'],
    capture_output=True, text=True,
    cwd=os.path.expanduser('~/bonusvarsel'))
errors = [l for l in r.stdout.splitlines() if 'error' in l.lower()]
if errors:
    for e in errors[:8]: print(f"  ❌ {e}")
else:
    print("  ✅ Ingen Dart-feil")

print()
print("Kjør: flutter run -d 00008110-001138643E60401E --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
