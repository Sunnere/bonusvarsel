#!/bin/bash
set -e

FILE="api/server.js"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE — kjør dette fra rota av repoet."
  exit 1
fi

if grep -q "api.brevo.com" "$FILE"; then
  echo "⚠️  Brevo ser ut til å allerede være i bruk — avbryter for å unngå duplikat."
  exit 1
fi

cp "$FILE" "${FILE}.bak-$(date +%Y%m%d%H%M%S)"
echo "📦 Sikkerhetskopi lagret: ${FILE}.bak-*"

python3 << 'PYEOF'
FILE = "api/server.js"

with open(FILE, "r") as f:
    content = f.read()

old_block = '''// ── E-post sending via SendGrid ───────────────────────────────────────────────
async function sendEmail(to, subject, html) {
  if (!process.env.SENDGRID_API_KEY || !process.env.SENDGRID_FROM) {
    console.warn('SendGrid ikke konfigurert');
    return false;
  }
  try {
    await sgMail.send({
      to,
      from: process.env.SENDGRID_FROM,
      subject,
      html,
    });
    console.log(`E-post sendt til ${to}`);
    return true;
  } catch (e) {
    console.error('SendGrid feil DETALJER:', JSON.stringify(e?.response?.body) || String(e));
    return false;
  }
}'''

if old_block not in content:
    raise SystemExit("❌ Fant ikke forventet sendEmail()-blokk med SendGrid — filen kan avvike fra det patchen er laget mot. Ingen endringer gjort. Kontakt Claude med fersk kopi av sendEmail()-funksjonen.")

new_block = '''// ── E-post sending via Brevo (byttet fra SendGrid pga. utløpt trial) ─────────
async function sendEmail(to, subject, html) {
  if (!process.env.BREVO_API_KEY || !process.env.BREVO_FROM) {
    console.warn('Brevo ikke konfigurert');
    return false;
  }
  try {
    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': process.env.BREVO_API_KEY,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: JSON.stringify({
        sender: { email: process.env.BREVO_FROM, name: 'Bonusvarsel' },
        to: [{ email: to }],
        subject,
        htmlContent: html,
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      console.error('Brevo feil DETALJER:', errorBody);
      return false;
    }

    console.log(`E-post sendt til ${to}`);
    return true;
  } catch (e) {
    console.error('Brevo feil:', String(e));
    return false;
  }
}'''

content = content.replace(old_block, new_block, 1)

# Fjern SendGrid-importen og init-blokken øverst (ikke lenger i bruk)
old_import_block = '''import dotenv from 'dotenv';
import sgMail from '@sendgrid/mail';
dotenv.config();

if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  console.log('✅ SendGrid klar');
}'''

new_import_block = '''import dotenv from 'dotenv';
dotenv.config();

if (process.env.BREVO_API_KEY) {
  console.log('✅ Brevo klar');
}'''

if old_import_block in content:
    content = content.replace(old_import_block, new_import_block, 1)
    print("2. SendGrid-import og init-blokk fjernet, erstattet med Brevo-sjekk")
else:
    print("2. HOPPET OVER (import-blokk ikke funnet uendret - sjekk manuelt om @sendgrid/mail-importen bør fjernes)")

with open(FILE, "w") as f:
    f.write(content)

print("✅ sendEmail() byttet fra SendGrid til Brevo")
PYEOF

node --check "$FILE" && echo "✅ $FILE — syntaks gyldig"

echo ""
echo "⚠️  HUSK å legge til disse miljøvariablene i Railway (Variables-fanen):"
echo "   BREVO_API_KEY = <din API-nøkkel fra Brevo>"
echo "   BREVO_FROM    = support@bonusvarsel.no"
echo ""
echo "Du kan la SENDGRID_API_KEY og SENDGRID_FROM stå urørt i Railway som backup,"
echo "de brukes ikke lenger av koden men gjør ingen skade om de blir liggende."
