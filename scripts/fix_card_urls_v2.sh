#!/bin/bash
cp lib/pages/cards_page.dart lib/pages/cards_page.dart.bak4

python3 << 'PYTHON'
with open('lib/pages/cards_page.dart', 'r') as f:
    content = f.read()

replacements = [
    ('sas_amex',   'https://www.americanexpress.com/no/'),
    ('sas_mc',     'https://www.lunar.app/no/kredittkort/sas-eurobonus'),
    ('sas_visa',   'https://www.lunar.app/no/kredittkort/sas-eurobonus'),
    ('trumf_visa', 'https://www.trumf.no/trumf-kredittkort/trumf-kredittkort-i-trumf-pay'),
    ('trumf_mc',   'https://www.trumf.no'),
]

import re
for card_id, url in replacements:
    pattern = rf"(id: '{card_id}'.*?url: ')[^']*(')"
    replacement = rf"\g<1>{url}\g<2>"
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/pages/cards_page.dart', 'w') as f:
    f.write(content)

print("URLer oppdatert:")
for card_id, url in replacements:
    print(f"  {card_id}: {url}")
PYTHON

echo "✅ Ferdig"
