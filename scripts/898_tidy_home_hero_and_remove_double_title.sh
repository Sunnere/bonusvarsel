#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_898.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# 1) AppBar-tittel: fjern dobbel "EuroBonus Shopping"
old_appbar = """          child: const Text(
            'EuroBonus Shopping',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
"""
new_appbar = """          child: const Text(
            'Shopping',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
"""
if old_appbar in text:
    text = text.replace(old_appbar, new_appbar, 1)

# 2) Hero-tittel + undertittel
old_title = """                Text(
                  'EuroBonus Shopping',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.2,
                      ),
                ),
"""
new_title = """                Text(
                  'Tjen flere poeng på shopping',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.2,
                      ),
                ),
"""
if old_title in text:
    text = text.replace(old_title, new_title, 1)

old_sub = """                Text(
                  'Finn butikker, kampanjer og poengboost',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w700,
                      ),
                ),
"""
new_sub = """                Text(
                  'Velg nivå og se hva som gir mest verdi for deg',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w700,
                      ),
                ),
"""
if old_sub in text:
    text = text.replace(old_sub, new_sub, 1)

# 3) Piller -> CTA-knapper
old_wrap = """                const Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _HeaderPill(icon: Icons.verified_user, text: 'Trygt'),
                    _HeaderPill(icon: Icons.workspace_premium, text: 'Premium'),
                    _HeaderPill(icon: Icons.emoji_events, text: 'Elite'),
                  ],
                ),
"""
new_wrap = """                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showFreeVsPremium(context),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Se gratis'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Se Premium'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Se Elite'),
                    ),
                  ],
                ),
"""
if old_wrap in text:
    text = text.replace(old_wrap, new_wrap, 1)

# 4) Sammenligningslenke litt tydeligere
text = text.replace("'Gratis vs Premium'", "'Sammenlign nivåer'")

if text == orig:
    raise SystemExit("❌ Fant ingen kjente hero-mønstre å endre")

p.write_text(text)
print("✅ Hero ryddet og gjort mer CTA-orientert")
PY

flutter analyze
echo "✅ 898 ferdig"
