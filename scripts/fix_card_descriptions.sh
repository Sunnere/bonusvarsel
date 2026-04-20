#!/bin/bash
python3 << 'PYTHON'
with open('lib/pages/cards_page.dart', 'r') as f:
    content = f.read()

# Oppdater beskrivelser
replacements = [
    (
        "description: 'Beste SAS-kort. 20 poeng per 100 kr på alle kjøp.',",
        "description: 'Beste SAS-kort. 20 poeng per 100 kr på alle kjøp. Søk direkte hos American Express Norge.',"
    ),
    (
        "description: '15 poeng per 100 kr. Bred aksept der Amex ikke fungerer.',",
        "description: 'SAS EuroBonus Mastercard via DNB. Gå til Mine kort i DNB-appen → trykk Mastercard → Oppgrader → legg inn EuroBonus-nummer. 15 poeng per 100 kr.',"
    ),
    (
        "description: '10 poeng per 100 kr. God aksept over hele verden.',",
        "description: 'SAS EuroBonus Visa via Lunar. Last ned Lunar-appen og søk om SAS EuroBonus Visa direkte der. 10 poeng per 100 kr.',"
    ),
    (
        "description: '10 poeng per 100 kr. Best for Trumf-opptjening i NorgesGruppen.',",
        "description: 'Trumf Visa via Trumf Pay. Legg til Visa-kortet ditt i Trumf-appen under Trumf Pay for å koble opptjening. 10 poeng per 100 kr.',"
    ),
    (
        "description: '8 poeng per 100 kr på alle kjøp via Trumf.',",
        "description: 'Trumf sitt eget Mastercard. Søk på trumf.no. 8 poeng per 100 kr på alle kjøp. Best kombinert med Trumf-medlemskap.',"
    ),
]

for old, new in replacements:
    content = content.replace(old, new)

with open('lib/pages/cards_page.dart', 'w') as f:
    f.write(content)

print("✅ Beskrivelser oppdatert:")
print("  SAS Amex: American Express Norge")
print("  SAS Mastercard: DNB-appen prosess forklart")
print("  SAS Visa: Lunar-appen forklart")
print("  Trumf Visa: Trumf Pay forklart")
print("  Trumf Mastercard: trumf.no forklart")
PYTHON
echo "✅ Ferdig"
