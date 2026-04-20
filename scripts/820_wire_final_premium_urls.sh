#!/usr/bin/env bash
set -euo pipefail

echo "==> 820_wire_final_premium_urls"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_820")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# URL-konstanter
anchor = "class _PremiumPageState extends State<PremiumPage> {\n"
insert = """class _PremiumPageState extends State<PremiumPage> {
  static const String _subscriptionsUrl =
      'https://www.bonusvarsel.no/abonnementer/';
  static const String _privacyPolicyUrl =
      'https://www.bonusvarsel.no/privacy-policy/';
  static const String _termsUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
"""
if "_subscriptionsUrl" not in text:
    if anchor not in text:
        print("❌ Fant ikke anker for URL-konstanter")
        raise SystemExit(1)
    text = text.replace(anchor, insert, 1)
    print("✅ La inn URL-konstanter")

# Premium checkout -> abonnementsside
old_checkout = """await launchUrl(
  Uri.parse('https://www.bonusvarsel.no'),
  mode: LaunchMode.externalApplication,
);"""
new_checkout = """await launchUrl(
  Uri.parse(_subscriptionsUrl),
  mode: LaunchMode.externalApplication,
);"""
if old_checkout in text:
    text = text.replace(old_checkout, new_checkout, 1)
    print("✅ Premium checkout peker til abonnementssiden")

# Fallback i partner-url -> abonnementsside
if old_checkout in text:
    text = text.replace(old_checkout, new_checkout, 1)
    print("✅ Partner fallback peker til abonnementssiden")

# Privacy Policy-knapp
text = text.replace(
    "await launchUrl(Uri.parse('https://www.bonusvarsel.no/privacy'));",
    "await launchUrl(\n"
    "                            Uri.parse(_privacyPolicyUrl),\n"
    "                            mode: LaunchMode.externalApplication,\n"
    "                          );",
)
text = text.replace(
    "await launchUrl(Uri.parse('https://www.bonusvarsel.no/privacy-policy/'));",
    "await launchUrl(\n"
    "                            Uri.parse(_privacyPolicyUrl),\n"
    "                            mode: LaunchMode.externalApplication,\n"
    "                          );",
)

# Terms of Use-knapp
text = text.replace(
    "await launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'));",
    "await launchUrl(\n"
    "                            Uri.parse(_termsUrl),\n"
    "                            mode: LaunchMode.externalApplication,\n"
    "                          );",
)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 820 ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
