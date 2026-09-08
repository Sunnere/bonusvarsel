import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read()

import_anchor = "import '../services/entitlement_service.dart';\n"
if src.count(import_anchor) != 1:
    print(f"ABORT (import): fant ankeret {src.count(import_anchor)} ganger, forventet 1.")
    sys.exit(1)
src = src.replace(import_anchor, import_anchor + "import 'package:home_widget/home_widget.dart';\n", 1)

ctrl_anchor = "  // Nåværende poeng\n  final _pointsCtrl = TextEditingController(text: '0');\n"
if src.count(ctrl_anchor) != 1:
    print(f"ABORT (ctrl): fant ankeret {src.count(ctrl_anchor)} ganger, forventet 1.")
    sys.exit(1)
ctrl_addition = ctrl_anchor + "\n  // Nåværende Trumf-saldo (kr)\n  final _trumfKrCtrl = TextEditingController(text: '0');\n"
src = src.replace(ctrl_anchor, ctrl_addition, 1)

dispose_anchor = "    _destCtrl.dispose();\n    _pointsCtrl.dispose();\n    super.dispose();\n"
if src.count(dispose_anchor) != 1:
    print(f"ABORT (dispose): fant ankeret {src.count(dispose_anchor)} ganger, forventet 1.")
    sys.exit(1)
dispose_addition = "    _destCtrl.dispose();\n    _pointsCtrl.dispose();\n    _trumfKrCtrl.dispose();\n    super.dispose();\n"
src = src.replace(dispose_anchor, dispose_addition, 1)

load_anchor = """    if (!mounted) return;
    setState(() {
      _cardIds = ids;
      _cardRatePer100 = best;
      _hasAmex = ids.contains('sas_amex');
      _isTrumfMember = trumf;
    });
  }
"""
if src.count(load_anchor) != 1:
    print(f"ABORT (load): fant ankeret {src.count(load_anchor)} ganger, forventet 1.")
    sys.exit(1)

load_addition = """    final savedPoints = await UserState.getEurobonusPoints();
    final savedTrumfKr = await UserState.getTrumfPoints();
    if (!mounted) return;
    setState(() {
      _cardIds = ids;
      _cardRatePer100 = best;
      _hasAmex = ids.contains('sas_amex');
      _isTrumfMember = trumf;
      if (savedPoints > 0) _pointsCtrl.text = savedPoints.toString();
      if (savedTrumfKr > 0) _trumfKrCtrl.text = savedTrumfKr.toString();
    });
  }

  Future<void> _saveEuroBonusPoints(String value) async {
    final points = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {});
    await UserState.setEurobonusPoints(points);
    await HomeWidget.saveWidgetData<int>('widget_points', points);
    await HomeWidget.updateWidget(iOSName: 'BonusWidget');
  }

  Future<void> _saveTrumfKr(String value) async {
    final kr = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {});
    await UserState.setTrumfPoints(kr);
    await HomeWidget.saveWidgetData<int>('widget_trumf_points', kr);
    await HomeWidget.updateWidget(iOSName: 'BonusWidget');
  }
"""
src = src.replace(load_anchor, load_addition, 1)

field_anchor = """        TextField(
          controller: _pointsCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _text, fontSize: 22,
              fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            labelText: 'Nåværende poeng',
            labelStyle: const TextStyle(color: _textMuted),
            filled: true, fillColor: _surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
            hintText: '0',
            hintStyle: const TextStyle(color: Colors.white24),
            suffixText: 'poeng',
            suffixStyle: const TextStyle(color: _textMuted),
          ),
        ),
        if (_currentPoints > 0) ...["""
if src.count(field_anchor) != 1:
    print(f"ABORT (field): fant ankeret {src.count(field_anchor)} ganger, forventet 1.")
    sys.exit(1)

field_addition = """        TextField(
          controller: _pointsCtrl,
          onChanged: (v) { setState(() {}); _saveEuroBonusPoints(v); },
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _text, fontSize: 22,
              fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            labelText: 'Nåværende poeng',
            labelStyle: const TextStyle(color: _textMuted),
            filled: true, fillColor: _surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
            hintText: '0',
            hintStyle: const TextStyle(color: Colors.white24),
            suffixText: 'poeng',
            suffixStyle: const TextStyle(color: _textMuted),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _trumfKrCtrl,
          onChanged: (v) { setState(() {}); _saveTrumfKr(v); },
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _text, fontSize: 22,
              fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            labelText: 'Trumf-saldo',
            labelStyle: const TextStyle(color: _textMuted),
            filled: true, fillColor: _surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
            hintText: '0',
            hintStyle: const TextStyle(color: Colors.white24),
            suffixText: 'kr',
            suffixStyle: const TextStyle(color: _textMuted),
          ),
        ),
        if (_currentPoints > 0) ...["""
src = src.replace(field_anchor, field_addition, 1)

open(path, 'w', encoding='utf-8').write(src)
print("OK: Trumf-saldo (kr) lagt til i travel_page.dart, EuroBonus-poeng nå persistert.")
