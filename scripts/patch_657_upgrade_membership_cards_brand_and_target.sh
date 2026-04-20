#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_657_upgrade_membership_cards_brand_and_target"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) Oppgrader de to medlemskortene med målrettede labels
text = text.replace(
"""                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.flight_takeoff_rounded,
                                title: 'Bli SAS EuroBonus-medlem',
                                body: 'Perfekt for deg som vil samle poeng til flyreiser, oppgraderinger og medlemsfordeler.',
                                badge: 'SAS',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.sas.no/register/eurobonus'),
                              ),""",
"""                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.flight_takeoff_rounded,
                                title: 'Bli SAS EuroBonus-medlem',
                                body: 'Perfekt for deg som vil samle poeng til flyreiser, oppgraderinger og medlemsfordeler.',
                                badge: 'SAS',
                                highlight: 'Best for flyreiser',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.sas.no/register/eurobonus'),
                              ),"""
)

text = text.replace(
"""                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.savings_rounded,
                                title: 'Bli Trumf-medlem',
                                body: 'Bra start hvis du vil samle bonus på dagligvarer, netthandel og senere kunne overføre verdi videre.',
                                badge: 'TRUMF',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.trumf.no/bli-medlem'),
                              ),""",
"""                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.savings_rounded,
                                title: 'Bli Trumf-medlem',
                                body: 'Bra start hvis du vil samle bonus på dagligvarer, netthandel og senere kunne overføre verdi videre.',
                                badge: 'TRUMF',
                                highlight: 'Best for daglig bonus',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.trumf.no/bli-medlem'),
                              ),"""
)

# 2) Utvid widgeten med highlight-felt
text = text.replace(
"""  final String badge;
  final String ctaLabel;
  final VoidCallback onTap;""",
"""  final String badge;
  final String highlight;
  final String ctaLabel;
  final VoidCallback onTap;"""
)

text = text.replace(
"""    required this.badge,
    required this.ctaLabel,
    required this.onTap,""",
"""    required this.badge,
    required this.highlight,
    required this.ctaLabel,
    required this.onTap,"""
)

# 3) Bytt widget body til mer luksuspreget versjon
old_widget_part = """  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: accent.withValues(alpha: 0.14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(icon, color: accent, size: 18),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: accent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(ctaLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }"""

new_widget_part = """  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.075),
                  Colors.white.withValues(alpha: 0.045),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0F172A).withValues(alpha: 0.45),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFF0F172A).withValues(alpha: 0.30),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          highlight,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(ctaLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }"""

if old_widget_part not in text:
    print("❌ Fant ikke eksisterende _MembershipPromoCard-body. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old_widget_part, new_widget_part, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Oppgraderte medlemskort med brand-strip og målrettede badges")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
