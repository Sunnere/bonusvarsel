#!/bin/bash
set -e

python3 << 'PYEOF'
path = "/Users/sunnerehelse/bonusvarsel/lib/pages/bonusvarsel_alerts_page.dart"
with open(path, "r") as f:
    content = f.read()

old = """  // Favoritter
  List<String> _favorites = [];
  final _favCtrl = TextEditingController();"""

new = """  // Favoritter
  List<String> _favorites = [];
  final _favCtrl = TextEditingController();

  // Kjente SAS og Trumf-partnere
  static const _sasPartners = [
    'Elkjøp', 'H&M', 'Zalando', 'ASOS', 'Booking.com', 'Hotels.com',
    'Expedia', 'Rentalcars', 'Nike', 'Adidas', 'Apple', 'Samsung',
    'Komplett', 'Power', 'Storytelling', 'Ving', 'Apolloreiser',
    'Norwegian', 'Finn.no reise', 'Ticket', 'Ebookers',
  ];

  static const _trumfPartners = [
    'Kiwi', 'Meny', 'Spar', 'Joker', 'Naustvik', 'Eurospar',
    'Uno-X', 'Circle K', 'Reitan', 'Bunnpris',
    'XXL', 'Intersport', 'Stadium', 'Sport1',
    'Clas Ohlson', 'Jernia', 'JYSK', 'Skeidar',
    'Trumf Netthandel', 'Netthandel via Trumf',
  ];"""

content = content.replace(old, new)

# Erstatt favoritt-input med dropdown/søk
old2 = """            if (_isPremium) ...[
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _favCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addFavorite(),
                    decoration: const InputDecoration(
                      labelText: 'Legg til butikk',
                      hintText: 'f.eks. Elkjøp, Zalando...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addFavorite,
                  child: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 12),
              if (_favorites.isEmpty)
                const Text('Ingen favoritter lagt til ennå.',
                  style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites.map((fav) => Chip(
                    label: Text(fav),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFavorite(fav),
                  )).toList(),
                ),"""

new2 = """            if (_isPremium) ...[
              const Text('SAS Online Shopping:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sasPartners.map((partner) {
                  final isAdded = _favorites.contains(partner);
                  return FilterChip(
                    label: Text(partner),
                    selected: isAdded,
                    onSelected: (_) => isAdded ? _removeFavorite(partner) : _addFavoriteItem(partner),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Trumf-partnere:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _trumfPartners.map((partner) {
                  final isAdded = _favorites.contains(partner);
                  return FilterChip(
                    label: Text(partner),
                    selected: isAdded,
                    onSelected: (_) => isAdded ? _removeFavorite(partner) : _addFavoriteItem(partner),
                  );
                }).toList(),
              ),
              if (_favorites.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Dine favoritter:', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites.map((fav) => Chip(
                    label: Text(fav),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFavorite(fav),
                  )).toList(),
                ),
              ],"""

content = content.replace(old2, new2)

# Legg til _addFavoriteItem metode
old3 = """  Future<void> _addFavorite() async {
    final fav = _favCtrl.text.trim();
    if (fav.isEmpty || _favorites.contains(fav)) return;
    final newFavs = [..._favorites, fav];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, newFavs);
    setState(() {
      _favorites = newFavs;
      _favCtrl.clear();
    });
  }"""

new3 = """  Future<void> _addFavorite() async {
    final fav = _favCtrl.text.trim();
    if (fav.isEmpty || _favorites.contains(fav)) return;
    await _addFavoriteItem(fav);
    _favCtrl.clear();
  }

  Future<void> _addFavoriteItem(String fav) async {
    if (_favorites.contains(fav)) return;
    final newFavs = [..._favorites, fav];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, newFavs);
    setState(() => _favorites = newFavs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fav lagt til i favoritter!')),
    );
  }"""

content = content.replace(old3, new3)

with open(path, "w") as f:
    f.write(content)
print("✅ Favoritter oppdatert med SAS og Trumf-partnere")
PYEOF
