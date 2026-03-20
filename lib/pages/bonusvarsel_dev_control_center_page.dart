import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'bonusvarsel_dev_tools_page.dart';
import 'bonusvarsel_device_monitor_page.dart';
import 'bonusvarsel_notifications_page.dart';
import 'bonusvarsel_push_preview_page.dart';

class BonusvarselDevControlCenterPage extends StatelessWidget {
  const BonusvarselDevControlCenterPage({super.key});

  Widget _entry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Container(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dev Control Center',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.surface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Intern kontrollside for seed offer, devices, notifications og push preview.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _flowCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: const Text(
        'Testflyt:\n'
        '1. Seed offer i Dev Tools\n'
        '2. Se aktiverte varsler i Notifications\n'
        '3. Se dispatch i Push Preview\n'
        '4. Verifiser devices i Device Monitor',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Control Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 16),
          _flowCard(),
          const SizedBox(height: 16),
          _entry(
            context,
            icon: Icons.build_circle_outlined,
            title: 'Dev Tools',
            subtitle: 'Seed offer og test API-flyt',
            page: const BonusvarselDevToolsPage(),
          ),
          _entry(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Se aktiverte kampanjevarsler',
            page: const BonusvarselNotificationsPage(),
          ),
          _entry(
            context,
            icon: Icons.send_outlined,
            title: 'Push Preview',
            subtitle: 'Se dispatch preview per device',
            page: const BonusvarselPushPreviewPage(),
          ),
          _entry(
            context,
            icon: Icons.devices_outlined,
            title: 'Device Monitor',
            subtitle: 'Se registrerte devices',
            page: const BonusvarselDeviceMonitorPage(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
