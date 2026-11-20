# 67: Full abonnementsside for alle + tydelige knapper til den.
#  - premium_page.dart: betalende brukere ser nå hele siden (Gratis / Premium / Elite side om side),
#    med "Din plan" merket, "Inkludert" på lavere nivå og "Oppgrader til Elite" for Premium.
#    Bannerboksen "Du er Premium-medlem" ligger øverst, med fordeler og "Administrer abonnement".
#    Test-knappen "Test Premium paywall" vises bare i debug.
#  - home_page.dart: abonnementsknapp (stjerne) ved siden av tannhjulet i toppmenyen.
#  - trumf_kalkulator_page.dart: abonnementskort øverst i Spar > Favoritter.
#  - settings_page.dart: lenken heter nå "Se alle abonnement".
# Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/67_abonnement_side_og_knapper.sh
# Test-miljø: BV_REPO=/sti/til/kopi bash scripts/67_abonnement_side_og_knapper.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/67_${TS}"
mkdir -p "$BACKUP"

python3 - "$BACKUP" <<'PYEOF'
import sys, os, shutil
backup = sys.argv[1]

FILES = [
    "lib/pages/premium_page.dart",
    "lib/pages/home_page.dart",
    "lib/pages/trumf_kalkulator_page.dart",
    "lib/pages/settings_page.dart",
]
src = {}
for p in FILES:
    if not os.path.isfile(p):
        raise SystemExit("FEIL: finner ikke %s. Ingen filer er endret." % p)
    with open(p, encoding="utf-8") as fh:
        src[p] = fh.read()

if "_buildCurrentPlanBanner" in src["lib/pages/premium_page.dart"]:
    print("Abonnementssiden er allerede oppdatert. Ingenting å gjøre.")
    raise SystemExit(0)

def rep(p, old, new):
    s = src[p]
    n = s.count(old)
    if not n == 1:
        raise SystemExit("FEIL i %s: forventet 1 treff, fant %d for:\n%s\nIngen filer er endret." % (p, n, old[:120]))
    src[p] = s.replace(old, new, 1)

def span(p, start, end, before, after):
    """Setter 'before' foran start og 'after' foran end (første end etter start)."""
    s = src[p]
    if not s.count(start) == 1:
        raise SystemExit("FEIL i %s: startanker treffer %d ganger:\n%s" % (p, s.count(start), start[:120]))
    i = s.index(start)
    j = s.find(end, i)
    if j < 0 or s.count(end, i) < 1:
        raise SystemExit("FEIL i %s: fant ikke sluttanker:\n%s" % (p, end[:120]))
    src[p] = s[:i] + before + s[i:j] + after + s[j:]

# ───────────────────────── premium_page.dart ─────────────────────────
P = "lib/pages/premium_page.dart"

rep(P, "import 'package:flutter/material.dart';\n",
       "import 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart' show kDebugMode;\n")

rep(P, "  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    if (_routeArgsApplied) return;",
       "  @override\n  void initState() {\n    super.initState();\n    if (EntitlementService.instance.isElite) _selected = 'Elite';\n  }\n\n"
       "  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    if (_routeArgsApplied) return;")

METHODS = """  Future<void> _upgradeToElite() async {
    final url = stripeCheckoutUri('https://buy.stripe.com/9B65kE28i7f44tbcrLcQU05');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _manageSubscription() async {
    await launchUrl(
      Uri.parse('https://billing.stripe.com/p/login/3cIdRa5ku42S2l34ZjcQU00'),
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _buildCurrentPlanBanner(bool isElite) {
    const gold = Color(0xFFD4AF37);
    const blue = Color(0xFF60A5FA);
    final color = isElite ? gold : blue;
    final benefits = isElite
        ? const [
            '✅ Alt i Premium',
            '✅ 10 Trumf Netthandel-favoritter',
            '✅ 10 SAS Shopping-favoritter',
            '✅ SAS Bonusreise-oversikt',
            '✅ VIP-varsler og prioritert support',
          ]
        : const [
            '✅ 5 Trumf Netthandel-favoritter',
            '✅ 5 SAS Shopping-favoritter',
            '✅ AI-analyse ubegrenset',
            '✅ Personlige varsler',
            '✅ SAS fly-tilbudsvarsler',
          ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2340),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isElite ? '🏆' : '⭐', style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isElite ? 'Du er Elite-medlem!' : 'Du er Premium-medlem!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isElite ? '89 kr/mnd' : '49 kr/mnd',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Dine fordeler:',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...benefits.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(t, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _manageSubscription,
            child: const Text(
              '💳 Administrer abonnement →',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

"""
rep(P, "  @override\n  Widget build(BuildContext context) {\n    final cs = Theme.of(context).colorScheme;\n    final isMobile = MediaQuery.of(context).size.width < 520;",
       METHODS + "  @override\n  Widget build(BuildContext context) {\n    final cs = Theme.of(context).colorScheme;\n    final isMobile = MediaQuery.of(context).size.width < 520;")

# Fjern den gamle korte siden for betalende (early return)
s = src[P]
a = s.find("    if (isCurrentElite || isCurrentPremium) {\n      return Scaffold(\n        appBar: AppBar(title: const Text('Mitt abonnement')),")
b = s.find("    return Scaffold(\n      floatingActionButton: PaywallLauncherButton(")
if a < 0 or b < 0 or b < a or s.count("    if (isCurrentElite || isCurrentPremium) {") != 1:
    raise SystemExit("FEIL i %s: fant ikke den gamle betalende-siden. Ingen filer er endret." % P)
src[P] = s[:a] + "    final isPaid = isCurrentElite || isCurrentPremium;\n\n" + s[b:]

rep(P, "      floatingActionButton: PaywallLauncherButton(\n        tooltip: 'Test Premium paywall',\n      ),",
       "      floatingActionButton: (isPaid || !kDebugMode)\n          ? null\n          : PaywallLauncherButton(\n              tooltip: 'Test Premium paywall',\n            ),")
rep(P, "      appBar: AppBar(\n        title: const Text('Premium & Elite'),\n      ),",
       "      appBar: AppBar(\n        title: Text(isPaid ? 'Mitt abonnement' : 'Premium & Elite'),\n      ),")

# Salgsseksjonene skjules for betalende; banner øverst
rep(P, "                    _HeroConversion(\n                      accent: accent,",
       "                    if (isPaid) ...[\n                      _buildCurrentPlanBanner(isCurrentElite),\n                      const SizedBox(height: 18),\n                    ],\n"
       "                    if (!isPaid) ...[\n                    _HeroConversion(\n                      accent: accent,")
rep(P, "                    const SizedBox(height: 18),\n\n                    const SizedBox(height: 16),\n                    _SectionTitle(\n                      title: 'Velg nivå',\n                      subtitle:\n                          'Premium hvis du vil maksimere SAS Shopping. Elite hvis du vil ha alt (SAS + mer).',\n                    ),",
       "                    ],\n                    const SizedBox(height: 18),\n\n                    const SizedBox(height: 16),\n                    _SectionTitle(\n                      title: isPaid ? 'Alle abonnement' : 'Velg nivå',\n"
       "                      subtitle: isPaid\n                          ? 'Sammenlign nivåene. Din plan er merket.'\n                          : 'Premium hvis du vil maksimere SAS Shopping. Elite hvis du vil ha alt (SAS + mer).',\n                    ),")

rep(P, "                          _PlanPicker(\n                            accent: accent,\n                            selected: _selected,\n                            onSelect: _select,\n                            onCheckout: _checkout,\n                          ),",
       "                          _PlanPicker(\n                            accent: accent,\n                            selected: _selected,\n                            onSelect: _select,\n                            onCheckout: _checkout,\n"
       "                            currentPlan: isPaid ? (isCurrentElite ? 'Elite' : 'Premium') : null,\n                            onUpgradeElite: _upgradeToElite,\n                          ),")

# "Klar for å låse opp"-boksen og betalingsknappen skjules for betalende
span(P, "                    const SizedBox(height: 18),\n                    Container(\n                      padding: const EdgeInsets.all(14),\n                      decoration: BoxDecoration(\n                        color: cs.surface.withValues(alpha: 0.82),",
       "                    const SizedBox(height: 20),\n                    Row(\n                      mainAxisAlignment: MainAxisAlignment.center,",
       "                    if (!isPaid) ...[\n", "                    ],\n")
span(P, "                    const SizedBox(height: 16),\n                    SizedBox(\n                      width: double.infinity,\n                      child: FilledButton(\n                        style: FilledButton.styleFrom(\n                          backgroundColor: accent,\n                          foregroundColor: const Color(0xFF111111),",
       "                  ],\n                ),\n              ),\n            ),\n\n\n          ],",
       "                    if (!isPaid) ...[\n", "                    ],\n")

# _PlanPicker
rep(P, "  final void Function(String plan) onCheckout;\n\n  const _PlanPicker({required this.accent,\n    required this.selected,\n    required this.onSelect,\n    required this.onCheckout,\n  });\n",
       "  final void Function(String plan) onCheckout;\n  final String? currentPlan;\n  final VoidCallback? onUpgradeElite;\n\n  const _PlanPicker({required this.accent,\n    required this.selected,\n    required this.onSelect,\n    required this.onCheckout,\n    this.currentPlan,\n    this.onUpgradeElite,\n  });\n\n"
       "  int _rank(String p) => p == 'Elite' ? 2 : (p == 'Premium' ? 1 : 0);\n"
       "  bool _isCurrent(String p) => currentPlan != null && _rank(p) == _rank(currentPlan!);\n"
       "  bool _isIncluded(String p) => currentPlan != null && _rank(p) < _rank(currentPlan!);\n")
rep(P, "          selected: selected == 'Gratis',\n", "          selected: selected == 'Gratis',\n          current: _isCurrent('Gratis'),\n          included: _isIncluded('Gratis'),\n")
rep(P, "          selected: selected == 'Premium',\n", "          selected: selected == 'Premium',\n          current: _isCurrent('Premium'),\n          included: _isIncluded('Premium'),\n")
rep(P, "          selected: selected == 'Elite',\n", "          selected: selected == 'Elite',\n          current: _isCurrent('Elite'),\n          included: _isIncluded('Elite'),\n")
rep(P, "          ctaLabel: 'Elite',\n          ctaColor: const Color(0xFFD4AF37),",
       "          ctaLabel: currentPlan == 'Premium' ? 'Oppgrader til Elite — 89 kr/mnd' : 'Elite',\n          ctaColor: const Color(0xFFD4AF37),")
rep(P, "          onCta: () => onCheckout('Elite'),",
       "          onCta: (currentPlan == 'Premium' && onUpgradeElite != null)\n              ? onUpgradeElite!\n              : () => onCheckout('Elite'),")

# _PlanCard
rep(P, "  final String? note;\n\n  // ignore: unused_element_parameter\n  final Color? ctaLabelColor;\n  final VoidCallback onCta;\n",
       "  final String? note;\n  final bool current;\n  final bool included;\n\n  // ignore: unused_element_parameter\n  final Color? ctaLabelColor;\n  final VoidCallback onCta;\n")
rep(P, "    this.note,\n    this.ctaLabelColor,\n    required this.onCta,\n    this.ctaColor,\n",
       "    this.note,\n    this.current = false,\n    this.included = false,\n    this.ctaLabelColor,\n    required this.onCta,\n    this.ctaColor,\n")
rep(P, "                    child: Text(\n                      badge,\n                      style: TextStyle(\n                        fontWeight: FontWeight.w900,",
       "                    child: Text(\n                      current ? 'Din plan' : badge,\n                      style: TextStyle(\n                        fontWeight: FontWeight.w900,")
rep(P, "                    backgroundColor: emphasis ? accent : cs.primary,\n                    foregroundColor: emphasis ? Colors.black : cs.onPrimary,\n                    textStyle: const TextStyle(fontWeight: FontWeight.w900),\n                  ),\n                  onPressed: onCta,\n                  child: Text(\n                    ctaLabel,",
       "                    backgroundColor: emphasis ? accent : cs.primary,\n                    foregroundColor: emphasis ? Colors.black : cs.onPrimary,\n                    disabledBackgroundColor: accent.withValues(alpha: 0.22),\n                    disabledForegroundColor: Colors.white,\n                    textStyle: const TextStyle(fontWeight: FontWeight.w900),\n                  ),\n                  onPressed: (current || included) ? null : onCta,\n                  child: Text(\n                    current ? 'Din plan ✓' : (included ? 'Inkludert' : ctaLabel),")

# ───────────────────────── home_page.dart ─────────────────────────
H = "lib/pages/home_page.dart"
rep(H, "import 'settings_page.dart';\n", "import 'settings_page.dart';\nimport 'premium_page.dart';\n")
rep(H, "      actions: [\n        IconButton(\n          icon: const Icon(Icons.settings_outlined),",
       "      actions: [\n        IconButton(\n          icon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFF0D48A)),\n          tooltip: 'Abonnement',\n          onPressed: () => Navigator.push(context,\n            MaterialPageRoute(builder: (_) => const PremiumPage())),\n        ),\n        IconButton(\n          icon: const Icon(Icons.settings_outlined),")

# ───────────────────────── trumf_kalkulator_page.dart ─────────────────────────
T = "lib/pages/trumf_kalkulator_page.dart"
rep(T, "import 'paywall_page.dart';\n", "import 'paywall_page.dart';\nimport 'premium_page.dart';\n")
PLANCARD = """  Widget _planCard() {
    final color = _isElite
        ? const Color(0xFFD4AF37)
        : (_isPremium ? const Color(0xFF34D399) : const Color(0xFF60A5FA));
    final title = _isElite
        ? 'Ditt abonnement: Elite'
        : (_isPremium ? 'Ditt abonnement: Premium' : 'Oppgrader til Premium eller Elite');
    final sub = _isElite
        ? 'Se alle fordeler og administrer abonnementet'
        : (_isPremium
            ? 'Se alle abonnement, oppgrader til Elite eller administrer'
            : 'Se hva du får og velg abonnement');
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(children: [
          Text(_isElite ? '🏆' : '⭐', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }

"""
rep(T, "  // ── FAVORITTER ────────────────────────────────────────────\n  Widget _buildFavoritter() {",
       PLANCARD + "  // ── FAVORITTER ────────────────────────────────────────────\n  Widget _buildFavoritter() {")
rep(T, "      _adBanner('spar_favoritter'),\n      const SizedBox(height: 8),",
       "      _adBanner('spar_favoritter'),\n      const SizedBox(height: 8),\n      _planCard(),")

# ───────────────────────── settings_page.dart ─────────────────────────
S = "lib/pages/settings_page.dart"
rep(S, "                    _currentPlan == 'elite'\n                      ? 'Se alle fordeler →'\n                      : 'Oppgrader til Elite →',",
       "                    'Se alle abonnement →',")

# Skriv alt, med backup
for p in FILES:
    dest = os.path.join(backup, p)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(p, dest)
    with open(p, "w", encoding="utf-8") as fh:
        fh.write(src[p])
    print("Endret: " + p)
PYEOF

echo ""
echo "Neste steg (kjøres av deg):"
echo "  cd $REPO && flutter analyze --no-pub 2>&1 | grep -E \"error|issues found\""
echo "  Forventet: ingen errors (ca. 116 issues). Kjør appen og sjekk: stjerne i toppmenyen, kort i Spar > Favoritter, Mitt abonnement."
