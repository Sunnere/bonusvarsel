// lib/services/eb_loader.dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/eb_shop.dart';

class EbLoader {
  // Husk: i pubspec.yaml må du ha:
  // assets:
  //   - assets/eb.shopping.min.json

  static const String assetPath = 'assets/eb.shopping.min.json';

  static Future<List<EbShop>> load() async {
    final s = await rootBundle.loadString(assetPath);

    final decoded = jsonDecode(s);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('EB asset root is not an object');
    }

    final shopsRaw = decoded['shops'];
    if (shopsRaw is! List) {
      throw Exception('EB asset missing "shops" array');
    }

    final shops = <EbShop>[];
    for (final item in shopsRaw) {
      if (item is Map<String, dynamic>) {
        shops.add(EbShop.fromJson(item));
      } else if (item is Map) {
        shops.add(EbShop.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // Sort A-Å
    shops.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return shops;
  }
}
