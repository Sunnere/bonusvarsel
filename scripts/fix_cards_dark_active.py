#!/usr/bin/env python3
path = '/Users/sunnerehelse/bonusvarsel/lib/pages/cards_page.dart'
with open(path, 'r') as f:
    content = f.read()

# SAS-kort activeBg: lys blå → mørk blå
fixes = [
    # SAS amex
    ("id: 'sas_amex', name: 'SAS EuroBonus American Express', network: 'Amex',\n      ratePer100: 20,\n      activeColor: Color(0xFF00447C), activeBg: Color(0xFFDBEAFE), borderColor: Color(0xFF93C5FD),",
     "id: 'sas_amex', name: 'SAS EuroBonus American Express', network: 'Amex',\n      ratePer100: 20,\n      activeColor: Color(0xFF60A5FA), activeBg: Color(0xFF0D2137), borderColor: Color(0xFF1D4ED8),"),
    # SAS mc
    ("id: 'sas_mc', name: 'SAS EuroBonus Mastercard', network: 'Mastercard',\n      ratePer100: 15,\n      activeColor: Color(0xFF1e3a8a), activeBg: Color(0xFFDBEAFE), borderColor: Color(0xFF93C5FD),",
     "id: 'sas_mc', name: 'SAS EuroBonus Mastercard', network: 'Mastercard',\n      ratePer100: 15,\n      activeColor: Color(0xFF60A5FA), activeBg: Color(0xFF0D2137), borderColor: Color(0xFF1D4ED8),"),
    # SAS visa
    ("id: 'sas_visa', name: 'SAS EuroBonus Visa', network: 'Visa',\n      ratePer100: 10,\n      activeColor: Color(0xFF1e3a8a), activeBg: Color(0xFFDBEAFE), borderColor: Color(0xFF93C5FD),",
     "id: 'sas_visa', name: 'SAS EuroBonus Visa', network: 'Visa',\n      ratePer100: 10,\n      activeColor: Color(0xFF60A5FA), activeBg: Color(0xFF0D2137), borderColor: Color(0xFF1D4ED8),"),
    # Trumf visa
    ("id: 'trumf_visa', name: 'Trumf Visa', network: 'Visa',\n      ratePer100: 10,\n      activeColor: Color(0xFF007A3D), activeBg: Color(0xFFD1FAE5), borderColor: Color(0xFF6EE7B7),",
     "id: 'trumf_visa', name: 'Trumf Visa', network: 'Visa',\n      ratePer100: 10,\n      activeColor: Color(0xFF34D399), activeBg: Color(0xFF0D2B1E), borderColor: Color(0xFF065F46),"),
    # Trumf mc
    ("id: 'trumf_mc', name: 'Trumf Mastercard', network: 'Mastercard',\n      ratePer100: 8,\n      activeColor: Color(0xFF007A3D), activeBg: Color(0xFFD1FAE5), borderColor: Color(0xFF6EE7B7),",
     "id: 'trumf_mc', name: 'Trumf Mastercard', network: 'Mastercard',\n      ratePer100: 8,\n      activeColor: Color(0xFF34D399), activeBg: Color(0xFF0D2B1E), borderColor: Color(0xFF065F46),"),
]

ok = 0
for old, new in fixes:
    if old in content:
        content = content.replace(old, new)
        ok += 1
    else:
        print(f"  ⚠️ Ikke funnet: {old[:50]!r}")

# Badge-farger: lys bakgrunn → mørk
content = content.replace(
    'color: card.activeBg,\n                        borderRadius: BorderRadius.circular(999),\n                        border: Border.all(color: card.borderColor)),\n                      child: Text(card.badge!,\n                        style: TextStyle(color: card.activeColor,',
    'color: card.activeColor.withValues(alpha: 0.15),\n                        borderRadius: BorderRadius.circular(999),\n                        border: Border.all(color: card.activeColor.withValues(alpha: 0.4))),\n                      child: Text(card.badge!,\n                        style: TextStyle(color: card.activeColor,')
)

with open(path, 'w') as f:
    f.write(content)
print(f"✅ {ok}/5 kortfarger oppdatert til mørkt tema")
