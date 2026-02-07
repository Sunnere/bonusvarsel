import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MamTestPage(),
    );
  }
}

class MamTestPage extends StatefulWidget {
  const MamTestPage({super.key});

  @override
  State<MamTestPage> createState() => _MamTestPageState();
}

class _MamTestPageState extends State<MamTestPage> {
  late final Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _countFuture = _loadOfferCount();
  }

  Future<int> _loadOfferCount() async {
    final s = await rootBundle.loadString('assets/mam.offers.min.json');
    final decoded = jsonDecode(s);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Root is not a JSON object');
    }

    final offers = decoded['offers'];
    if (offers is! List) {
      throw Exception('Missing or invalid "offers" array');
    }

    return offers.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bonusvarsel')),
      body: FutureBuilder<int>(
        future: _countFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final count = snapshot.data ?? 0;
          return Center(
            child: Text(
              'Offers loaded: $count',
              style: const TextStyle(fontSize: 22),
            ),
          );
        },
      ),
    );
  }
}
