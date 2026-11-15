#!/usr/bin/env bash
# 15_build_webnode_forside.sh
# Genererer webnode/forside.html for bonusvarsel.no
# Regler: kun <style> + <div> (ingen html/head/body), hardkodede farger, ingen JS.
# Bruk:  bash scripts/15_build_webnode_forside.sh [rot-mappe]   (default: ~/bonusvarsel)
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
OUT_DIR="$ROOT/webnode"
OUT="$OUT_DIR/forside.html"

# ---- Endre disse ved behov ----
APPSTORE_URL="https://apps.apple.com/no/app/bonusvarsel/id6761297259"
SHOP_URL="https://bonusshop.no"
CONTACT_EMAIL="support@bonusvarsel.no"
PRIVACY_URL="https://www.bonusvarsel.no/privacy-policy/"
# --------------------------------

mkdir -p "$OUT_DIR"

PRIV_NO=""; PRIV_EN=""
if [ -n "$PRIVACY_URL" ]; then
  PRIV_NO="<a href=\"$PRIVACY_URL\">Personvern</a>"
  PRIV_EN="<a href=\"$PRIVACY_URL\">Privacy</a>"
fi

cat > "$OUT" <<EOF
<style>
.bvn{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;color:#1B2433;line-height:1.55;background:#FFFFFF}
.bvn *{box-sizing:border-box}
.bvn-radio{position:absolute;opacity:0;pointer-events:none}
.bvn .en{display:none !important}
#bvn-en:checked ~ .bvn-page .no{display:none !important}
#bvn-en:checked ~ .bvn-page .en{display:revert !important}
.bvn a{color:#2F6BFF;text-decoration:none}
.bvn-top{display:flex;align-items:center;justify-content:flex-end;padding:10px 24px;background:#0B1F3A}
.bvn-logo{color:#FFFFFF !important;font-weight:800;letter-spacing:2px;font-size:18px}
.bvn-nav{display:flex;gap:20px;flex-wrap:wrap;align-items:center}
.bvn-nav a{color:#C9D6EE !important;font-size:15px}
.bvn-flags{display:flex;gap:8px;align-items:center}
.bvn-flags label{cursor:pointer;display:inline-flex;padding:3px;border-radius:6px;border:2px solid transparent;opacity:.55;line-height:0}
#bvn-no:checked ~ .bvn-page label[for=bvn-no],#bvn-en:checked ~ .bvn-page label[for=bvn-en]{opacity:1;border-color:#FFFFFF}
.bvn-btn{display:inline-block;padding:13px 26px;border-radius:10px;font-weight:700;font-size:16px;background:#2F6BFF;color:#FFFFFF !important;margin:6px 8px 6px 0}
.bvn-btn.alt{background:transparent;border:2px solid #FFFFFF}
.bvn-btn.dis{background:#E3E8F1;color:#6B7690 !important;cursor:default}
.bvn-btn.small{padding:9px 18px;font-size:14px;margin:0}
.bvn-hero{background:#0B1F3A;color:#FFFFFF;padding:72px 24px 80px;text-align:center}
.bvn-eyebrow{text-transform:uppercase;letter-spacing:2px;font-size:13px;color:#8FB0FF;margin-bottom:14px}
.bvn-hero h1{font-size:44px;line-height:1.1;margin:0 auto 18px;max-width:760px;color:#FFFFFF}
.bvn-hero p{font-size:18px;color:#C9D6EE;max-width:640px;margin:0 auto 28px}
.bvn-supports{margin-top:34px;font-size:14px;color:#8FA3C7}
.bvn-supports b{color:#FFFFFF;font-weight:600}
.bvn-sec{padding:64px 24px;max-width:1040px;margin:0 auto}
.bvn-sec h2{font-size:32px;line-height:1.2;margin:0 0 12px;color:#0B1F3A}
.bvn-lead{font-size:17px;color:#4A556B;max-width:680px;margin:0 0 36px}
.bvn-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:18px}
.bvn-card{background:#F5F7FB;border-radius:14px;padding:24px}
.bvn-card h3{margin:0 0 8px;font-size:19px;color:#0B1F3A}
.bvn-card p{margin:0 0 14px;color:#4A556B;font-size:15px}
.bvn-step{display:inline-flex;width:34px;height:34px;border-radius:50%;background:#2F6BFF;color:#FFFFFF;font-weight:700;align-items:center;justify-content:center;margin-bottom:12px}
.bvn-alt{background:#F5F7FB}
.bvn-cta{background:#0B1F3A;color:#FFFFFF;text-align:center;padding:64px 24px}
.bvn-cta h2{color:#FFFFFF;font-size:32px;margin:0 0 10px}
.bvn-cta p{color:#C9D6EE;margin:0 0 24px}
.bvn-foot{padding:28px 24px;text-align:center;font-size:14px;color:#6B7690;background:#FFFFFF}
.bvn-foot a{margin:0 10px}
@media (max-width:640px){.bvn-hero h1{font-size:32px}.bvn-sec h2{font-size:26px}.bvn-top{padding:12px 16px}}
</style>

<div class="bvn">
<input class="bvn-radio" type="radio" name="bvlang" id="bvn-no" checked>
<input class="bvn-radio" type="radio" name="bvlang" id="bvn-en">

<div class="bvn-page">

<div class="bvn-top">
  <div class="bvn-flags">
    <label for="bvn-no" title="Norsk"><svg width="28" height="20" viewBox="0 0 22 16"><rect width="22" height="16" fill="#BA0C2F"/><rect x="6" width="4" height="16" fill="#FFFFFF"/><rect y="6" width="22" height="4" fill="#FFFFFF"/><rect x="7" width="2" height="16" fill="#00205B"/><rect y="7" width="22" height="2" fill="#00205B"/></svg></label>
    <label for="bvn-en" title="English"><svg width="28" height="20" viewBox="0 0 60 30"><rect width="60" height="30" fill="#012169"/><path d="M0,0 L60,30 M60,0 L0,30" stroke="#FFFFFF" stroke-width="6"/><path d="M0,0 L60,30 M60,0 L0,30" stroke="#C8102E" stroke-width="2"/><path d="M30,0 V30 M0,15 H60" stroke="#FFFFFF" stroke-width="10"/><path d="M30,0 V30 M0,15 H60" stroke="#C8102E" stroke-width="6"/></svg></label>
  </div>
</div>

<div class="bvn-hero">
  <div class="bvn-eyebrow no">Bonuspoeng og cashback på ett sted</div>
  <div class="bvn-eyebrow en">Bonus points and cashback in one place</div>
  <h1 class="no">La poengene dine jobbe for deg.</h1>
  <h1 class="en">Make your points work harder.</h1>
  <p class="no">Bonusvarsel viser deg hvor du bør handle for å tjene EuroBonus- og Trumf-poeng, i butikkene du allerede bruker.</p>
  <p class="en">Bonusvarsel shows you where to shop to earn EuroBonus and Trumf points, at the stores you already use.</p>
  <a class="bvn-btn no" href="$APPSTORE_URL">Last ned i App Store</a>
  <a class="bvn-btn en" href="$APPSTORE_URL">Download on the App Store</a>
  <a class="bvn-btn alt no" href="#hvordan">Slik fungerer det</a>
  <a class="bvn-btn alt en" href="#hvordan">How it works</a>
  <div class="bvn-supports no">Støtter: <b>SAS EuroBonus</b> · <b>Trumf</b></div>
  <div class="bvn-supports en">Supports: <b>SAS EuroBonus</b> · <b>Trumf</b></div>
</div>

<div id="hvordan" class="bvn-sec">
  <h2 class="no">Slik fungerer det</h2><h2 class="en">How it works</h2>
  <p class="bvn-lead no">Tre steg fra spredte poeng til din neste reise.</p>
  <p class="bvn-lead en">Three steps from scattered points to your next trip.</p>
  <div class="bvn-grid">
    <div class="bvn-card"><div class="bvn-step">1</div>
      <h3 class="no">Se saldoen samlet</h3><h3 class="en">See your balance in one view</h3>
      <p class="no">Se EuroBonus og Trumf samlet, også direkte på hjemskjermen med widget.</p>
      <p class="en">See EuroBonus and Trumf together, also on your home screen with the widget.</p></div>
    <div class="bvn-card"><div class="bvn-step">2</div>
      <h3 class="no">Finn reiser</h3><h3 class="en">Find trips</h3>
      <p class="no">Se hva poengene dine faktisk rekker til, og hva som er verdt å handle på.</p>
      <p class="en">See what your points can actually get you, and what is worth shopping for.</p></div>
    <div class="bvn-card"><div class="bvn-step">3</div>
      <h3 class="no">Ta med noen gratis</h3><h3 class="en">Bring someone along</h3>
      <p class="no">Bruk poengene smart og ta med en venn eller familiemedlem på turen.</p>
      <p class="en">Use your points wisely and bring a friend or family member on the trip.</p></div>
  </div>
</div>

<div id="produkter" class="bvn-alt"><div class="bvn-sec">
  <h2 class="no">Fire produkter. Én plattform.</h2><h2 class="en">Four products. One platform.</h2>
  <div class="bvn-grid">
    <div class="bvn-card"><h3>App</h3>
      <p class="no">Bonusoversikt, optimalisering og varsler samlet i appen.</p>
      <p class="en">Bonus overview, optimization and alerts in one app.</p>
      <a class="no" href="$APPSTORE_URL">Last ned i App Store →</a><a class="en" href="$APPSTORE_URL">Download on the App Store →</a></div>
    <div class="bvn-card"><h3>Shop</h3>
      <p class="no">Cashback hos over 50 butikker. Du handler som vanlig og får penger tilbake.</p>
      <p class="en">Cashback at 50+ stores. Shop as usual and get money back.</p>
      <a class="no" href="$SHOP_URL">Gå til BonusShop →</a><a class="en" href="$SHOP_URL">Go to BonusShop →</a></div>
    <div class="bvn-card"><h3 class="no">Regnskap</h3><h3 class="en">Accounting</h3>
      <p class="no">Finansiell oversikt og regnskapsassistanse.</p>
      <p class="en">Financial overview and accounting assistance.</p></div>
    <div class="bvn-card"><h3>Booking</h3>
      <p class="no">Oppdag reiser og opplevelser.</p>
      <p class="en">Discover trips and experiences.</p></div>
  </div>
</div></div>

<div class="bvn-cta">
  <h2 class="no">Kom i gang på under to minutter</h2><h2 class="en">Get started in under two minutes</h2>
  <p class="no">Gratis å laste ned. Premium og Elite er valgfrie abonnement i appen.</p>
  <p class="en">Free to download. Premium and Elite are optional subscriptions in the app.</p>
  <a class="bvn-btn no" href="$APPSTORE_URL">Last ned i App Store</a><a class="bvn-btn en" href="$APPSTORE_URL">Download on the App Store</a>
  <span class="bvn-btn dis no">Google Play: kommer</span><span class="bvn-btn dis en">Google Play: coming soon</span>
</div>

<div class="bvn-foot">
  <div>© 2026 Bonusvarsel</div>
  <div style="margin-top:8px">
    <a class="no" href="mailto:$CONTACT_EMAIL">Kontakt</a><a class="en" href="mailto:$CONTACT_EMAIL">Contact</a>
    <span class="no">$PRIV_NO</span><span class="en">$PRIV_EN</span>
  </div>
</div>

</div>
</div>
EOF


# ---- Navbar (erstatter koden i den ØVERSTE HTML-blokken) ----
NAV_OUT="$OUT_DIR/navbar.html"
cat > "$NAV_OUT" <<NAVEOF
<header class="bvx-navbar">
  <div class="bvx-nav-inner">
    <a href="/" class="bvx-logo">BONUSVARSEL</a>
    <nav class="bvx-nav-links">
      <a href="#hvordan">Bonusvarsel</a>
      <a href="$SHOP_URL">BonusShop</a>
      <a href="#produkter">Regnskap</a>
      <a href="#produkter">AI Booking</a>
    </nav>
    <div class="bvx-nav-actions">
      <a href="$APPSTORE_URL" class="bvx-nav-download">Last ned app</a>
    </div>
  </div>
</header>
<style>
.bvx-navbar{position:sticky;top:0;z-index:1000;backdrop-filter:blur(20px);background:rgba(255,255,255,.92);border-bottom:1px solid rgba(0,0,0,.05)}
.bvx-nav-inner{max-width:1280px;margin:auto;padding:18px 30px;display:flex;align-items:center;justify-content:space-between}
.bvx-logo{font-family:'Cormorant Garamond',serif;font-size:30px;text-decoration:none;color:#1a1208}
.bvx-nav-links{display:flex;gap:30px}
.bvx-nav-links a{text-decoration:none;color:#6b5b4d;font-size:15px}
.bvx-nav-download{background:linear-gradient(135deg,#c9956a,#9a6840);color:white;padding:12px 24px;border-radius:999px;text-decoration:none}
@media(max-width:900px){.bvx-nav-links{display:none}}
</style>
NAVEOF

# ---- Validering ----
fail=0
grep -qiE '<(html|head|body)\b' "$OUT" && { echo "FEIL: html/head/body-tagger funnet"; fail=1; }
grep -qE 'var\(--' "$OUT" && { echo "FEIL: CSS-variabler funnet"; fail=1; }
grep -qiE '<script' "$OUT" && { echo "FEIL: script-tagger funnet"; fail=1; }
[ "$fail" -eq 0 ] || exit 1

python3 - "$OUT" <<'PY'
import sys
from html.parser import HTMLParser
void={'input','meta','br','img','hr','link','path','rect'}
class P(HTMLParser):
    def __init__(s):
        super().__init__(); s.st=[]; s.err=[]
    def handle_starttag(s,t,a):
        if t not in void: s.st.append(t)
    def handle_startendtag(s,t,a): pass
    def handle_endtag(s,t):
        if t in void: return
        if not s.st or s.st[-1]!=t: s.err.append(f"uventet </{t}> (forventet {s.st[-1] if s.st else 'ingen'})")
        else: s.st.pop()
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
if p.err or p.st:
    print("FEIL i HTML-struktur:",p.err[:3],p.st[:3]); sys.exit(1)
PY

echo "OK: $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
echo "OK: $NAV_OUT"
echo "Neste: cat \"$OUT\" | pbcopy  → lim inn i Webnode HTML-blokk"
