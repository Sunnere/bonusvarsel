#!/usr/bin/env python3
import os

# ── 1. Oppdater ad_service.dart med nye annonser og placements ────────────────
ad_path = os.path.expanduser('~/bonusvarsel/lib/services/ad_service.dart')
with open(ad_path, 'r') as f:
    ad = f.read()
with open(ad_path + '.bak_placements', 'w') as f:
    f.write(ad)

old_creative = """  List<AdSlot> getCreative() => const <AdSlot>[
        AdSlot(
          id: 'amex_sas_1',
          title: 'Amex: høy poengopptjening',
          body: 'Bruk Amex på hverdagskjøp og bygg poeng raskere.',
          cta: 'Se tilbud',
          link: 'https://www.americanexpress.com/',
          tags: ['cards', 'amex', 'elite'],
        ),
        AdSlot(
          id: 'visa_sas_1',
          title: 'Visa: trygt og bredt akseptert',
          body: 'Se fordeler og kampanjer hos partnere.',
          cta: 'Sjekk kort',
          link: 'https://www.visa.com/',
          tags: ['cards', 'visa'],
        ),
        AdSlot(
          id: 'mc_sas_1',
          title: 'Mastercard: sterke fordeler',
          body: 'Se fordeler som kan gi mer verdi i hverdagen.',
          cta: 'Se fordeler',
          link: 'https://www.mastercard.com/',
          tags: ['cards', 'mastercard'],
        ),
        AdSlot(
          id: 'shopping_boost_1',
          title: 'Ekstra poeng-kampanjer i dag',
          body: 'Sjekk butikker med høy rate akkurat nå.',
          cta: 'Åpne',
          link: 'https://onlineshopping.flysas.com/',
          tags: ['shopping', 'campaign'],
        ),
      ];"""

new_creative = """  List<AdSlot> getCreative() => const <AdSlot>[
        // ── POENG-FANEN ──────────────────────────────────────────────────
        AdSlot(
          id: 'amex_sas_1',
          title: '✈️ Amex: 20 poeng per 100 kr',
          body: 'Beste SAS-kort for hverdagskjøp. Companion ticket ved 150 000 kr/år.',
          cta: 'Søk nå',
          link: 'https://www.americanexpress.com/no/',
          tags: ['poeng', 'cards', 'amex', 'elite'],
        ),
        AdSlot(
          id: 'betalo_1',
          title: '💡 Betalo: betal regninger med Amex',
          body: 'Tjen EuroBonus-poeng på strøm, studielån og faste utgifter. 2,19% gebyr.',
          cta: 'Les mer',
          link: 'https://betalo.no/',
          tags: ['poeng', 'shopping', 'betalo'],
        ),
        // ── SPAR-FANEN ──────────────────────────────────────────────────
        AdSlot(
          id: 'talkmore_1',
          title: '📱 Talkmore: 4% Trumf på mobilregningen',
          body: 'Bytt til Talkmore og tjen Trumf-bonus automatisk hver måned.',
          cta: 'Se abonnement',
          link: 'https://www.talkmore.no/',
          tags: ['spar', 'trumf', 'talkmore'],
        ),
        AdSlot(
          id: 'fjordkraft_1',
          title: '⚡ Fjordkraft: 1% Trumf på strøm',
          body: 'Bytt strømleverandør og tjen Trumf-bonus automatisk på strømregningen.',
          cta: 'Bytt nå',
          link: 'https://www.fjordkraft.no/',
          tags: ['spar', 'trumf', 'fjordkraft'],
        ),
        // ── KORT-FANEN ──────────────────────────────────────────────────
        AdSlot(
          id: 'lunar_sas_visa',
          title: '💳 SAS EuroBonus Visa via Lunar',
          body: 'Søk om SAS EuroBonus Visa direkte i Lunar-appen. 10 poeng per 100 kr.',
          cta: 'Søk i Lunar',
          link: 'https://www.lunar.app/en/personal/sas-eurobonus',
          tags: ['kort', 'visa', 'lunar'],
        ),
        AdSlot(
          id: 'mc_sas_1',
          title: '🔵 SAS EuroBonus Mastercard',
          body: 'Via DNB. 15 poeng per 100 kr. Betal regninger via AvtaleGiro.',
          cta: 'Se kortet',
          link: 'https://saseurobonusmastercard.no/',
          tags: ['kort', 'mastercard'],
        ),
        // ── VARSLER-FANEN ──────────────────────────────────────────────
        AdSlot(
          id: 'shopping_boost_1',
          title: '🛍️ Ekstra poeng-kampanjer i dag',
          body: 'Sjekk SAS Online Shopping og Trumf Netthandel for høyeste rater nå.',
          cta: 'Se kampanjer',
          link: 'https://onlineshopping.flysas.com/',
          tags: ['varsler', 'shopping', 'campaign'],
        ),
        // ── REISE-FANEN ─────────────────────────────────────────────────
        AdSlot(
          id: 'betalo_reise',
          title: '✈️ Nå målet raskere med Betalo',
          body: 'Betal reiseutgifter med Amex via Betalo og tjen ekstra poeng.',
          cta: 'Prøv Betalo',
          link: 'https://betalo.no/',
          tags: ['reis', 'betalo', 'amex'],
        ),
      ];"""

if old_creative in ad:
    ad = ad.replace(old_creative, new_creative)
    print("✅ ad_service: 8 annonser på 5 placements")
else:
    print("❌ Fant ikke getCreative()")

with open(ad_path, 'w') as f:
    f.write(ad)

# ── 2. Legg til AdSlotCard i alle 5 faner ────────────────────────────────────
def add_ad_to_page(page_path, import_line, ad_widget, anchor_old, anchor_new, label):
    with open(page_path, 'r') as f:
        c = f.read()
    with open(page_path + '.bak_ad', 'w') as f:
        f.write(c)

    if 'AdSlotCard' in c:
        print(f"✅ {label}: AdSlotCard finnes allerede")
        return

    # Legg til import
    if import_line not in c:
        c = c.replace(
            "import 'package:flutter/material.dart';",
            f"import 'package:flutter/material.dart';\n{import_line}")

    if anchor_old in c:
        c = c.replace(anchor_old, anchor_new, 1)
        print(f"✅ {label}: annonseplass lagt til")
    else:
        print(f"❌ {label}: fant ikke anchor")

    with open(page_path, 'w') as f:
        f.write(c)

base = os.path.expanduser('~/bonusvarsel/lib')
imp = "import '../widgets/ad_slot.dart';\nimport '../services/ad_service.dart';"

# SPAR (trumf_kalkulator_page)
add_ad_to_page(
    f'{base}/pages/trumf_kalkulator_page.dart', imp,
    """          // ── Forbruk ──────────────────────────────────────────
      _card([""",
    """          // ── Forbruk ──────────────────────────────────────────
      _adBanner('spar'),
      const SizedBox(height: 14),
      _card([""",
    'spar')

# REISE
add_ad_to_page(
    f'{base}/pages/travel_page.dart', imp,
    "            _slagplanSection(),\n            const SizedBox(height: 12),\n            _destinasjonerSection(),",
    "            _slagplanSection(),\n            const SizedBox(height: 12),\n            _adBanner('reis'),\n            const SizedBox(height: 12),\n            _destinasjonerSection(),",
    'reis')

# KORT
add_ad_to_page(
    f'{base}/pages/cards_page.dart', imp,
    "          // ── Annonseplass ──\n          Container(\n            height: 60,\n            decoration: BoxDecoration(\n              color: const Color(0xFF122033),\n              borderRadius: BorderRadius.circular(12),\n              border: Border.all(color: const Color(0xFF2F435C)),\n            ),\n            child: const Center(child: Text('Annonse',\n              style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 12,\n                fontWeight: FontWeight.w600, letterSpacing: 1.5))),\n          ),",
    "          // ── Annonseplass ──\n          _adBanner('kort'),",
    'kort')

# ── 3. Legg til _adBanner helper i travel_page ───────────────────────────────
travel_path = f'{base}/pages/travel_page.dart'
with open(travel_path, 'r') as f:
    travel = f.read()

if '_adBanner' not in travel:
    travel = travel.replace(
        "  Widget _card({required String title,",
        """  Widget _adBanner(String placement) {
    final ads = AdService.instance.getAdsForPlacement(placement);
    if (ads.isEmpty) return const SizedBox.shrink();
    return AdSlotCard(slot: ads.first, placement: placement);
  }

  Widget _card({required String title,""")
    with open(travel_path, 'w') as f:
        f.write(travel)
    print("✅ travel: _adBanner helper")

# Spar
spar_path = f'{base}/pages/trumf_kalkulator_page.dart'
with open(spar_path, 'r') as f:
    spar = f.read()
if '_adBanner' not in spar:
    spar = spar.replace(
        "  Widget _card(List<Widget> children)",
        """  Widget _adBanner(String placement) {
    final ads = AdService.instance.getAdsForPlacement(placement);
    if (ads.isEmpty) return const SizedBox.shrink();
    return AdSlotCard(slot: ads.first, placement: placement);
  }

  Widget _card(List<Widget> children)""")
    with open(spar_path, 'w') as f:
        f.write(spar)
    print("✅ spar: _adBanner helper")

print()
print("Sjekk om AdService har getAdsForPlacement:")
import subprocess
r = subprocess.run(['grep', '-n', 'getAdsForPlacement\|getAds\|forPlacement', ad_path],
    capture_output=True, text=True)
print(r.stdout[:300] if r.stdout else "❌ Metode mangler — må legges til")
