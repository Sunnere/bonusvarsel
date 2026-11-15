#!/usr/bin/env bash
# Skript 30: Felles ℹ️-info om programmer (Spenn nå + Avios/Flying Blue/Miles & More snart)
#  - NY fil lib/widgets/programs_info.dart (én kilde til teksten + dialog)
#  - Varsler-fanen: _showProgramsInfo() bruker den felles dialogen
#  - Poeng-forsiden (eb_shopping_page): ny brikke «💸 Spenn ℹ️» ved siden av Varsler
#  - Onboarding «Vi viser deg hvor du tjener mest»: nytt trykkbart kort med ℹ️
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .script_backups lib/widgets
TS="$(date +%Y%m%d_%H%M%S)"
for f in lib/pages/bonusvarsel_alerts_page.dart lib/pages/eb_shopping_page.dart lib/pages/onboarding_page.dart; do
  [[ -f "$f" ]] || { echo "❌ Mangler $f (kjør fra repo-roten)"; exit 1; }
  cp "$f" ".script_backups/$(basename "$f").$TS.bak"
done
echo "💾 Backup i .script_backups/ ($TS)"

cat > lib/widgets/programs_info.dart <<'DART'
import 'package:flutter/material.dart';

/// Felles info om programmer i Bonusvarsel. Brukes i Varsler-fanen,
/// på Poeng-forsiden og i onboarding, slik at teksten alltid er lik.
const String programsInfoTitle = '💸 Spenn og flere programmer';

const String programsInfoText =
    '✅ Du kan følge nå\n'
    '• Trumf Netthandel – ekstra bonus i favorittbutikkene dine\n'
    '• SAS Online Shopping – ekstra EuroBonus-poeng\n'
    '• Spenn – Superspenn-dager og ekstra Spenn hos REMA 1000, Norwegian m.fl.\n\n'
    '💸 Slik får du Spenn-varsler\n'
    '1. Gå til Varsler-fanen og slå på «Spenn-kampanjer»\n'
    '2. Legg inn e-post eller koble til Telegram\n'
    '3. Legg gjerne inn Spenn-saldoen din under Reis\n\n'
    '🔜 Kommer snart\n'
    '• Avios (British Airways m.fl.)\n'
    '• Flying Blue (Air France-KLM)\n'
    '• Miles & More (Lufthansa m.fl.)';

Widget _programsStep(String num, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(right: 8, top: 1),
          decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(999)),
          child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white))),
        ),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4))),
      ]),
    );

void showProgramsInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0B1728),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFFFDBA74)),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Programmer i Bonusvarsel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            const Text('✅ Du kan følge nå',
                style: TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
                '• Trumf Netthandel – ekstra bonus i favorittbutikkene dine\n'
                '• SAS Online Shopping – ekstra EuroBonus-poeng\n'
                '• Spenn – Superspenn-dager og ekstra Spenn hos REMA 1000, Norwegian m.fl.',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.5)),
            const SizedBox(height: 16),
            const Text('💸 Slik får du Spenn-varsler',
                style: TextStyle(
                    color: Color(0xFFFDBA74),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            _programsStep('1', 'Gå til Varsler-fanen og slå på «Spenn-kampanjer»'),
            _programsStep('2', 'Legg inn e-post eller koble til Telegram'),
            _programsStep('3', 'Legg gjerne inn Spenn-saldoen din under Reis'),
            const SizedBox(height: 16),
            const Text('🔜 Kommer snart',
                style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
                '• Avios (British Airways m.fl.)\n'
                '• Flying Blue (Air France-KLM)\n'
                '• Miles & More (Lufthansa m.fl.)',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFFCBD5E1), height: 1.5)),
          ],
        ),
      ),
    ),
  );
}
DART
echo "✅ Skrev lib/widgets/programs_info.dart"

python3 - <<'PY'
import re, sys

def load(p): return open(p, encoding='utf-8').read()
def save(p, s): open(p, 'w', encoding='utf-8').write(s)
def add_import(s, imp):
    if imp in s: return s
    m = re.search(r"^import .*;\n", s, re.M)
    return s[:m.end()] + imp + "\n" + s[m.end():]

# 1) Varsler-fanen: bruk felles dialog
p = 'lib/pages/bonusvarsel_alerts_page.dart'
s = load(p)
a = s.find("  void _showProgramsInfo() {")
b = s.find("  Widget _hero() => Container(", a)
if a < 0 or b < 0: print("❌ Fant ikke _showProgramsInfo/_hero i", p); sys.exit(1)
s = s[:a] + "  void _showProgramsInfo() => showProgramsInfo(context);\n\n" + s[b:]
s = add_import(s, "import '../widgets/programs_info.dart';")
save(p, s); print("✅ Patchet", p)

# 2) Poeng-forsiden: ny brikke
p = 'lib/pages/eb_shopping_page.dart'
s = load(p)
old = 'Premium: 5 favoritter. Elite: 10 favoritter."),\n          ]),'
new = ('Premium: 5 favoritter. Elite: 10 favoritter."),\n'
       '            _infoChip(context, "💸 Spenn", programsInfoTitle, programsInfoText),\n'
       '          ]),')
if s.count(old) != 1: print("❌ Fant ikke Varsler-brikken i", p, "antall:", s.count(old)); sys.exit(1)
s = s.replace(old, new)
s = add_import(s, "import '../widgets/programs_info.dart';")
save(p, s); print("✅ Patchet", p)

# 3) Onboarding: trykkbart kort med ℹ️
p = 'lib/pages/onboarding_page.dart'
s = load(p)
old = ("          subtitle: 'Se hvilke valg som kan gi mest verdi.',\n"
       "          accent: _blue,\n"
       "        ),\n"
       "      ],")
new = ("          subtitle: 'Se hvilke valg som kan gi mest verdi.',\n"
       "          accent: _blue,\n"
       "        ),\n"
       "        GestureDetector(\n"
       "          onTap: () => showProgramsInfo(context),\n"
       "          child: _bullet(\n"
       "            icon: Icons.info_outline,\n"
       "            title: 'NYTT: Spenn-varsler 💸',\n"
       "            subtitle: 'Trykk for å se hva du kan følge nå – og hva som kommer snart (Avios, Flying Blue, Miles & More).',\n"
       "            accent: Colors.orangeAccent,\n"
       "          ),\n"
       "        ),\n"
       "      ],")
if s.count(old) != 1: print("❌ Fant ikke 'Kort og kampanjer' i", p, "antall:", s.count(old)); sys.exit(1)
s = s.replace(old, new)
s = add_import(s, "import '../widgets/programs_info.dart';")
save(p, s); print("✅ Patchet", p)
PY

dart format lib/widgets/programs_info.dart >/dev/null 2>&1 || true
echo "🔎 flutter analyze (kun berørte filer)…"
flutter analyze lib/widgets/programs_info.dart lib/pages/bonusvarsel_alerts_page.dart lib/pages/eb_shopping_page.dart lib/pages/onboarding_page.dart 2>&1 | tail -25 || true
echo "➡️  Test: flutter run --release -d 00008110-001138643E60401E"
