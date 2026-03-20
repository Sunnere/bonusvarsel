import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';

class BonusvarselDeviceMonitorPage extends StatefulWidget {
  const BonusvarselDeviceMonitorPage({super.key});

  @override
  State<BonusvarselDeviceMonitorPage> createState() =>
      _BonusvarselDeviceMonitorPageState();
}

class _BonusvarselDeviceMonitorPageState
    extends State<BonusvarselDeviceMonitorPage> {
  late Future<List<Map<String, dynamic>>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _devicesFuture = ApiService.getDevices();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _devicesFuture;
  }

  Widget _header(int count) {
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
      child: Text(
        'Registrerte devices ($count)',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.surface,
        ),
      ),
    );
  }

  Widget _deviceCard(Map<String, dynamic> item) {
    final token = (item['token'] ?? '').toString();
    final platform = (item['platform'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.devices_outlined),
        title: Text(
          platform.isEmpty ? 'unknown' : platform,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(token.isEmpty ? '(mangler token)' : token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Monitor'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _devicesFuture,
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

            final devices = snapshot.data ?? <Map<String, dynamic>>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(devices.length),
                const SizedBox(height: 16),
                if (devices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text('Ingen devices registrert ennå.'),
                  )
                else
                  ...devices.map(_deviceCard),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
