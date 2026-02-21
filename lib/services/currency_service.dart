import 'package:flutter/material.dart';

class CurrencyService {
  /// Enkel, trygg formatering uten ekstra dependencies.
  /// Viser beløp i lokal desimal-format og legger på "kr" (midlertidig).
  /// (Når vi går “pro”, kan vi gjøre ekte valuta pr land.)
  static String format(BuildContext context, double amountNok) {
    final loc = MaterialLocalizations.of(context);
    final s = loc.formatDecimal(amountNok.round());
    return '$s kr';
  }
}
