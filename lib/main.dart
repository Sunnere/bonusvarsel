import 'package:flutter/material.dart';
import 'pages/eb_shopping_page.dart';
import 'app/error_handling.dart';

void main() {
  setupErrorHandling();

  runApp(const BonusvarselApp());
}

class BonusvarselApp extends StatelessWidget {
  const BonusvarselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bonusvarsel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const EbShoppingPage(),
    );
  }
}
