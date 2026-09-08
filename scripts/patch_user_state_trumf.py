import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read()

anchor = """  static Future<int> getEurobonusPoints() async {
    final prefs = await _p();
    return prefs.getInt(_kEurobonusPoints) ?? 0;
  }
"""

count = src.count(anchor)
if count != 1:
    print(f"ABORT: fant ankerteksten {count} ganger (forventet 1). Ingen endring gjort.")
    sys.exit(1)

addition = anchor + """
  // ── Trumf-saldo ──────────────────────────────────────────────────────
  static const _kTrumfPoints = 'trumf_points';

  static Future<void> setTrumfPoints(int points) async {
    final prefs = await _p();
    await prefs.setInt(_kTrumfPoints, points);
  }

  static Future<int> getTrumfPoints() async {
    final prefs = await _p();
    return prefs.getInt(_kTrumfPoints) ?? 0;
  }
"""

src2 = src.replace(anchor, addition, 1)
open(path, 'w', encoding='utf-8').write(src2)
print("OK: setTrumfPoints/getTrumfPoints lagt til.")
