/// Register over bonusvalutaer appen kan vise saldo for.
/// Verdier (kr per poeng) ligger IKKE her. De hentes fra loyalty_config (Fase 3).
enum LoyaltyWorld { trumfEuroBonus, reitan }

class LoyaltyCurrency {
  final String id;
  final String name;
  final String unit;
  final LoyaltyWorld world;
  final String prefsKey;
  final String? widgetKey;

  const LoyaltyCurrency({
    required this.id,
    required this.name,
    required this.unit,
    required this.world,
    required this.prefsKey,
    this.widgetKey,
  });

  static const eurobonus = LoyaltyCurrency(
    id: 'eurobonus', name: 'EuroBonus', unit: 'poeng',
    world: LoyaltyWorld.trumfEuroBonus, prefsKey: 'eurobonus_points', widgetKey: 'widget_points');

  static const trumf = LoyaltyCurrency(
    id: 'trumf', name: 'Trumf-bonus', unit: 'kr',
    world: LoyaltyWorld.trumfEuroBonus, prefsKey: 'trumf_points', widgetKey: 'widget_trumf_points');

  static const spenn = LoyaltyCurrency(
    id: 'spenn', name: 'Spenn', unit: 'Spenn',
    world: LoyaltyWorld.reitan, prefsKey: 'spenn_points', widgetKey: 'widget_spenn_points');

  static const cashpoints = LoyaltyCurrency(
    id: 'cashpoints', name: 'Norwegian CashPoints', unit: 'CashPoints',
    world: LoyaltyWorld.reitan, prefsKey: 'cashpoints_points');

  static const List<LoyaltyCurrency> all = [eurobonus, trumf, spenn, cashpoints];

  static LoyaltyCurrency? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
