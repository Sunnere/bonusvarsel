#!/usr/bin/env bash
set -euo pipefail

echo "==> 819_set_premium_urls_cleanly"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_819")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) legg inn URL-konstanter én gang, rett under state class
anchor = "class _PremiumPageState extends State<PremiumPage> {\n"
insert = """class _PremiumPageState extends State<PremiumPage> {
  static const String _subscriptionsUrl = 'https://www.bonusvarsel.no/';
  static const String _privacyPolicyUrl = 'https://www.bonusvarsel.no/privacy-policy/';
  static const String _termsUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
"""
if "_privacyPolicyUrl" not in text:
    if anchor not in text:
        print("❌ Fant ikke anker for URL-konstanter")
        raise SystemExit(1)
    text = text.replace(anchor, insert, 1)
    print("✅ La inn URL-konstanter")

# 2) checkout -> abonnementsside-konstant
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
    print("✅ Premium-knapp peker nå til abonnementskonstant")

# 3) partner fallback -> abonnementsside-konstant
old_partner_fallback = """await launchUrl(
  Uri.parse('https://www.bonusvarsel.no'),
  mode: LaunchMode.externalApplication,
);"""
if old_partner_fallback in text:
    text = text.replace(old_partner_fallback, new_checkout, 1)
    print("✅ Fallback peker nå til abonnementskonstant")

# 4) privacy button -> din privacy-side
old_priv = """await launchUrl(Uri.parse('https://www.bonusvarsel.no/privacy'));"""
new_priv = """await launchUrl(
                            Uri.parse(_privacyPolicyUrl),
                            mode: LaunchMode.externalApplication,
                          );"""
if old_priv in text:
    text = text.replace(old_priv, new_priv, 1)
    print("✅ Privacy Policy peker nå til privacy-policy")

# fallback hvis knapp allerede peker et annet sted
text = text.replace(
    "await launchUrl(Uri.parse('https://www.bonusvarsel.no/privacy-policy/'));",
    "await launchUrl(\n                            Uri.parse(_privacyPolicyUrl),\n                            mode: LaunchMode.externalApplication,\n                          );",
)

# 5) terms button -> konstant
text = text.replace(
    "await launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'));",
    "await launchUrl(\n                            Uri.parse(_termsUrl),\n                            mode: LaunchMode.externalApplication,\n                          );",
)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 819 ferdig")
print()
print("Når abonnementssiden er klar, endre bare denne linjen i premium_page.dart:")
print("  static const String _subscriptionsUrl = 'https://www.bonusvarsel.no/abonnementer/';")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
