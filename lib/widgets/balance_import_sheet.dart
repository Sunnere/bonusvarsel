import 'package:flutter/material.dart';
import '../models/loyalty_currency.dart';
import '../services/balance_import_service.dart';

/// Viser funn fra skjermbildet. Bruker kan rette tall og velge hva som lagres.
/// Returnerer program-id -> saldo, eller null hvis avbrutt.
Future<Map<String, int>?> showBalanceImportSheet(
    BuildContext context, List<ImportedBalance> found) {
  return showModalBottomSheet<Map<String, int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF152B4A),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _BalanceImportSheet(found: found),
  );
}

class _BalanceImportSheet extends StatefulWidget {
  final List<ImportedBalance> found;
  const _BalanceImportSheet({required this.found});
  @override
  State<_BalanceImportSheet> createState() => _BalanceImportSheetState();
}

class _BalanceImportSheetState extends State<_BalanceImportSheet> {
  late final Map<String, TextEditingController> _ctrls;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final b in widget.found) b.program: TextEditingController(text: b.value.toString()),
    };
    _selected = {
      for (final b in widget.found)
        if (b.confidence != 'low') b.program,
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final out = <String, int>{};
    for (final id in _selected) {
      final v = int.tryParse(_ctrls[id]!.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (v != null) out[id] = v;
    }
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fant disse saldoene',
                style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Sjekk tallene og rett dem om nødvendig før du lagrer.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 12),
            if (widget.found.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Fant ingen saldo i bildet. Prøv et skjermbilde der saldoen er godt synlig.',
                    style: TextStyle(color: Color(0xFFCBD5E1))),
              ),
            for (final b in widget.found)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Checkbox(
                    value: _selected.contains(b.program),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(b.program);
                      } else {
                        _selected.remove(b.program);
                      }
                    }),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrls[b.program],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        labelText: LoyaltyCurrency.byId(b.program)?.name ?? b.program,
                        helperText: b.confidence == 'low' ? 'Usikker avlesning – sjekk nøye' : null,
                        helperStyle: const TextStyle(color: Color(0xFFFBBF24)),
                        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                        suffixText: LoyaltyCurrency.byId(b.program)?.unit,
                        suffixStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Avbryt'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : _save,
                  child: const Text('Lagre valgte'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
