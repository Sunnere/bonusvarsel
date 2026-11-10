import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Bytt cashback til poeng": regner ut hvor mange poeng cashback gir.
/// Ingen faste priser: prisen per 1 000 poeng skrives inn av brukeren
/// etter å ha sjekket gjeldende pris hos programmet.
class CashbackToPointsCard extends StatefulWidget {
  const CashbackToPointsCard({super.key});

  @override
  State<CashbackToPointsCard> createState() => _CashbackToPointsCardState();
}

class _Prog {
  final String name;
  final String url;
  final bool soon;
  final bool trumf;
  const _Prog(this.name, this.url, {this.soon = false, this.trumf = false});
}

class _CashbackToPointsCardState extends State<CashbackToPointsCard> {
  static const _bg = Color(0xFF152B4A);
  static const _field = Color(0xFF0F2340);
  static const _border = Color(0xFF2F435C);
  static const _primary = Color(0xFF60A5FA);
  static const _success = Color(0xFF34D399);
  static const _text = Color(0xFFF8FAFC);
  static const _muted = Color(0xFFCBD5E1);

  static const _programs = [
    _Prog('Trumf-bonus', 'https://www.trumf.no/', trumf: true),
    _Prog('EuroBonus', 'https://www.flysas.com/no-no/'),
    _Prog('Avios', 'https://www.britishairways.com/'),
    _Prog('Spenn', 'https://spenn.com/', soon: true),
    _Prog('Flying Blue', 'https://www.flyingblue.com/', soon: true),
    _Prog('Miles & More', 'https://www.miles-and-more.com/', soon: true),
  ];

  final _trumfCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _progIdx = 0;

  @override
  void dispose() {
    _trumfCtrl.dispose();
    _cashCtrl.dispose();
    _priceCtrl.dispose();
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

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

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
    final cash = _num(_cashCtrl);
    final price = _num(_priceCtrl);
    final prog = _programs[_progIdx];
    final buyPoints = (cash > 0 && price > 0) ? cash / price * 1000 : 0.0;
    final isTrumf = prog.trumf;

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
          const Text('🔁 Bytt cashback til poeng',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: _text)),
          const SizedBox(height: 6),
          const Text(
            'Har du tjent cashback? Her ser du hva den kan bli til i poeng. '
            'Priser og kampanjer endres, så sjekk alltid gjeldende pris hos programmet før du kjøper.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // ── Kontant cashback -> kjøp poeng ──
          Text(isTrumf ? 'Trumf-bonus → EuroBonus' : 'Kontant cashback → kjøp poeng',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _primary)),
          const SizedBox(height: 4),
          Text(
            isTrumf
                ? 'Trumf-bonus kan overføres til EuroBonus. Automatisk overføring gir 13,5 poeng per krone, engangsoverføring 10 poeng per krone (samme regler som kalkulatoren over).'
                : 'Cashback fra BonusShop og andre utbetales i penger. Poeng kan kjøpes direkte hos programmene, ofte billigere i kampanjer.',
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < _programs.length; i++)
              ChoiceChip(
                label: Text(_programs[i].soon
                    ? '${_programs[i].name} · kommer'
                    : _programs[i].name),
                selected: _progIdx == i,
                onSelected: _programs[i].soon
                    ? null
                    : (_) => setState(() => _progIdx = i),
                selectedColor: _primary.withValues(alpha: 0.25),
                backgroundColor: _field,
                side: const BorderSide(color: _border),
                labelStyle: const TextStyle(
                    color: _text, fontWeight: FontWeight.w700, fontSize: 12),
              ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _cashCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            decoration: _dec(isTrumf ? 'Din Trumf-bonus' : 'Din cashback', 'kr'),
            onChanged: (_) => setState(() {}),
          ),
          if (!isTrumf) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            decoration: _dec('Pris per 1 000 poeng hos ${prog.name}', 'kr'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sjekk gjeldende pris hos programmet og skriv den inn her.',
            style: TextStyle(fontSize: 11, color: _muted),
          ),
          ],
          if (isTrumf && cash > 0) ...[
            const SizedBox(height: 10),
            Text(
              '≈ ${_fmt(cash * 13.5)} EuroBonus-poeng ved automatisk overføring',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: _success),
            ),
            const SizedBox(height: 4),
            Text(
              '≈ ${_fmt(cash * 10)} poeng ved engangsoverføring',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
          if (!isTrumf && buyPoints > 0) ...[
            const SizedBox(height: 10),
            Text(
              '≈ ${_fmt(buyPoints)} ${prog.name}-poeng for ${_fmt(cash)} kr',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: _success),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('Åpne ${prog.name}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () => _open(prog.url),
            ),
          ),
          if (prog.name == 'EuroBonus')
            Center(
              child: TextButton(
                onPressed: () => _open(
                    'https://flysas.com/au-en/help-and-contact/faq/eurobonus/can-i-buy-points-and-how-much-do-they-cost'),
                child: const Text('❓ Hvor kjøper jeg EuroBonus-poeng? →',
                    style: TextStyle(
                        color: _primary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _open('https://bonusshop.no'),
              child: const Text('💡 Tjen cashback i BonusShop →',
                  style: TextStyle(
                      color: _primary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }
}
