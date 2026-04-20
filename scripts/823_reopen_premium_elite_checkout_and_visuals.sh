#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="${FILE}.bak_${STAMP}_823"

echo "==> 823_reopen_premium_elite_checkout_and_visuals"
cp "$FILE" "$BACKUP"
echo "Backup: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
src = path.read_text(encoding="utf-8")
original = src

def require_contains(text: str, needle: str, label: str):
    if needle not in text:
        print(f"❌ Fant ikke {label}")
        sys.exit(1)

# 1) checkout_page import tilbake
if "import 'checkout_page.dart';" not in src:
    needle = "import '../services/checkout_service.dart';\n"
    require_contains(src, needle, "import for checkout_service.dart")
    src = src.replace(
        needle,
        needle + "import 'checkout_page.dart';\n",
        1,
    )

# 2) _checkout tilbake til intern checkout for Premium/Elite
old_checkout = """  void _checkout(String plan) async {
    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: _billingCycle,
    );

    final payload = CheckoutService.instance.toPayload();

    // TODO: kobles til Stripe / IAP senere
    debugPrint('Checkout payload: $payload');

    if (!mounted) return;

    
await launchUrl(
  Uri.parse('https://www.bonusvarsel.no'),
  mode: LaunchMode.externalApplication,
);

  }
"""

new_checkout = """  void _checkout(String plan) async {
    if (plan == 'Gratis') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gratis krever ingen betaling.')),
      );
      return;
    }

    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: _billingCycle,
    );

    final payload = CheckoutService.instance.toPayload();

    // TODO: kobles til ekte Apple IAP / StoreKit
    debugPrint('Checkout payload: $payload');

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }
"""
require_contains(src, old_checkout, "_checkout-blokken")
src = src.replace(old_checkout, new_checkout, 1)

# 3) Partner-url fallback skal ikke sende til hjemmeside
old_open_partner = """  Future<void> _openPartnerUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      
await launchUrl(
  Uri.parse('https://www.bonusvarsel.no'),
  mode: LaunchMode.externalApplication,
);

    }
  }
"""

new_open_partner = """  Future<void> _openPartnerUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne lenken akkurat nå.')),
      );
    }
  }
"""
if old_open_partner in src:
    src = src.replace(old_open_partner, new_open_partner, 1)

# 4) Build-header: tre tydelige looks
old_build_header = """  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 520;

    final accent = _selected == 'Elite'
        ? const Color(0xFFD4AF37)
        : const Color(0xFFF0D48A);

    return Scaffold(
"""

new_build_header = """  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 520;

    final isEliteSelected = _selected == 'Elite';
    final isPremiumSelected = _selected == 'Premium';
    final isFreeSelected = _selected == 'Gratis';

    final accent = isEliteSelected
        ? const Color(0xFFD4AF37)
        : isPremiumSelected
            ? const Color(0xFF22C55E)
            : const Color(0xFF60A5FA);

    final heroTitle = isEliteSelected
        ? 'Elite: maksimal poengkraft'
        : isPremiumSelected
            ? 'Premium: få alle poengene'
            : 'Start gratis og oppgrader når du vil';

    final heroSubtitle = isEliteSelected
        ? 'Elite prioriterer maksimal poengverdi, flere programmer og et tydeligere premium-uttrykk i hele flyten.'
        : isPremiumSelected
            ? 'Premium åpner full poengoversikt, beste rate og sterkere shopping- og reisevalg direkte i appen.'
            : 'Gratis lar deg teste kjernen. Premium og Elite låser opp betaling, mer verdi og tydeligere premium-opplevelse.';

    final valueLeftTitle = isEliteSelected
        ? 'Elite-verdi'
        : isPremiumSelected
            ? 'Premium-verdi'
            : 'Gratis i dag';

    final valueLeftBody = isEliteSelected
        ? 'For brukere som vil presse ut maksimal poengverdi på tvers av SAS, Trumf og videre partnerlogikk.'
        : isPremiumSelected
            ? 'For deg som vil ha full Premium-flyt med bedre prioritering, raskere vei til handling og tydeligere verdi.'
            : 'Se basisinnholdet gratis, og oppgrader når du vil låse opp Premium eller Elite.';

    final valueRightTitle = isEliteSelected
        ? 'Elite-look'
        : isPremiumSelected
            ? 'Premium-look'
            : 'Neste steg';

    final valueRightBody = isEliteSelected
        ? 'Gulltoner, sterkere premium-signaler og tydelig Elite-prioritering i hele medlemssiden.'
        : isPremiumSelected
            ? 'Grønn Premium-look, tydelig betalingsvei og mer salgssterk medlemspresentasjon.'
            : 'Velg Premium eller Elite for å åpne betalingsflyt og et tydeligere medlemsuttrykk.';

    return Scaffold(
"""
require_contains(src, old_build_header, "build-header")
src = src.replace(old_build_header, new_build_header, 1)

# 5) Hero-tekst dynamisk
old_hero = """                    _HeroConversion(
                      accent: accent,
                      title: 'Få alle poengene — uten å tenke',
                      subtitle:
                          'Premium/Elite gjør at du alltid ser beste poengrate og boost-tilbud. '
                          'Du handler som vanlig — og får mer tilbake.',
                      chips: const [
"""

new_hero = """                    _HeroConversion(
                      accent: accent,
                      title: heroTitle,
                      subtitle: heroSubtitle,
                      chips: const [
"""
require_contains(src, old_hero, "_HeroConversion-blokken")
src = src.replace(old_hero, new_hero, 1)

# 6) ValueBar dynamisk
old_valuebar = """                    _ValueBar(
                      accent: accent,
                      leftTitle: 'Typisk gevinst',
                      leftBody:
                          'Typisk bruk kan gi ca. 1 500–4 000 ekstra poeng per måned med riktige valg.',
                      rightTitle: 'Mål',
                      rightBody:
                          'Aktiv bruk kan gi opptil 8 000+ poeng per måned og gjøre reiser merkbart billigere.',
                    ),
"""

new_valuebar = """                    _ValueBar(
                      accent: accent,
                      leftTitle: valueLeftTitle,
                      leftBody: valueLeftBody,
                      rightTitle: valueRightTitle,
                      rightBody: valueRightBody,
                    ),
"""
require_contains(src, old_valuebar, "_ValueBar-blokken")
src = src.replace(old_valuebar, new_valuebar, 1)

# 7) Nederste CTA tydelig per nivå
old_cta = """                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: const Color(0xFF111111),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            onPressed: () => _checkout(_selected),
                            child: Text(_selected == 'Elite' ? 'Elite' : 'Premium'),
                          ),
"""

new_cta = """                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: isEliteSelected
                                  ? const Color(0xFF111111)
                                  : Colors.white,
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            onPressed: () => _checkout(_selected),
                            child: Text(
                              isFreeSelected
                                  ? 'Fortsett gratis'
                                  : isEliteSelected
                                      ? 'Åpne Elite'
                                      : 'Åpne Premium',
                            ),
                          ),
"""
require_contains(src, old_cta, "nederste CTA-blokken")
src = src.replace(old_cta, new_cta, 1)

if src == original:
    print("❌ Ingen endringer ble gjort.")
    sys.exit(1)

path.write_text(src, encoding="utf-8")
print("✅ premium_page.dart oppdatert")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d ios"
