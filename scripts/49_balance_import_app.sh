#!/usr/bin/env bash
# 49_balance_import_app.sh — Fase 2: importer saldo fra skjermbilde (Premium/Elite) i Reise-fanen
# Kjør: bash scripts/49_balance_import_app.sh   (fra ~/bonusvarsel, eller sett REPO=...)
set -euo pipefail
REPO="${REPO:-$HOME/bonusvarsel}"
cd "$REPO"
for f in pubspec.yaml lib/pages/travel_page.dart ios/Runner/Info.plist; do
  [ -f "$f" ] || { echo "❌ Mangler $f i $REPO"; exit 1; }
done
B=".script_backups"; mkdir -p "$B"; T=$(date +%s)
cp pubspec.yaml "$B/pubspec.yaml.bak_49_$T"
cp lib/pages/travel_page.dart "$B/travel_page.dart.bak_49_$T"
cp ios/Runner/Info.plist "$B/Info.plist.bak_49_$T"

cat > lib/services/balance_import_service.dart <<'EOF'
import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ImportedBalance {
  final String program;
  final int value;
  final String confidence;
  final String label;
  const ImportedBalance(this.program, this.value, this.confidence, this.label);
}

class BalanceImportException implements Exception {
  final String message;
  const BalanceImportException(this.message);
  @override
  String toString() => message;
}

class BalanceImportService {
  /// Velger skjermbilde fra galleriet og sender det til Claude. Returnerer null hvis bruker avbryter.
  static Future<List<ImportedBalance>?> pickAndRead() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final bytes = await File(picked.path).readAsBytes();
    final lower = picked.path.toLowerCase();
    final mediaType = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final callable = FirebaseFunctions.instance.httpsCallable(
        'importBalance',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
      final res = await callable.call({
        'imageBase64': base64Encode(bytes),
        'mediaType': mediaType,
      });
      final raw = (res.data['balances'] as List?) ?? const [];
      return [
        for (final b in raw)
          ImportedBalance(
            b['program'] as String,
            (b['value'] as num).toInt(),
            (b['confidence'] as String?) ?? 'low',
            (b['label'] as String?) ?? '',
          ),
      ];
    } on FirebaseFunctionsException catch (e) {
      throw BalanceImportException(e.message ?? 'Kunne ikke lese skjermbildet.');
    } catch (_) {
      throw const BalanceImportException('Kunne ikke lese skjermbildet. Prøv igjen.');
    }
  }
}
EOF

cat > lib/widgets/balance_import_sheet.dart <<'EOF'
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
EOF

python3 - <<'PY'
import re, sys
# pubspec
p = open('pubspec.yaml').read()
if 'image_picker:' not in p:
    assert '  cloud_functions:' in p, 'fant ikke cloud_functions i pubspec'
    p = re.sub(r'(  cloud_functions:[^\n]*\n)', r'\1  image_picker: ^1.1.2\n', p, count=1)
    open('pubspec.yaml','w').write(p)
# Info.plist
pl = open('ios/Runner/Info.plist').read()
if 'NSPhotoLibraryUsageDescription' not in pl:
    i = pl.rindex('</dict>')
    pl = pl[:i] + '\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Bonusvarsel bruker valgt skjermbilde til å lese saldoen din. Bildet lagres ikke.</string>\n' + pl[i:]
    open('ios/Runner/Info.plist','w').write(pl)
# travel_page
f = 'lib/pages/travel_page.dart'
t = open(f).read()
if 'balance_import_service' not in t:
    imp = "import 'premium_page.dart';\n"
    assert imp in t
    t = t.replace(imp, imp + "import '../services/balance_import_service.dart';\nimport '../widgets/balance_import_sheet.dart';\n", 1)
    fld = "  final _aviosCtrl = TextEditingController(text: '0');\n"
    assert fld in t
    t = t.replace(fld, fld + "  bool _importing = false;\n", 1)
    anchor = "  // ── Beregninger ──"
    assert t.count(anchor) == 1, 'anker Beregninger'
    methods = '''  // ── Import fra skjermbilde (Fase 2, Premium/Elite) ───────────────────────
  Future<void> _importFromScreenshot() async {
    if (!EntitlementService.instance.isPremium) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _importing = true);
    try {
      final found = await BalanceImportService.pickAndRead();
      if (found == null || !mounted) return;
      final picked = await showBalanceImportSheet(context, found);
      if (picked == null || picked.isEmpty) return;
      await _applyImported(picked);
      messenger.showSnackBar(SnackBar(content: Text('Lagret ${picked.length} saldo(er)')));
    } on BalanceImportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _applyImported(Map<String, int> picked) async {
    for (final e in picked.entries) {
      final id = e.key;
      final v = e.value;
      if (id == 'eurobonus') {
        _pointsCtrl.text = '$v';
        await _saveEuroBonusPoints('$v');
      } else if (id == 'trumf') {
        _trumfKrCtrl.text = '$v';
        await _saveTrumfKr('$v');
      } else {
        final ctrl = {
          'spenn': _spennCtrl,
          'cashpoints': _cashCtrl,
          'avios': _aviosCtrl,
          'amexmr': _mrCtrl,
        }[id];
        if (ctrl == null) continue;
        ctrl.text = '$v';
        await _saveBalance(id, '$v', widgetKey: id == 'spenn' ? 'widget_spenn_points' : null);
        if (!_enabledExtra.contains(id)) await _toggleProgram(id, true);
      }
    }
    if (mounted) setState(() {});
  }

'''
    t = t.replace(anchor, methods + anchor, 1)
    old = "        const Text('Flere programmer',"
    assert t.count(old) == 1, 'anker Flere programmer'
    btn = '''        OutlinedButton.icon(
          onPressed: _importing ? null : _importFromScreenshot,
          icon: Icon(_importing ? Icons.hourglass_empty : Icons.photo_camera_outlined, size: 18),
          label: Text(EntitlementService.instance.isPremium
              ? 'Importer saldo fra skjermbilde'
              : 'Importer saldo fra skjermbilde (Premium)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _border),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
'''
    t = t.replace(old, btn + old, 1)
    open(f,'w').write(t)
print('patch ok')
PY

flutter pub get >/dev/null
flutter analyze lib/pages/travel_page.dart lib/services/balance_import_service.dart lib/widgets/balance_import_sheet.dart
echo "✅ Fase 2 app-kode lagt inn. Kjør: flutter run -d 00008110-001138643E60401E --release"
