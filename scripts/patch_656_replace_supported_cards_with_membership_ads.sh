#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_656_replace_supported_cards_with_membership_ads"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) imports
if "package:url_launcher/url_launcher.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';\n",
        1,
    )

# 2) helper method inside _PremiumPageState
marker = "  void _checkout(String plan) {\n"
if marker in text and "Future<void> _openPartnerUrl(String url) async {" not in text:
    insert_after = """  void _checkout(String plan) {
    // TODO: Koble til betaling/IAP senere (RevenueCat/StoreKit/Google Play Billing)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Start $plan (betalingsflyt kommer).')),
    );
  }
"""
    replacement = """  void _checkout(String plan) {
    // TODO: Koble til betaling/IAP senere (RevenueCat/StoreKit/Google Play Billing)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Start $plan (betalingsflyt kommer).')),
    );
  }

  Future<void> _openPartnerUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke åpne lenken: $url')),
      );
    }
  }
"""
    text = text.replace(insert_after, replacement, 1)

old = """                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: const Color(0xFF0F172A),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Icon(
                                  Icons.credit_card_rounded,
                                  color: accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kort vi støtter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Se kort og programmer vi bygger rundt for å maksimere poengverdien.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.78),
                                        fontSize: 12.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Container(
                                width: isMobile ? double.infinity : 195,
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
                                    Icon(Icons.workspace_premium_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'SAS Amex',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sterk verdi for deg som vil kombinere kortopptjening med SAS-flybonus.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
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
                                    Icon(Icons.credit_score_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'SAS Mastercard',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Relevant for daglig bruk og opptjening mot EuroBonus over tid.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
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
                                    Icon(Icons.language_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Visa / SAS-partnere',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Gir plass til Visa-baserte kort og partnere som inngår i SAS-løpet.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: isMobile ? double.infinity : 195,
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
                                    Icon(Icons.savings_rounded, color: accent, size: 20),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Trumf-kort',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'For deg som vil fange opp dagligvare- og Trumf-verdi som kan konverteres videre.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.76),
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),"""

new = """                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: const Color(0xFF0F172A),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Icon(
                                  Icons.campaign_rounded,
                                  color: accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start med riktig medlemskap',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'To raske valg for å komme i gang med bonus og poeng.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.78),
                                        fontSize: 12.5,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.flight_takeoff_rounded,
                                title: 'Bli SAS EuroBonus-medlem',
                                body: 'Perfekt for deg som vil samle poeng til flyreiser, oppgraderinger og medlemsfordeler.',
                                badge: 'SAS',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.sas.no/register/eurobonus'),
                              ),
                              _MembershipPromoCard(
                                width: isMobile ? null : 390,
                                accent: accent,
                                icon: Icons.savings_rounded,
                                title: 'Bli Trumf-medlem',
                                body: 'Bra start hvis du vil samle bonus på dagligvarer, netthandel og senere kunne overføre verdi videre.',
                                badge: 'TRUMF',
                                ctaLabel: 'Bli medlem her',
                                onTap: () => _openPartnerUrl('https://www.trumf.no/bli-medlem'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),"""

if old not in text:
    print("❌ Fant ikke eksisterende 'Kort vi støtter'-seksjon. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old, new, 1)

# 3) helper widget at end of file
if "class _MembershipPromoCard extends StatelessWidget {" not in text:
    text += """

class _MembershipPromoCard extends StatelessWidget {
  final double? width;
  final Color accent;
  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final String ctaLabel;
  final VoidCallback onTap;

  const _MembershipPromoCard({
    this.width,
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
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
  }
}
"""

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Byttet ut støttede kort med medlems-annonsekort for SAS og Trumf")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
