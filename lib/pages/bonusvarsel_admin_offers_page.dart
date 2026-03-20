import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../models/offer_record.dart';
import '../services/api_service.dart';

class BonusvarselAdminOffersPage extends StatefulWidget {
  const BonusvarselAdminOffersPage({super.key});

  @override
  State<BonusvarselAdminOffersPage> createState() => _BonusvarselAdminOffersPageState();
}

class _BonusvarselAdminOffersPageState extends State<BonusvarselAdminOffersPage> {
  late Future<List<OfferRecord>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _offersFuture = ApiService.getOffers();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _offersFuture;
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'boost':
        return Colors.orange;
      case 'premium':
        return Colors.blue;
      case 'elite':
        return const Color(0xFFD4AF37);
      default:
        return Colors.grey;
    }
  }

  Widget _buildOffersList(List<OfferRecord> offers) {
    if (offers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text('Ingen offers funnet.'),
      );
    }

    return Column(
      children: offers.map((offer) {
        final color = _levelColor(offer.level);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border),
          ),
          child: ListTile(
            leading: const Icon(Icons.local_offer),
            title: Text(
              offer.id,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${offer.storeId} • ${offer.rateText} • ${offer.expires}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: color.withValues(alpha: 0.12),
              ),
              child: Text(
                offer.level.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Offers'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OfferRecord>>(
          future: _offersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Feil: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              );
            }

            final offers = snapshot.data ?? <OfferRecord>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B1F4D),
                        Color(0xFF2F80ED),
                      ],
                    ),
                  ),
                  child: Text(
                    'Adminverktøy for offers (${offers.length})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildOffersList(offers),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
