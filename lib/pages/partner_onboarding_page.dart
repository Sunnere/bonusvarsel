import 'package:flutter/material.dart';

import '../services/referral_code_service.dart';

class PartnerOnboardingPage extends StatefulWidget {
  const PartnerOnboardingPage({super.key});

  @override
  State<PartnerOnboardingPage> createState() => _PartnerOnboardingPageState();
}

class _PartnerOnboardingPageState extends State<PartnerOnboardingPage> {
  final _svc = const ReferralCodeService();
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = await _svc.getCode();
    if (!mounted) return;
    setState(() {
      _current = code;
      if (code != null) _ctrl.text = code;
    });
  }

  Future<void> _save() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _saving = true);
    await _svc.setCode(code);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _current = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode lagret ✅')),
    );
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await _svc.clear();

    if (!mounted) return;
    setState(() {
      _saving = false;
      _current = null;
      _ctrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode fjernet')),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner-kode (BV)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skriv inn koden du fikk fra partner (kort/airline/klubb).\n'
              'Dette kan brukes for sporing av kampanjer/fordeler.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'BV-kode',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lagre'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: (_saving || _current == null) ? null : _clear,
                  child: const Text('Fjern'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_current != null)
              Text(
                'Aktiv kode: $_current',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}
