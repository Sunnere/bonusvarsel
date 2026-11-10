import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Hva gir et kjøp i poeng?": regner poeng ut fra poeng per 100 kr.
/// Ingen faste satser: brukeren skriver inn tallet fra butikkens eller programmets side.
class PointsEarnCard extends StatefulWidget {
  const PointsEarnCard({super.key});

  @override
  State<PointsEarnCard> createState() => _PointsEarnCardState();
}

class _Src {
  final String name;
  final String unit;
  final String hint;
  final String? url;
  const _Src(this.name, this.unit, this.hint, this.url);
}

class _PointsEarnCardState extends State<PointsEarnCard> {
  static const _bg = Color(0xFF152B4A);
  static const _field = Color(0xFF0F2340);
  static const _border = Color(0xFF2F435C);
  static const _primary = Color(0xFF60A5FA);
  static const _success = Color(0xFF34D399);
  static const _text = Color(0xFFF8FAFC);
  static const _muted = Color(0xFFCBD5E1);

  static const _sources = [
    _Src(
        'SAS Online Shopping',
        'EuroBonus-poeng',
        'Åpne butikken i SAS Online Shopping (finn den under Varsler). Der står det hvor mange poeng du får per 100 kr. Satsen er ulik per butikk og kan være høyere i kampanjer. Poengene kommer senest etter 12 uker.',
        'https://onlineshopping.flysas.com/nb-NO'),
    _Src(
        'Amex Membership Rewards',
        'MR-poeng',
        'Sjekk vilkårene for kortet ditt hos Amex for poeng per 100 kr. Hvor mange EuroBonus-poeng MR-poengene blir, avhenger av overføringsforholdet hos Amex.',
        null),
    _Src(
        'Avios',
        'Avios',
        'Sjekk poeng per kr hos British Airways (Avios-shopping eller kortet ditt), og at tilbudet gjelder for Norge.',
        'https://www.britishairways.com/'),
    _Src(
        'Spenn',
        'Spenn-poeng',
        'Se Spenn-appen eller kampanjen for poeng per 100 kr. Kampanjene finner du under Varsler.',
        null),
  ];

  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  int _idx = 0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(' ', '').replaceAll(',', '.')) ?? 0;

  String _fmt(num v) {
    final s = v.round().toString();
    final chunks = <String>[];
    for (int i = s.length; i > 0; i -= 3) {
      chunks.insert(0, s.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return chunks.join(' ');
  }

  InputDecoration _dec(String label, String suffix) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _field,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final s = _sources[_idx];
    final amount = _num(_amountCtrl);
    final rate = _num(_rateCtrl);
    final pts = (amount > 0 && rate > 0) ? amount / 100 * rate : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🧮 Hva gir et kjøp i poeng?',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: _text)),
          const SizedBox(height: 6),
          const Text(
            'Velg program, skriv inn kjøpet og poeng per 100 kr. Satsene er ulike og endres i kampanjer, så vi legger ikke inn faste tall.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < _sources.length; i++)
              ChoiceChip(
                label: Text(_sources[i].name),
                selected: _idx == i,
                onSelected: (_) => setState(() => _idx = i),
                selectedColor: _primary.withValues(alpha: 0.25),
                backgroundColor: _field,
                side: const BorderSide(color: _border),
                labelStyle: const TextStyle(
                    color: _text, fontWeight: FontWeight.w700, fontSize: 12),
              ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            decoration: _dec('Kjøpet', 'kr'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            decoration: _dec('Poeng per 100 kr', 'poeng'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(s.hint,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.4)),
          if (pts > 0) ...[
            const SizedBox(height: 10),
            Text(
              '≈ ${_fmt(pts)} ${s.unit} for ${_fmt(amount)} kr',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: _success),
            ),
          ],
          if (s.url != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse(s.url!),
                    mode: LaunchMode.externalApplication),
                child: Text('Åpne ${s.name} →',
                    style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
