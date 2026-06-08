import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/checkout_service.dart';
import '../services/entitlement_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CheckoutService _checkout = CheckoutService.instance;

  String billing = CheckoutService.instance.billing;
  bool _loading = true;
  bool _busy = false;
  String? _status;
  bool _productAvailable = false;
  String? _selectedProductId;
  List<String> _availableIds = const [];

  @override
  void initState() {
    super.initState();
    _prepare();
    CheckoutService.instance.onPurchaseSuccess = _onPurchaseSuccess;
    // Sjekk om allerede aktivert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plan = CheckoutService.instance.plan.toLowerCase();
      final targetPlan = CheckoutService.instance.effectivePlan.toLowerCase();
      final currentPlan = EntitlementService.instance.plan.toLowerCase();
      if (currentPlan == targetPlan && currentPlan != 'free') {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const _PurchaseSuccessPage()));
        }
      }
    });
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
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      await _checkout.init();
      await _checkout.loadProducts();

      final selectedId = _checkout.selectedProductId();
      final loadedIds = _checkout.products.map((p) => p.id).toList();
      final available = _checkout.getProduct(selectedId) != null;

      if (!mounted) return;
      setState(() {
        billing = _checkout.billing;
        _selectedProductId = selectedId;
        _availableIds = loadedIds;
        _productAvailable = available;
        _loading = false;
        _status = available ? null : 'Produktet lastes... Prøv igjen om et øyeblikk.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _productAvailable = false;
        _status = 'Kunne ikke klargjøre betaling: $e';
      });
    }
  }

  Future<void> _setBilling(String value) async {
    setState(() {
      billing = value;
      _loading = true;
    });
    await _checkout.setBilling(value);
    await _prepare();
  }

  Future<void> _buy() async {
    if (_busy) return;

    // Hvis produkt ikke er lastet, prøv på nytt før vi gir opp
    if (!_productAvailable) {
      await _prepare();
      if (!_productAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produktet er ikke tilgjengelig ennå. Sjekk internett og prøv igjen.'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final msg = await _checkout.buySelectedVerbose();
      if (!mounted) return;
      setState(() => _status = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = 'Betaling feilet: $e';
      setState(() => _status = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _checkout.restorePurchases();
      if (!mounted) return;
      const msg = 'Gjenoppretting startet.';
      setState(() => _status = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = 'Kunne ikke gjenopprette kjøp: $e';
      setState(() => _status = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _checkout.plan.toLowerCase();
    final isElite = plan == 'elite';
    final accent = isElite ? const Color(0xFFD4AF37) : const Color(0xFF22C55E);
    final monthlyPrice = isElite ? 89 : 49;
    final yearlyPrice = isElite ? 890 : 490;
    final monthlyEquivalent = (yearlyPrice / 12).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isElite ? 'Elite' : 'Premium'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Laster betalingsalternativer...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: isElite
                              ? const [Color(0xFF1E1B13), Color(0xFFD4AF37)]
                              : const [Color(0xFF052E1C), Color(0xFF22C55E)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isElite
                                ? 'Maksimer alle poeng'
                                : 'Tjen flere poeng automatisk',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isElite
                                ? 'Opptil 8 000+ poeng per måned'
                                : 'Typisk 1 500–4 000 ekstra poeng per måned',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _PriceOption(
                            label: 'Månedlig',
                            price: '$monthlyPrice kr',
                            selected: billing == 'monthly',
                            onTap: () => _setBilling('monthly'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PriceOption(
                            label: 'Årlig',
                            price: '$yearlyPrice kr',
                            sub: '$monthlyEquivalent kr/mnd',
                            badge: '2 mnd gratis',
                            selected: billing == 'yearly',
                            onTap: () => _setBilling('yearly'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _featureRow('Flere butikker'),
                          _featureRow('Høyere poengrate'),
                          if (isElite) _featureRow('Flere programmer'),
                          _featureRow('Smartere valg'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_status != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          _status!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Alltid synlig og klikkbar — retry skjer inni _buy()
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _busy ? null : _buy,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Fortsett til Apple-betaling',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _prepare,
                      child: const Text(
                        'Last betalingsalternativer på nytt',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: const Text(
                        'Gjenopprett kjøp',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final url = isElite
                          ? 'https://buy.stripe.com/bJecN600a8j8f7P8bvcQU06'
                          : 'https://buy.stripe.com/9B65kE28i7f44tbcrLcQU05';
                        await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        isElite
                          ? '🌐 Betal via bonusvarsel.no (Elite 89kr)'
                          : '🌐 Betal via bonusvarsel.no (Premium 49kr)',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dette er et auto-fornybart abonnement betalt via Apple ID. '
                      'Abonnementet fornyes automatisk med mindre det kanselleres '
                      'minst 24 timer før slutten av perioden. '
                      'Du kan administrere abonnementet i App Store-innstillinger.',
                      style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  final String label;
  final String price;
  final String? sub;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PriceOption({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge!, style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white)),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
            if (sub != null)
              Text(
                sub!,
                style: TextStyle(fontSize: 12, color: selected ? Colors.black54 : Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}

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
