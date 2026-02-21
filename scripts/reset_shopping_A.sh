#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)" 2>/dev/null || true

cat > "$FILE" << 'DART'
import 'package:flutter/material.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {

  Future<List<Map<String, dynamic>>> _load() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return List.generate(230, (i) => {
      "name": "Butikk ${i + 1}",
      "rate": (i % 10) + 1,
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("EuroBonus Shopping"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snap) {

          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snap.data ?? [];

          return SafeArea(
            child: Column(
              children: [

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [

                      Text(
                        "${data.length} butikker",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {

                      final shop = data[i];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(shop["name"]),
                          subtitle: Text(
                            "${shop["rate"]} poeng / 100 kr",
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
DART

dart format "$FILE"
flutter analyze || true

echo "✅ A-layout ferdig og strukturert."
