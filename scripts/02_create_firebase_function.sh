#!/bin/bash
set -e
TARGET="functions/index.js"

if [ ! -f "$TARGET" ]; then
  echo "❌ Finner ikke $TARGET – er du i bonusvarsel-mappen?"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_notification_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

cd functions
if ! grep -q '"nodemailer"' package.json 2>/dev/null; then
  echo "📦 Installerer nodemailer..."
  npm install nodemailer --save
fi
if ! grep -q '"axios"' package.json 2>/dev/null; then
  echo "📦 Installerer axios..."
  npm install axios --save
fi
cd ..

if grep -q "sendWeeklyOfferNotification" "$TARGET" 2>/dev/null; then
  echo "ℹ️  Funksjon finnes allerede – hopper over"
  exit 0
fi

cat >> "$TARGET" << 'JS'

// ── Bonusvarsler ukentlig – lagt til av script 02 ────────────
const nodemailer = require('nodemailer');
const axios      = require('axios');

const RAILWAY_URL         = process.env.RAILWAY_URL || 'https://bonusvarsel-production.up.railway.app';
const TELEGRAM_BOT_TOKEN  = process.env.TELEGRAM_BOT_TOKEN || '';
const EMAIL_USER          = process.env.EMAIL_USER || '';
const EMAIL_PASS          = process.env.EMAIL_PASS || '';
const EMAIL_FROM          = process.env.EMAIL_FROM || 'noreply@bonusvarsel.no';

async function fetchOffersFromRailway(program) {
  try {
    const res = await axios.get(`${RAILWAY_URL}/api/offers`, {
      params: { program, limit: 5 }, timeout: 8000,
    });
    return res.data?.items || res.data?.offers || [];
  } catch (e) {
    console.error(`fetchOffers(${program}) feilet:`, e.message);
    return [];
  }
}

function buildMessage(sasOffers, trumfOffers, sasFavs, trumfFavs) {
  let msg = '🔔 *Bonusvarsler denne uken*\n\n';
  if (trumfOffers.length > 0) {
    const fav = trumfFavs && trumfFavs.length > 0 ? ' (dine favoritter)' : '';
    msg += `🟢 *Trumf Netthandel${fav}*\n`;
    for (const item of trumfOffers) {
      const rate = item.rate ? ` – ${item.rate} p/100kr` : '';
      msg += `• ${item.store || item.name}${rate}\n`;
    }
    msg += '👉 https://trumfnetthandel.no\n\n';
  }
  if (sasOffers.length > 0) {
    const fav = sasFavs && sasFavs.length > 0 ? ' (dine favoritter)' : '';
    msg += `✈️ *SAS Online Shopping${fav}*\n`;
    for (const item of sasOffers) {
      const rate = item.rate ? ` – ${item.rate} p/100kr` : '';
      msg += `• ${item.store || item.name}${rate}\n`;
    }
    msg += '👉 https://onlineshopping.flysas.com/nb-NO\n\n';
  }
  msg += '_Last ned Bonusvarsel for full oversikt_';
  return msg;
}

async function sendTelegram(chatIdOrUsername, message) {
  if (!TELEGRAM_BOT_TOKEN || !chatIdOrUsername) return;
  const chatId = chatIdOrUsername.replace('@', '');
  try {
    await axios.post(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      { chat_id: chatId, text: message, parse_mode: 'Markdown' },
      { timeout: 8000 }
    );
    console.log(`✅ Telegram sendt til ${chatId}`);
  } catch (e) {
    console.error(`Telegram feil:`, e.response?.data || e.message);
  }
}

async function sendEmail(toEmail, message) {
  if (!toEmail || !EMAIL_USER) return;
  const transporter = nodemailer.createTransporter({
    service: 'gmail',
    auth: { user: EMAIL_USER, pass: EMAIL_PASS },
  });
  const html = message
    .replace(/\*([^*]+)\*/g, '<strong>$1</strong>')
    .replace(/_([^_]+)_/g, '<em>$1</em>')
    .replace(/\n/g, '<br>');
  try {
    await transporter.sendMail({
      from: `Bonusvarsel <${EMAIL_FROM}>`,
      to: toEmail,
      subject: '🔔 Ukens bonustilbud fra Bonusvarsel',
      html: `<div style="font-family:sans-serif;max-width:500px;margin:auto;padding:20px">${html}</div>`,
    });
    console.log(`✅ E-post sendt til ${toEmail}`);
  } catch (e) {
    console.error(`E-post feil:`, e.message);
  }
}

exports.sendWeeklyOfferNotification = functions.https.onCall(async (data) => {
  const { email, telegram, message, sasCount, trumfCount } = data;
  const promises = [];
  if (telegram) promises.push(sendTelegram(telegram, message));
  if (email)    promises.push(sendEmail(email, message));
  await Promise.allSettled(promises);
  return { ok: true, sent: { telegram: !!telegram, email: !!email }, sasCount, trumfCount };
});

exports.weeklyOffersScheduler = functions.pubsub
  .schedule('0 9 * * 1,3,5')
  .timeZone('Europe/Oslo')
  .onRun(async () => {
    console.log('⏰ weeklyOffersScheduler kjører...');
    const [sasOffers, trumfOffers] = await Promise.all([
      fetchOffersFromRailway('sas_online'),
      fetchOffersFromRailway('trumf_netthandel'),
    ]);
    const sasPicked   = sasOffers.slice(0, 2);
    const trumfPicked = trumfOffers.slice(0, 3);
    if (sasPicked.length === 0 && trumfPicked.length === 0) {
      console.log('Ingen tilbud – avbryter'); return null;
    }
    const usersSnap = await admin.firestore()
      .collection('users')
      .where('notificationsEnabled', '==', true)
      .get();
    console.log(`📨 Sender til ${usersSnap.size} brukere`);
    const jobs = [];
    for (const doc of usersSnap.docs) {
      const user      = doc.data();
      const email     = user.alertEmail    || '';
      const telegram  = user.alertTelegram || '';
      if (!email && !telegram) continue;
      const sasFavs   = user.sasFavs   || [];
      const trumfFavs = user.trumfFavs || [];
      const finalSas   = sasFavs.length > 0
        ? (sasPicked.filter(i => sasFavs.some(f => (i.store||'').toLowerCase().includes(f.toLowerCase()))) || sasPicked)
        : sasPicked;
      const finalTrumf = trumfFavs.length > 0
        ? (trumfPicked.filter(i => trumfFavs.some(f => (i.store||'').toLowerCase().includes(f.toLowerCase()))) || trumfPicked)
        : trumfPicked;
      const msg = buildMessage(
        finalSas.length > 0 ? finalSas : sasPicked,
        finalTrumf.length > 0 ? finalTrumf : trumfPicked,
        sasFavs, trumfFavs
      );
      if (telegram) jobs.push(sendTelegram(telegram, msg));
      if (email)    jobs.push(sendEmail(email, msg));
    }
    await Promise.allSettled(jobs);
    console.log(`✅ Ferdig – ${jobs.length} utsendinger`);
    return null;
  });
// ─────────────────────────────────────────────────────────────
JS

echo "✅ Firebase functions lagt til"
