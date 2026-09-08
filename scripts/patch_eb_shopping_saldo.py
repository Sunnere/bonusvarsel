import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read()

# 1. Imports
import_anchor = "import '../services/api_service.dart';\n"
if src.count(import_anchor) != 1:
    print(f"ABORT (imports): fant ankeret {src.count(import_anchor)} ganger, forventet 1.")
    sys.exit(1)
new_imports = import_anchor + "import 'package:home_widget/home_widget.dart';\nimport '../services/user_state.dart';\n"
src = src.replace(import_anchor, new_imports, 1)

# 2. State-felt, controllers, metoder
state_anchor = """  Map<String, dynamic>? _topTrumf;
  Map<String, dynamic>? _topSas;
  bool _loadingTop = true;

  @override
  void initState() {
    super.initState();
    _loadTopCampaigns();
  }
"""
if src.count(state_anchor) != 1:
    print(f"ABORT (state): fant ankeret {src.count(state_anchor)} ganger, forventet 1.")
    sys.exit(1)

state_addition = """  Map<String, dynamic>? _topTrumf;
  Map<String, dynamic>? _topSas;
  bool _loadingTop = true;

  final _euroBonusCtrl = TextEditingController();
  final _trumfCtrl = TextEditingController();
  bool _savingSaldo = false;

  static const _appGroupId = 'group.com.royrotvold.bonusvarsel';

  @override
  void initState() {
    super.initState();
    _loadTopCampaigns();
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    final eb = await UserState.getEurobonusPoints();
    final trumf = await UserState.getTrumfPoints();
    if (!mounted) return;
    setState(() {
      _euroBonusCtrl.text = eb > 0 ? eb.toString() : '';
      _trumfCtrl.text = trumf > 0 ? trumf.toString() : '';
    });
  }

  Future<void> _saveSaldo() async {
    setState(() => _savingSaldo = true);
    final eb = int.tryParse(_euroBonusCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final trumf = int.tryParse(_trumfCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    await UserState.setEurobonusPoints(eb);
    await UserState.setTrumfPoints(trumf);

    await HomeWidget.saveWidgetData<int>('widget_points', eb);
    await HomeWidget.saveWidgetData<int>('widget_trumf_points', trumf);
    await HomeWidget.updateWidget(iOSName: 'BonusWidget');

    if (!mounted) return;
    setState(() => _savingSaldo = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saldo lagret og widget oppdatert'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _euroBonusCtrl.dispose();
    _trumfCtrl.dispose();
    super.dispose();
  }

  Widget _saldoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: AppTheme.activeBorder(),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📲  Min saldo (vises på hjemskjerm-widget)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Skriv inn faktisk saldo så widgeten holder seg oppdatert.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: _euroBonusCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'EuroBonus-poeng',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _trumfCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Trumf-saldo',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            )),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _savingSaldo ? null : _saveSaldo,
              child: Text(_savingSaldo ? 'Lagrer...' : 'Lagre saldo'),
            ),
          ),
        ]),
      ),
    );
  }
"""
src = src.replace(state_anchor, state_addition, 1)

# 3. Sett inn i build()
build_anchor = """          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _stepsSection()),"""
if src.count(build_anchor) != 1:
    print(f"ABORT (build): fant ankeret {src.count(build_anchor)} ganger, forventet 1.")
    sys.exit(1)
build_addition = """          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _saldoSection()),
          SliverToBoxAdapter(child: _stepsSection()),"""
src = src.replace(build_anchor, build_addition, 1)

open(path, 'w', encoding='utf-8').write(src)
print("OK: saldo-seksjon, imports og build()-innsetting fullført.")
