#!/bin/bash
set -e

# ── FIX 1: E-post typo i functions/index.js ──
echo "🔧 Fikser e-post (createTransporter → createTransport)..."
sed -i '' 's/nodemailer.createTransporter/nodemailer.createTransport/g' functions/index.js
cd functions && node -e "require('./index.js')" && echo "✅ index.js OK" && cd ..

# ── FIX 2: Lys _alertCard i alerts_page ──
TARGET="lib/pages/bonusvarsel_alerts_page.dart"
cp "$TARGET" "$TARGET.bak_alertcard_$(date +%Y%m%d_%H%M%S)"

python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

# Bytt lyse farger til mørke i _alertCard
replacements = [
    ('color:isTop?const Color(0xFFECFDF5):Colors.white,',
     'color:isTop?const Color(0xFF0F2A1A):const Color(0xFF0F1E35),'),
    ('border:Border.all(color:isTop?Colors.green:Colors.grey.shade200)),',
     'border:Border.all(color:isTop?const Color(0xFF34D399):const Color(0xFF2F435C))),'),
    ('Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),',
     'Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:Color(0xFFF8FAFC)))),'),
    ('Text(body,style:const TextStyle(color:const Color(0xFFF8FAFC))),',
     'Text(body,style:const TextStyle(color:Color(0xFFCBD5E1))),'),
    ('Text("Rate: $rate",style:const TextStyle(fontWeight:FontWeight.w700,color:Colors.green)),',
     'Text("Rate: $rate",style:const TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF34D399))),'),
]

count = 0
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        count += 1

with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
    f.write(content)
print(f'✅ {count}/{len(replacements)} fargefikser i _alertCard')
PYTHON

echo ""
echo "🚀 Deployer e-postfiksen..."
firebase deploy --only functions:sendWeeklyOfferNotification,functions:weeklyOffersScheduler
