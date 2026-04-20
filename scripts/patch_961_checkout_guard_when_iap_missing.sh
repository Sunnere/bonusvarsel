#!/bin/bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"
BACKUP="${FILE}.bak_961_checkout_guard_when_iap_missing_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

cat <<'DART' > "$FILE"
import 'package:flutter/material.dart';
import '../services/checkout_service.dart';

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
  }

  Future<void> _prepare() async {
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
        if (!available) {
          _status =
              'Produkt ikke klart ennå for denne builden.\n'
              'Valgt produkt: $selectedId\n'
              'Lastede produkter: ${loadedIds.isEmpty ? 'ingen' : loadedIds.join(', ')}';
        } else {
          _status = null;
        }
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

  Future<void> _retryLoad() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    await _prepare();
  }

  Future<void> _buy() async {
    if (_busy || !_productAvailable) return;

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final msg = await _checkout.buySelectedVerbose();
      if (!mounted) return;

      setState(() {
        _status = msg;
      });

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
      if (mounted) {
        setState(() => _busy = false);
      }
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
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _checkout.plan.toLowerCase();
    final isElite = plan == 'elite';

    final accent = isElite
        ? const Color(0xFFD4AF37)
        : const Color(0xFF22C55E);

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
            ? const Center(child: CircularProgressIndicator())
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        _productAvailable
                            ? 'Betaling fullføres i appen via Apple.'
                            : 'Kjøpsproduktet er ikke tilgjengelig for denne builden ennå. '
                              'Vent litt og prøv igjen etter at abonnementene er synlige i App Store Connect / sandbox.',
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productAvailable
                                ? 'Kjøpsprodukt klart'
                                : 'Kjøpsprodukt mangler',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Valgt produkt: ${_selectedProductId ?? '-'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tilgjengelige produkter: ${_availableIds.isEmpty ? 'ingen' : _availableIds.join(', ')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (_status != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _status!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: (_busy || !_productAvailable) ? null : _buy,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _productAvailable
                                    ? 'Fortsett til Apple-betaling'
                                    : 'Produkt ikke klart ennå',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _retryLoad,
                      child: const Text('Prøv å laste produkter på nytt'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: const Text('Gjenopprett kjøp'),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
              ),
            ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.black54 : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ Patch lagt inn i checkout_page.dart"
echo "✅ Backup laget: $BACKUP"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run"
