#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_675_force_visible_elite_luxury_card"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

repls = [
    (
"""  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final borderColor = selected
        ? (title == 'Elite'
            ? const Color(0xFFD4AF37)
            : accent.withValues(alpha: 0.85))
        : (emphasis
            ? (title == 'Elite'
                ? const Color(0xFFD4AF37).withValues(alpha: 0.52)
                : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));

    final bg = title == 'Elite'
        ? (selected
            ? const Color(0xFF17132E)
            : const Color(0xFF121826))
        : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);

    return SizedBox(""",
"""  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isElite = title == 'Elite';

    final borderColor = selected
        ? (isElite
            ? const Color(0xFFD4AF37)
            : accent.withValues(alpha: 0.85))
        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));

    final bg = isElite
        ? (selected
            ? const Color(0xFF1A1333)
            : const Color(0xFF141B29))
        : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);

    return SizedBox("""
    ),
    (
"""          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),""",
"""          decoration: BoxDecoration(
            color: isElite ? null : bg,
            gradient: isElite
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? const [
                            Color(0xFF24164A),
                            Color(0xFF17132E),
                            Color(0xFF101826),
                          ]
                        : const [
                            Color(0xFF1A2232),
                            Color(0xFF151B28),
                          ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isElite ? 1.5 : 1.0),
            boxShadow: [
              BoxShadow(
                color: isElite
                    ? const Color(0xFFD4AF37).withValues(alpha: selected ? 0.16 : 0.08)
                    : Colors.black.withValues(alpha: 0.36),
                blurRadius: isElite ? 24 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),"""
    ),
    (
"""                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: title == 'Elite'
                              ? const Color(0xFFFFF3C4)
                              : null,
                        ),
                  ),""",
"""                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isElite ? const Color(0xFFFFE7A3) : null,
                          letterSpacing: isElite ? 0.2 : null,
                        ),
                  ),"""
    ),
    (
"""                    decoration: BoxDecoration(
                      color: title == 'Elite'
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.16)
                          : (emphasis ? accent : cs.onSurface)
                              .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: title == 'Elite'
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.50)
                            : (emphasis ? accent : cs.onSurface)
                                .withValues(alpha: 0.36),
                      ),
                    ),""",
"""                    decoration: BoxDecoration(
                      color: isElite
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
                          : (emphasis ? accent : cs.onSurface)
                              .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isElite
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.62)
                            : (emphasis ? accent : cs.onSurface)
                                .withValues(alpha: 0.36),
                      ),
                    ),"""
    ),
]

changed = False
for old, new in repls:
    if old in text:
        text = text.replace(old, new, 1)
        changed = True

# Sørg for Elite-kortet har note + gull CTA
old_elite = """        _PlanCard(
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

new_elite = """        _PlanCard(
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
          note: 'Luksusnivå: maks poengverdi + flere programmer',
          onCta: () => onCheckout('Elite'),
        ),"""

if old_elite in text:
    text = text.replace(old_elite, new_elite, 1)
    changed = True

if not changed:
    print("❌ Fant ikke de forventede _PlanCard-blokkene. Ingen endring gjort.")
    sys.exit(1)

path.write_text(text)
print("✅ Gjorde Elite-kortet synlig mørkere og mer luksuriøst")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "==> Vis elite-treff"
grep -n "isElite\|D4AF37\|Luksusnivå" "$FILE" || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
