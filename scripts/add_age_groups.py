#!/usr/bin/env python3
path = '/Users/sunnerehelse/bonusvarsel/lib/pages/travel_page.dart'
with open(path, 'r') as f:
    c = f.read()
with open(path + '.bak_ages', 'w') as f:
    f.write(c)

# 1. Legg til state-variabler for ungdom og spedbarn
c = c.replace(
    "  int _adults = 2;\n  int _children = 2;",
    "  int _adults = 2;\n  int _youth = 0;    // 12–25 år (SAS Young)\n  int _children = 2; // 2–11 år\n  int _infants = 0;  // 0–23 måneder (fanget)")

# 2. Oppdater _EbCost med alle aldersgrupper
c = c.replace(
    "  // Barn 2-11 år: 75% av voksen\n  static int childCost(String dest, String cabin) =>\n      (costPerPerson(dest, cabin) * 0.75).round();",
    "  // Spedbarn 0-23 mnd: 10% av voksen (sitter på fanget)\n  static int infantCost(String dest, String cabin) =>\n      (costPerPerson(dest, cabin) * 0.10).round();\n  // Barn 2-11 år: 75% av voksen (eget sete)\n  static int childCost(String dest, String cabin) =>\n      (costPerPerson(dest, cabin) * 0.75).round();\n  // Ungdom 12-25 år: SAS Young ~75% av voksen\n  static int youthCost(String dest, String cabin) =>\n      (costPerPerson(dest, cabin) * 0.75).round();")

# 3. Oppdater totalFamily til å inkludere alle grupper
c = c.replace(
    "  static int totalFamily({\n    required String dest,\n    required String cabin,\n    required int adults,\n    required int children,\n    required bool companionTicket, // Amex CT: 1 voksen gratis t/r\n  }) {\n    int adultCost = costPerPerson(dest, cabin) * 2; // t/r\n    int childCostEach = childCost(dest, cabin) * 2; // t/r\n    int totalAdults = adultCost * adults;\n    if (companionTicket && adults >= 2) {\n      totalAdults -= adultCost; // én voksen gratis\n    }\n    return totalAdults + (childCostEach * children);\n  }",
    "  static int totalFamily({\n    required String dest,\n    required String cabin,\n    required int adults,\n    required int youth,\n    required int children,\n    required int infants,\n    required bool companionTicket,\n  }) {\n    final adultCost  = costPerPerson(dest, cabin) * 2; // t/r\n    final youthEach  = youthCost(dest, cabin)  * 2;\n    final childEach  = childCost(dest, cabin)  * 2;\n    final infantEach = infantCost(dest, cabin) * 2;\n    int totalAdults = adultCost * adults;\n    if (companionTicket && adults >= 2) {\n      totalAdults -= adultCost; // én voksen gratis med Amex CT\n    }\n    return totalAdults\n        + (youthEach  * youth)\n        + (childEach  * children)\n        + (infantEach * infants);\n  }")

# 4. Oppdater _pointsNeeded getter
c = c.replace(
    "  int get _pointsNeeded => _EbCost.totalFamily(\n    dest: _dest, cabin: _cabin,\n    adults: _adults, children: _children,\n    companionTicket: _hasAmex,\n  );",
    "  int get _pointsNeeded => _EbCost.totalFamily(\n    dest: _dest, cabin: _cabin,\n    adults: _adults, youth: _youth,\n    children: _children, infants: _infants,\n    companionTicket: _hasAmex,\n  );")

# 5. Oppdater hero-tekst
c = c.replace(
    "        Text('$_adults voksne${_children > 0 ? ', $_children barn' : ''} · $_cabin',",
    "        Text(_buildPaxString() + ' · $_cabin',")

# 6. Legg til _buildPaxString metode etter _dest getter
c = c.replace(
    "  String get _dest => _destCtrl.text.trim().isEmpty ? 'Bangkok' : _destCtrl.text.trim();",
    """  String get _dest => _destCtrl.text.trim().isEmpty ? 'Bangkok' : _destCtrl.text.trim();

  String _buildPaxString() {
    final parts = <String>[];
    if (_adults > 0)   parts.add('$_adults voksen${_adults > 1 ? 'e' : ''}');
    if (_youth > 0)    parts.add('$_youth ungdom');
    if (_children > 0) parts.add('$_children barn');
    if (_infants > 0)  parts.add('$_infants spedbarn');
    return parts.join(', ');
  }""")

# 7. Oppdater reisemål-seksjonen med alle aldersgrupper
c = c.replace(
    """        _personRow('Voksne (12+)', _adults,
          onMinus: _adults > 1 ? () => setState(() => _adults--) : null,
          onPlus: () => setState(() => _adults++)),
        const SizedBox(height: 8),
        _personRow('Barn (2–11 år)', _children,
          note: '75% av voksenpris · eget sete',
          onMinus: _children > 0 ? () => setState(() => _children--) : null,
          onPlus: () => setState(() => _children++)),""",
    """        _personRow('Voksne (26+)', _adults,
          onMinus: _adults > 1 ? () => setState(() => _adults--) : null,
          onPlus: () => setState(() => _adults++)),
        const SizedBox(height: 8),
        _personRow('Ungdom (12–25 år)', _youth,
          note: 'SAS Young · ~75% av voksen',
          onMinus: _youth > 0 ? () => setState(() => _youth--) : null,
          onPlus: () => setState(() => _youth++)),
        const SizedBox(height: 8),
        _personRow('Barn (2–11 år)', _children,
          note: '75% av voksen · eget sete',
          onMinus: _children > 0 ? () => setState(() => _children--) : null,
          onPlus: () => setState(() => _children++)),
        const SizedBox(height: 8),
        _personRow('Spedbarn (0–23 mnd)', _infants,
          note: '10% av voksen · sitter på fanget',
          onMinus: _infants > 0 ? () => setState(() => _infants--) : null,
          onPlus: () => setState(() => _infants++)),""")

# 8. Oppdater kabintype totaloversikt
c = c.replace(
    "            _costRow('$_adults voksne t/r',\n              _hasAmex\n                ? '${_fmt(_EbCost.costPerPerson(_dest, _cabin) * 2 * (_adults - 1))}p  +  🎟️ 1 gratis'\n                : '${_fmt(_EbCost.costPerPerson(_dest, _cabin) * 2 * _adults)}p'),\n            if (_children > 0)\n              _costRow('$_children barn t/r',\n                '${_fmt(_EbCost.childCost(_dest, _cabin) * 2 * _children)}p'),",
    """            _costRow('$_adults voksne t/r',
              _hasAmex && _adults >= 2
                ? '\${_fmt(_EbCost.costPerPerson(_dest, _cabin) * 2 * (_adults - 1))}p  +  🎟️ 1 gratis'
                : '\${_fmt(_EbCost.costPerPerson(_dest, _cabin) * 2 * _adults)}p'),
            if (_youth > 0)
              _costRow('$_youth ungdom t/r (SAS Young)',
                '\${_fmt(_EbCost.youthCost(_dest, _cabin) * 2 * _youth)}p'),
            if (_children > 0)
              _costRow('$_children barn t/r',
                '\${_fmt(_EbCost.childCost(_dest, _cabin) * 2 * _children)}p'),
            if (_infants > 0)
              _costRow('$_infants spedbarn t/r',
                '\${_fmt(_EbCost.infantCost(_dest, _cabin) * 2 * _infants)}p'),""")

# 9. Oppdater AI getTravelPlan kall
c = c.replace(
    "        destination: _dest,\n        adults: _adults,\n        children: _children,",
    "        destination: _dest,\n        adults: _adults + _youth,\n        children: _children,")

with open(path, 'w') as f:
    f.write(c)

import subprocess
r = subprocess.run(['flutter', 'analyze', 'lib/pages/travel_page.dart'],
    capture_output=True, text=True,
    cwd='/Users/sunnerehelse/bonusvarsel')
errors = [l for l in r.stdout.splitlines() if 'error' in l.lower()]
if errors:
    for e in errors[:8]: print(f"  ❌ {e}")
else:
    print("  ✅ Ingen feil")
print("Ferdig")
