#!/usr/bin/env bash
set -euo pipefail

echo "==> 818_fix_premium_appstore_blockers"

FILE="lib/pages/premium_page.dart"

python3 <<'PY'
from pathlib import Path
import shutil, datetime

p = Path("lib/pages/premium_page.dart")
text = p.read_text()
orig = text

bak = p.with_name(p.name + ".bak_818_" + datetime.datetime.now().strftime("%H%M%S"))
shutil.copy2(p, bak)
print("Backup:", bak)

# 1. FIX checkout → ekstern side (ikke fake flow)
text = text.replace(
"""Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const CheckoutPage()),
);""",
"""await launchUrl(
  Uri.parse('https://www.bonusvarsel.no'),
  mode: LaunchMode.externalApplication,
);"""
)

# 2. LEGG INN subscription info banner
if "auto-renewable subscription" not in text:
    insert_after = "child: Column("
    info = """
            const SizedBox(height: 12),
            Text(
              'Dette er et auto-fornybart abonnement. Betaling skjer via din Apple-ID. '
              'Abonnementet fornyes automatisk med mindre det kanselleres minst 24 timer før slutten av perioden.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
"""
    text = text.replace(insert_after, insert_after + info, 1)

# 3. LEGG INN Terms + Privacy knapper nederst
if "Privacy Policy" not in text:
    footer = """
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await launchUrl(Uri.parse('https://www.bonusvarsel.no/privacy'));
                          },
                          child: const Text('Privacy Policy'),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            await launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'));
                          },
                          child: const Text('Terms of Use'),
                        ),
                      ],
                    ),
"""
    text = text.replace(
        "FilledButton(",
        footer + "\n                          FilledButton(",
        1
    )

if text == orig:
    print("⚠️ Ingen endring gjort")
else:
    p.write_text(text)
    print("✅ 818 ferdig")
PY

echo
echo "Kjør:"
echo "flutter analyze"
echo "flutter run -d macos"
