#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_674_remove_mobile_sticky_cta_and_make_elite_luxury"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) Fjern kun den mobile sticky CTA-bruken
old_sticky = """            if (isMobile)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _StickyCta(
                  accent: accent,
                  selected: _selected,
                  onCheckout: () => _checkout(_selected),
                ),
              ),"""

new_sticky = ""

if old_sticky in text:
    text = text.replace(old_sticky, new_sticky, 1)
else:
    print("⚠️ Fant ikke eksakt Positioned/_StickyCta-blokk. Hopper over sticky-fjerning.")

# 2) Gjør Elite-kortet visuelt dyrere i _PlanCard
old_border = """    final borderColor = selected
        ? accent.withValues(alpha: 0.85)
        : (emphasis
            ? accent.withValues(alpha: 0.45)
            : cs.onSurface.withValues(alpha: 0.36));"""

new_border = """    final borderColor = selected
        ? (title == 'Elite'
            ? const Color(0xFFD4AF37)
            : accent.withValues(alpha: 0.85))
        : (emphasis
            ? (title == 'Elite'
                ? const Color(0xFFD4AF37).withValues(alpha: 0.52)
                : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));"""

if old_border in text:
    text = text.replace(old_border, new_border, 1)
else:
    print("⚠️ Fant ikke borderColor-blokken. Hopper over den delen.")

old_bg = """    final bg = cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);"""

new_bg = """    final bg = title == 'Elite'
        ? (selected
            ? const Color(0xFF17132E)
            : const Color(0xFF121826))
        : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);"""

if old_bg in text:
    text = text.replace(old_bg, new_bg, 1)
else:
    print("⚠️ Fant ikke bg-blokken. Hopper over den delen.")

old_badge = """                      color: (emphasis ? accent : cs.onSurface)
                          .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: (emphasis ? accent : cs.onSurface)
                            .withValues(alpha: 0.36),
                      ),"""

new_badge = """                      color: title == 'Elite'
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.16)
                          : (emphasis ? accent : cs.onSurface)
                              .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: title == 'Elite'
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.50)
                            : (emphasis ? accent : cs.onSurface)
                                .withValues(alpha: 0.36),
                      ),"""

if old_badge in text:
    text = text.replace(old_badge, new_badge, 1)
else:
    print("⚠️ Fant ikke badge-fargeblokken. Hopper over den delen.")

old_title = """                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),"""

new_title = """                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: title == 'Elite'
                              ? const Color(0xFFFFF3C4)
                              : null,
                        ),
                  ),"""

if old_title in text:
    text = text.replace(old_title, new_title, 1)
else:
    print("⚠️ Fant ikke title-stylen. Hopper over den delen.")

old_premium_card = """        _PlanCard(
          title: 'Premium',
          badge: 'Mest valgt',
          emphasis: true,
          selected: selected == 'Premium',
          accent: accent,
          bullets: const [
            'Alle SAS Shopping-butikker',
            'Høyeste poengrate',
            'Boost og kampanjer',
            'Maks oversikt',
          ],
          onTap: () => onSelect('Premium'),
          ctaLabel: 'Premium',
              ctaColor: const Color(0xFF22C55E),
              note: 'Typisk ekstra: +2k–8k poeng/år',
          onCta: () => onCheckout('Premium'),
        ),"""

new_premium_card = """        _PlanCard(
          title: 'Premium',
          badge: 'Mest valgt',
          emphasis: true,
          selected: selected == 'Premium',
          accent: accent,
          bullets: const [
            'Alle SAS Shopping-butikker',
            'Høyeste poengrate',
            'Boost og kampanjer',
            'Maks oversikt',
          ],
          onTap: () => onSelect('Premium'),
          ctaLabel: 'Premium',
          ctaColor: const Color(0xFF22C55E),
          note: 'Typisk ekstra: +2k–8k poeng/år',
          onCta: () => onCheckout('Premium'),
        ),"""

if old_premium_card in text:
    text = text.replace(old_premium_card, new_premium_card, 1)

old_elite_card = """        _PlanCard(
          title: 'Elite',
          badge: 'Mest eksklusiv',
          emphasis: true,
          selected: selected == 'Elite',
          accent: accent,
          bullets: const [
            'Alt i Premium',
            'Flere programmer (SAS + SkyTeam + Trumf m.fl.)',
            'Enda flere boost-muligheter',
            'Smartere prioritering (kommer)',
          ],
          onTap: () => onSelect('Elite'),
          ctaLabel: 'Elite',
          onCta: () => onCheckout('Elite'),
        ),"""

new_elite_card = """        _PlanCard(
          title: 'Elite',
          badge: 'Mest eksklusiv',
          emphasis: true,
          selected: selected == 'Elite',
          accent: accent,
          bullets: const [
            'Alt i Premium',
            'Flere programmer (SAS + SkyTeam + Trumf m.fl.)',
            'Enda flere boost-muligheter',
            'Smartere prioritering (kommer)',
          ],
          onTap: () => onSelect('Elite'),
          ctaLabel: 'Elite',
          ctaColor: const Color(0xFFD4AF37),
          note: 'Typisk ekstra: maks poengverdi + flere programmer',
          onCta: () => onCheckout('Elite'),
        ),"""

if old_elite_card in text:
    text = text.replace(old_elite_card, new_elite_card, 1)
else:
    print("⚠️ Fant ikke Elite _PlanCard-blokken. Hopper over note/ctaColor.")

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Fjernet mobil sticky CTA og ga Elite-kortet luksusfarger")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "==> Verifiser nøkkellinjer"
grep -n "_StickyCta\|title: 'Elite'\|D4AF37\|Typisk ekstra: maks poengverdi" "$FILE" || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
