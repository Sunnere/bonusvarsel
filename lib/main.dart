import 'package:bonusvarsel/pages/bonusvarsel_home_api_page.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:bonusvarsel/services/api_service.dart';


void main() {
  ApiService.registerDemoDeviceOnce();
  runApp(const BonusvarselApp());
  NotificationPolling.start();
}

class BonusvarselApp extends StatelessWidget {
  const BonusvarselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      
      title: 'Bonusvarsel',
      debugShowCheckedModeBanner: false,
      home: const BonusvarselHomeApiPage(),
    );
  }
}
