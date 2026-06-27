#!/usr/bin/env python3
import os

base = os.path.expanduser('~/bonusvarsel/lib')

# ── 1. WhatsNewService ────────────────────────────────────────────────────────
service = """import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class WhatsNewService {
  static const _kLastSeenVersion = 'whats_new_last_seen_version';

  // Definer hva som er nytt per versjon
  static const Map<String, List<Map<String, String>>> _changelog = {
    '1.0.1': [
      {'icon': '✈️', 'title': 'Ny Reise-side', 'desc': 'Full poengkalkulator for hele familien med riktige SAS-priser.'},
      {'icon': '🤖', 'title': 'AI-slagplan', 'desc': 'Personlig plan for å nå drømmereisen med bonuspoeng.'},
      {'icon': '💳', 'title': 'Velg flere kort', 'desc': 'Amex + Trumf Visa gir dobbel opptjening – nå støttet.'},
      {'icon': '🎟️', 'title': 'Companion Ticket', 'desc': 'Se når én voksen flyr gratis med Amex ved 150 000 kr/år.'},
      {'icon': '🌍', 'title': 'Butikker i appen', 'desc': 'SAS og Trumf-butikker åpnes nå direkte i Bonusvarsel.'},
    ],
  };

  static Future<bool> shouldShow(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_kLastSeenVersion) ?? '';
    return lastSeen != currentVersion && _changelog.containsKey(currentVersion);
  }

  static Future<void> markSeen(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSeenVersion, version);
  }

  static List<Map<String, String>> getChanges(String version) {
    return _changelog[version] ?? [];
  }

  static Future<void> showIfNeeded(BuildContext context, String version) async {
    if (!await shouldShow(version)) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhatsNewModal(version: version),
    );
  }
}

class WhatsNewModal extends StatelessWidget {
  final String version;
  const WhatsNewModal({super.key, required this.version});

  static const _bg      = Color(0xFF06111F);
  static const _surface = Color(0xFF0B1728);
  static const _border  = Color(0xFF2F435C);
  static const _primary = Color(0xFF60A5FA);
  static const _text    = Color(0xFFF8FAFC);
  static const _muted   = Color(0xFFCBD5E1);
  static const _gold    = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final changes = WhatsNewService.getChanges(version);
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('✨', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Nytt i Bonusvarsel',
                  style: TextStyle(color: _text,
                    fontWeight: FontWeight.w900, fontSize: 18)),
                Text('Versjon $version',
                  style: const TextStyle(color: _muted, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 20),

            // Endringer
            ...changes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Center(child: Text(c['icon']!,
                    style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['title']!,
                      style: const TextStyle(color: _text,
                        fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(c['desc']!,
                      style: const TextStyle(color: _muted,
                        fontSize: 12, height: 1.4)),
                  ],
                )),
              ]),
            )),

            const SizedBox(height: 8),

            // Knapp
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await WhatsNewService.markSeen(version);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Forstått! 👍',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""

service_path = os.path.join(base, 'services', 'whats_new_service.dart')
with open(service_path, 'w') as f:
    f.write(service)
print(f"✅ {service_path}")

# ── 2. Patch home_page.dart til å vise modal ──────────────────────────────────
home_path = os.path.join(base, 'pages', 'home_page.dart')
with open(home_path, 'r') as f:
    home = f.read()
with open(home_path + '.bak_whatsnew', 'w') as f:
    f.write(home)

# Legg til import
if 'whats_new_service' not in home:
    home = home.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:package_info_plus/package_info_plus.dart';\nimport '../services/whats_new_service.dart';")

# Legg til _checkWhatsNew i initState
old_init = "  @override\n  void initState() {\n    super.initState();\n    final idx = widget.initialIndex;\n    _index = (idx >= 0 && idx < _pages.length) ? idx : 0;\n  }"
new_init = """  @override
  void initState() {
    super.initState();
    final idx = widget.initialIndex;
    _index = (idx >= 0 && idx < _pages.length) ? idx : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWhatsNew());
  }

  Future<void> _checkWhatsNew() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      await WhatsNewService.showIfNeeded(context, info.version);
    } catch (_) {}
  }"""

if old_init in home:
    home = home.replace(old_init, new_init)
    print("✅ home_page: _checkWhatsNew lagt til")
else:
    print("❌ Fant ikke initState i home_page — legg til manuelt")

with open(home_path, 'w') as f:
    f.write(home)

print()
print("Husk å legge til package_info_plus:")
print("  flutter pub add package_info_plus")
print()
print("Legg til ny versjon i _changelog i whats_new_service.dart ved neste update!")
