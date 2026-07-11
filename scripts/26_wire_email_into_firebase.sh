#!/bin/bash
set -e
TARGET="functions/index.js"

[ -f "$TARGET" ] || { echo "❌ Fant ikke $TARGET – står du i bonusvarsel-mappen?"; exit 1; }
cp "$TARGET" "$TARGET.bak_email3d_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
f = "functions/index.js"
s = open(f).read()
changed = []

if "buildEmailHtml" in s:
    print("ℹ️  buildEmailHtml finnes allerede – hopper over (ingen endring)")
else:
    anchor = "const EMAIL_FROM = process.env.EMAIL_FROM || 'noreply@bonusvarsel.no';"
    logo_const = anchor + "\nconst BV_LOGO_URL = 'https://res.cloudinary.com/ds3xrvivm/image/upload/wa3jjnrx6k6skq01sqxg.jpg';\nconst BV_SAS_BASE = 'https://onlineshopping.flysas.com/nb-NO/butikk/';"
    if anchor in s:
        s = s.replace(anchor, logo_const); changed.append("LOGO_URL")
    else:
        print("⚠️  Fant ikke EMAIL_FROM-linja – legger LOGO øverst")
        s = "const BV_LOGO_URL = 'https://res.cloudinary.com/ds3xrvivm/image/upload/wa3jjnrx6k6skq01sqxg.jpg';\nconst BV_SAS_BASE = 'https://onlineshopping.flysas.com/nb-NO/butikk/';\n" + s
        changed.append("LOGO_URL(top)")

    BUILDER = r'''
// ── 3D HTML-e-post (logo + dempet grønn premium) ──────────────────────
const BV = {
  NAVY:"#0F2340", GOLD:"#D4AF37", ELITE_BG:"#110A28", PREMIUM_BG:"#0E2A22",
  GRAD_NAVY:"linear-gradient(145deg,#1a3454 0%,#0F2340 55%,#081628 100%)",
  GRAD_PREMIUM:"linear-gradient(145deg,#16382c 0%,#0E2A22 55%,#08160F 100%)",
  GRAD_ELITE:"linear-gradient(145deg,#241544 0%,#110A28 55%,#080414 100%)",
  GRAD_GOLD:"linear-gradient(145deg,#f0d77a 0%,#D4AF37 55%,#a8841f 100%)",
};
function bvFmtDate(iso){ if(!iso) return ""; const p=String(iso).split("-"); return p.length===3?`${p[2]}.${p[1]}`:""; }
function bvTheme(tier,isElite){
  const t=String(tier||"").toLowerCase();
  if(isElite||t.includes("elite")) return {grad:BV.GRAD_ELITE,solid:BV.ELITE_BG};
  if(t.includes("premium")) return {grad:BV.GRAD_PREMIUM,solid:BV.PREMIUM_BG};
  return {grad:BV.GRAD_NAVY,solid:BV.NAVY};
}
function bvOfferCard(c){
  const name=c.name||c.store||"Butikk";
  const slug=c.slug||"";
  const link=slug?(BV_SAS_BASE+slug):(c.url||c.link||"https://onlineshopping.flysas.com/nb-NO");
  const pc=c.points_campaign!=null?c.points_campaign:(c.rate!=null?c.rate:null);
  const old=(c.points!=null&&c.points>0)?c.points:null;
  const ends=c.campaign_ends_iso?`Gyldig t.o.m. ${bvFmtDate(c.campaign_ends_iso)}`:"";
  const img=c.image_url||"";
  const initial=name[0]||"?";
  const imgCell=img
    ?`<img src="${img}" width="54" height="54" style="border-radius:12px;object-fit:cover;display:block;box-shadow:0 4px 10px rgba(15,35,64,0.25)" alt="${name}">`
    :`<div style="width:54px;height:54px;border-radius:12px;background:${BV.GRAD_NAVY};color:${BV.GOLD};text-align:center;line-height:54px;font-weight:800;font-size:22px;box-shadow:0 4px 10px rgba(15,35,64,0.25),inset 0 1px 0 rgba(255,255,255,0.15)">${initial}</div>`;
  const priceLine=pc!=null
    ?`${old!=null?`<span style="text-decoration:line-through;color:#aab">${old}p</span> `:""}<span style="color:#b8901f;font-weight:800">${pc}p/100kr</span>`
    :"";
  return `<tr><td style="padding:7px 0"><table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(145deg,#ffffff 0%,#f5f7fa 100%);border-radius:14px;box-shadow:0 6px 16px rgba(15,35,64,0.10);border:1px solid rgba(15,35,64,0.06)"><tr><td width="74" style="vertical-align:middle;padding:14px 0 14px 14px">${imgCell}</td><td style="vertical-align:middle;padding:14px 8px 14px 14px"><div style="font-size:16px;font-weight:800;color:${BV.NAVY}">${name}</div><div style="font-size:14px;margin-top:2px">${priceLine}</div><div style="font-size:11px;color:#9aa3ad;margin-top:2px">${ends}</div></td><td width="96" style="vertical-align:middle;text-align:right;padding-right:14px"><a href="${link}" style="background:${BV.GRAD_GOLD};color:${BV.NAVY};padding:10px 16px;border-radius:9px;text-decoration:none;font-weight:800;font-size:13px;display:inline-block;box-shadow:0 4px 12px rgba(212,175,55,0.4),inset 0 1px 0 rgba(255,255,255,0.5)">Handle &rarr;</a></td></tr></table></td></tr>`;
}
function buildEmailHtml(offers, tier, isElite){
  tier=tier||"Premium"; isElite=!!isElite;
  const th=bvTheme(tier,isElite);
  const list=Array.isArray(offers)?offers:[];
  const cards=list.map(bvOfferCard).join("");
  const skyteam=isElite?`<tr><td style="padding:6px 22px 14px"><table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(145deg,#faf8ff 0%,#f1ecff 100%);border-radius:14px;box-shadow:0 6px 16px rgba(17,10,40,0.10);border:1px solid rgba(17,10,40,0.06)"><tr><td style="padding:16px 18px"><div style="font-size:13px;font-weight:800;color:${BV.ELITE_BG};margin-bottom:8px">&#9992;&#65039; SkyTeam &amp; Luksus</div><div style="font-size:13px;color:#555;line-height:1.9">&bull; <a href="https://www.sas.no/eurobonus/bonusreiser" style="color:${BV.ELITE_BG};font-weight:600">SAS Bonusreiser</a> &ndash; fast poengpris<br>&bull; <a href="https://www.sas.no/eurobonus" style="color:${BV.ELITE_BG};font-weight:600">Hotell med poeng</a><br>&bull; SkyTeam-lounger med Gull/Diamant</div></td></tr></table></td></tr>`:"";
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;background:#e8ebf0;font-family:Arial,Helvetica,sans-serif"><table width="100%" cellpadding="0" cellspacing="0" style="background:#e8ebf0"><tr><td align="center" style="padding:24px 12px"><table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:linear-gradient(145deg,#ffffff 0%,#eef1f6 100%);border-radius:22px;overflow:hidden;box-shadow:0 20px 48px rgba(15,35,64,0.22),0 2px 0 rgba(255,255,255,0.8) inset"><tr><td style="background:${th.grad};background-color:${th.solid};padding:30px 24px 26px;text-align:center;box-shadow:inset 0 -3px 12px rgba(0,0,0,0.35),inset 0 2px 0 rgba(255,255,255,0.12)"><img src="${BV_LOGO_URL}" width="64" height="64" alt="Bonusvarsel" style="border-radius:16px;display:inline-block;vertical-align:middle;box-shadow:0 6px 16px rgba(0,0,0,0.45),inset 0 1px 0 rgba(255,255,255,0.2)"><div style="color:${BV.GOLD};font-size:28px;font-weight:800;letter-spacing:0.5px;text-shadow:0 2px 4px rgba(0,0,0,0.4);margin-top:10px">Bonusvarsel</div><div style="display:inline-block;margin-top:10px;padding:5px 16px;border-radius:20px;background:rgba(255,255,255,0.10);box-shadow:inset 0 1px 0 rgba(255,255,255,0.2);color:#fff;font-size:13px;font-weight:600">${tier} &middot; Ukens topptilbud</div></td></tr><tr><td style="padding:18px 22px 8px"><table width="100%" cellpadding="0" cellspacing="0">${cards}</table></td></tr>${skyteam}<tr><td style="background:${th.grad};background-color:${th.solid};padding:22px;text-align:center;box-shadow:inset 0 3px 12px rgba(0,0,0,0.3)"><div style="color:#fff;font-size:12px;line-height:1.7">Du mottar dette fordi du har registrert e-posten i Bonusvarsel-appen.<br><a href="mailto:support@bonusvarsel.no?subject=Avmeld" style="color:${BV.GOLD};font-weight:600">Avmeld deg</a></div><div style="color:rgba(255,255,255,0.5);font-size:10px;line-height:1.5;margin-top:12px;border-top:1px solid rgba(255,255,255,0.12);padding-top:10px">&laquo;Premium&raquo; og &laquo;Elite&raquo; er Bonusvarsel sine egne abonnementsniv&aring;er<br>og har ingen tilknytning til American Express sine kortprodukter.</div></td></tr></table><div style="font-size:11px;color:#9aa3ad;margin-top:14px">Bonusvarsel &middot; Sunnere Helse Hub</div></td></tr></table></body></html>`;
}

'''
    marker = "async function sendEmail(toEmail, message) {"
    if marker in s:
        s = s.replace(marker, BUILDER + marker, 1); changed.append("buildEmailHtml")
    else:
        print("⚠️  Fant ikke sendEmail – sjekk filen manuelt")

    s = s.replace(
        "async function sendEmail(toEmail, message) {",
        "async function sendEmail(toEmail, message, emailHtml) {", 1)
    s = s.replace(
        'html: `<div style="font-family:sans-serif;max-width:500px;margin:auto;padding:20px">${html}</div>`,',
        'html: emailHtml || `<div style="font-family:sans-serif;max-width:500px;margin:auto;padding:20px">${html}</div>`,', 1)
    changed.append("sendEmail-signatur")

    sched_old = "const msg = buildMessage(finalSas, finalTrumf, sasFavs, trumfFavs);\n    if (telegram) jobs.push(sendTelegram(telegram, msg));\n    if (email)    jobs.push(sendEmail(email, msg));"
    sched_new = ("const msg = buildMessage(finalSas, finalTrumf, sasFavs, trumfFavs);\n"
                 "    const userTier = user.tier || 'Premium';\n"
                 "    const userIsElite = String(userTier).toLowerCase().includes('elite');\n"
                 "    const emailHtml = buildEmailHtml([].concat(finalTrumf, finalSas), userTier, userIsElite);\n"
                 "    if (telegram) jobs.push(sendTelegram(telegram, msg));\n"
                 "    if (email)    jobs.push(sendEmail(email, msg, emailHtml));")
    if sched_old in s:
        s = s.replace(sched_old, sched_new, 1); changed.append("scheduler")
    else:
        print("ℹ️  Scheduler-blokk litt annerledes – e-post bruker fortsatt enkel HTML der (callable+test virker)")

    call_old = "if (email)    promises.push(sendEmail(email, message));"
    call_new = ("if (email)    promises.push(sendEmail(email, message,\n"
                "      data.offers ? buildEmailHtml(data.offers, data.tier, /elite/i.test(String(data.tier||''))) : undefined));")
    if call_old in s:
        s = s.replace(call_old, call_new, 1); changed.append("callable")

    open(f,"w").write(s)

print("Endret:", ", ".join(changed) if changed else "ingenting")
PYTHON

echo ""
echo "🧪 Verifiserer syntaks..."
node --check "$TARGET" && echo "✅ Syntaks gyldig" || { echo "❌ Syntaksfeil – gjenoppretter backup"; cp "$TARGET".bak_email3d_* "$TARGET" 2>/dev/null; exit 1; }
