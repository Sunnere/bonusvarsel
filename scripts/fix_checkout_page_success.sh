#!/bin/bash
set -e

python3 << 'PYEOF'
path = "/Users/sunnerehelse/bonusvarsel/lib/pages/checkout_page.dart"
with open(path, "r") as f:
    content = f.read()

old = """  @override
  void initState() {
    super.initState();
    _prepare();
  }"""

new = """  @override
  void initState() {
    super.initState();
    _prepare();
    CheckoutService.instance.onPurchaseSuccess = _onPurchaseSuccess;
  }

  @override
  void dispose() {
    CheckoutService.instance.onPurchaseSuccess = null;
    super.dispose();
  }

  void _onPurchaseSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _PurchaseSuccessPage()),
    );
  }"""

content = content.replace(old, new)

if "entitlement_service.dart" not in content:
    content = content.replace(
        "import '../services/checkout_service.dart';",
        "import '../services/checkout_service.dart';\nimport '../services/entitlement_service.dart';"
    )

success_page = '''
class _PurchaseSuccessPage extends StatelessWidget {
  const _PurchaseSuccessPage();

  @override
  Widget build(BuildContext context) {
    final plan = EntitlementService.instance.plan;
    final isElite = plan == 'elite';
    final accent = isElite ? const Color(0xFFD4AF37) : const Color(0xFF22C55E);
    final title = isElite ? 'Elite aktivert!' : 'Premium aktivert!';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: accent, size: 96),
                const SizedBox(height: 24),
                Text(title, style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                const Text(
                  'Abonnementet ditt er nå aktivt. Du har tilgang til alle premium-funksjoner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Tilbake til appen', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
'''

content = content.rstrip() + "\n" + success_page

with open(path, "w") as f:
    f.write(content)

print("✅ checkout_page.dart oppdatert")
PYEOF
