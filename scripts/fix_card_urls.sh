#!/bin/bash
cp lib/pages/cards_page.dart lib/pages/cards_page.dart.bak2

sed -i '' \
  "s|url: 'https://www.saseurobonuscard.no',|url: 'https://www.americanexpress.com/no/',|" \
  lib/pages/cards_page.dart

# Nå er alle 3 SAS-kort satt til Amex-URL, fiks Mastercard og Visa separat
# Vi må gjøre det manuelt siden de er like — erstatt fil direkte

cat > /tmp/card_urls_patch.py << 'PYTHON'
import re

with open('lib/pages/cards_page.dart', 'r') as f:
    content = f.read()

# Erstatt korrekte URLer per kort
replacements = [
    ('sas_amex', 'https://www.americanexpress.com/no/'),
    ('sas_mc', 'https://www.sbanken.no/produkter/kredittkort/sas-eurobonus-mastercard/'),
    ('sas_visa', 'https://www.dnb.no/privat/kort/kredittkort/sas-eurobonus-visa.html'),
    ('trumf_visa', 'https://www.trumf.no/trumf-visa'),
    ('trumf_mc', 'https://www.trumf.no'),
]

for card_id, url in replacements:
    # Finn blokken for dette kortet og erstatt URL
    pattern = rf"(id: '{card_id}'.*?url: ')[^']*(')"
    replacement = rf"\g<1>{url}\g<2>"
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/pages/cards_page.dart', 'w') as f:
    f.write(content)

print("URLer oppdatert:")
for card_id, url in replacements:
    print(f"  {card_id}: {url}")
PYTHON

python3 /tmp/card_urls_patch.py
echo "✅ Ferdig"
