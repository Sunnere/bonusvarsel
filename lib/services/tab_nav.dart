import 'package:flutter/foundation.dart';

/// Lar en side be HomePage bytte fane.
/// 0 = Poeng, 1 = Spar, 2 = Kort, 3 = Varsler, 4 = Reis.
final ValueNotifier<int?> homeTabRequest = ValueNotifier<int?>(null);

void goToHomeTab(int index) {
  homeTabRequest.value = index;
}

/// Aktiv fane i HomePage (lar sidene laste på nytt når de blir synlige).
final ValueNotifier<int> homeTabIndex = ValueNotifier<int>(0);
