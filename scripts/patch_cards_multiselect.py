#!/usr/bin/env python3
import os

path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')
with open(path, 'r') as f:
    content = f.read()
with open(path + '.bak_multi', 'w') as f:
    f.write(content)

patches = []

# ── 1. State: én ID → sett med IDer ─────────────────────────────────────
patches.append((
    "  String? _selectedCardId;",
    "  Set<String> _selectedCardIds = {};",
))

# ── 2. initState / _loadSelected ────────────────────────────────────────
patches.append((
    """  @override void initState() { super.initState(); _loadSelected(); }

  Future<void> _loadSelected() async {
    final id = await UserState.getSelectedCardId();
    if (!mounted) return;
    setState(() => _selectedCardId = id);
  }""",

    """  @override void initState() { super.initState(); _loadSelected(); }

  Future<void> _loadSelected() async {
    final ids = await UserState.getSelectedCardIds();
    // Bakoverkompatibilitet: hent enkelt-ID hvis listen er tom
    if (ids.isEmpty) {
      final id = await UserState.getSelectedCardId();
      if (id != null) ids.add(id);
    }
    if (!mounted) return;
    setState(() => _selectedCardIds = ids.toSet());
  }""",
))

# ── 3. _selectCard: radio → toggle ──────────────────────────────────────
patches.append((
    """  Future<void> _selectCard(String id, int rate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LoginPage(onSuccess: () async {
          await UserState.setSelectedCard(id, rate.toDouble());
          if (!mounted) return;
          setState(() => _selectedCardId = id);
        }),
      ));
      return;
    }
    await UserState.setSelectedCard(id, rate.toDouble());
    if (!mounted) return;
    setState(() => _selectedCardId = id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(CardCatalog.nameFor(id) + ' valgt som aktivt kort'),
      duration: const Duration(seconds: 2),
    ));
  }""",

    """  Future<void> _selectCard(String id, int rate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LoginPage(onSuccess: () async {
          await _toggleCard(id, rate);
        }),
      ));
      return;
    }
    await _toggleCard(id, rate);
  }

  Future<void> _toggleCard(String id, int rate) async {
    final isNowSelected = !_selectedCardIds.contains(id);
    if (isNowSelected) {
      await UserState.addSelectedCard(id);
      await UserState.setSelectedCard(id, rate.toDouble()); // primær = sist valgte
    } else {
      await UserState.removeSelectedCard(id);
    }
    if (!mounted) return;
    setState(() {
      if (isNowSelected) {
        _selectedCardIds.add(id);
      } else {
        _selectedCardIds.remove(id);
      }
    });
    final name = CardCatalog.nameFor(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isNowSelected ? '$name lagt til' : '$name fjernet'),
      duration: const Duration(seconds: 1),
    ));
  }""",
))

# ── 4. Hero: viser antall valgte kort ───────────────────────────────────
patches.append((
    """              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Velg bonuskort',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  selected != null ? 'Aktivt: ${selected.name}' : 'Ingen kort valgt ennå',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ])),
              if (selected != null)
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),""",

    """              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Velg bonuskort',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  _selectedCardIds.isEmpty
                    ? 'Ingen kort valgt ennå'
                    : '${_selectedCardIds.length} kort valgt',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ])),
              if (_selectedCardIds.isNotEmpty)
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white24,
                  child: Text('${_selectedCardIds.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                ),""",
))

# ── 5. build(): fjern `selected`-variabel, oppdater isSelected ───────────
patches.append((
    """    final selected = _cards.where((c) => c.id == _selectedCardId).firstOrNull;
    return Scaffold(""",
    "    return Scaffold(",
))

# ── 6. _CardTile isSelected: string-sammenligning → set.contains ─────────
patches.append((
    """          ..._cards.where((c) => c.id.startsWith('sas')).map((card) => _CardTile(
            card: card, isSelected: _selectedCardId == card.id,
            onSelect: () => _selectCard(card.id, card.ratePer100),
            onOpenUrl: () => _openUrl(card.url),
          )),""",
    """          ..._cards.where((c) => c.id.startsWith('sas')).map((card) => _CardTile(
            card: card, isSelected: _selectedCardIds.contains(card.id),
            onSelect: () => _selectCard(card.id, card.ratePer100),
            onOpenUrl: () => _openUrl(card.url),
          )),""",
))

patches.append((
    """          ..._cards.where((c) => c.id.startsWith('trumf')).map((card) => _CardTile(
            card: card, isSelected: _selectedCardId == card.id,
            onSelect: () => _selectCard(card.id, card.ratePer100),
            onOpenUrl: () => _openUrl(card.url),
          )),""",
    """          ..._cards.where((c) => c.id.startsWith('trumf')).map((card) => _CardTile(
            card: card, isSelected: _selectedCardIds.contains(card.id),
            onSelect: () => _selectCard(card.id, card.ratePer100),
            onOpenUrl: () => _openUrl(card.url),
          )),""",
))

# ── 7. Info-boks: oppdater tekst ─────────────────────────────────────────
patches.append((
    "              Text('ℹ️  Slik fungerer kortvalget',",
    "              Text('ℹ️  Slik fungerer kortvalget (multi)',",
))
patches.append((
    "                '• Valgt kort brukes til poengberegning på Reise-siden\n'",
    "                '• Velg ett eller flere kort – alle telles med i AI-slagplanen\n'"
    "                '• Siste valgte kort er primært for enkel kalkulator\n'",
))

# ── Kjør alle patches ────────────────────────────────────────────────────
ok = 0
fail = 0
for old, new in patches:
    if old in content:
        content = content.replace(old, new, 1)
        ok += 1
    else:
        print(f"❌ Fant ikke: {old[:60].strip()!r}")
        fail += 1

with open(path, 'w') as f:
    f.write(content)

print(f"\n✅ {ok} patches OK  |  ❌ {fail} feilet")

import subprocess
checks = [
    ('_selectedCardIds',   'Set<String> state'),
    ('_toggleCard',        'Toggle-funksjon'),
    ('addSelectedCard',    'UserState.addSelectedCard'),
    ('removeSelectedCard', 'UserState.removeSelectedCard'),
    ('.contains(card.id)', 'isSelected med set'),
    ('kort valgt',         'Hero-tekst'),
]
for term, label in checks:
    r = subprocess.run(['grep', '-c', term, path], capture_output=True, text=True)
    n = int(r.stdout.strip())
    print(f"  {'✅' if n > 0 else '❌'} {label} ({n})")
