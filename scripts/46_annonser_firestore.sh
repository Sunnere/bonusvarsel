#!/usr/bin/env bash
# 46: Annonser fra Firestore (samling "ads") med hardkodet liste som reserve.
# Remote-dokument med samme id overstyrer, nye id-er legges til, active:false skjuler.
set -euo pipefail
REPO="${REPO:-$HOME/bonusvarsel}"
F="$REPO/lib/services/ad_service.dart"
[ -f "$F" ] || { echo "Finner ikke $F"; exit 1; }
if grep -q "_inventory()" "$F"; then echo "Allerede patchet (46)."; exit 0; fi
cp "$F" "$F.bak_46"

python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

imp = "import 'package:shared_preferences/shared_preferences.dart';"
assert imp in s
s = s.replace(imp, "import 'package:cloud_firestore/cloud_firestore.dart';\n" + imp, 1)

block = r'''
  // ── Remote inventar: Firestore-samling "ads" (dokument-id = annonse-id) ──
  // Overstyrer hardkodet annonse med samme id, legger til nye, active:false skjuler.
  Map<String, AdSlot?>? _remoteDocs;
  DateTime? _remoteAt;
  static const Duration _remoteTtl = Duration(minutes: 10);

  AdSlot? _adFromDoc(String id, Map<String, dynamic> d) {
    if (d['active'] == false) return null;
    final now = DateTime.now();
    final s = d['startDate'];
    final e = d['endDate'];
    if (s is Timestamp && s.toDate().isAfter(now)) return null;
    if (e is Timestamp && e.toDate().isBefore(now)) return null;
    final title = (d['title'] ?? '').toString();
    final link = (d['link'] ?? '').toString();
    if (title.isEmpty || link.isEmpty) return null;
    final img = (d['imageUrl'] ?? '').toString();
    final tags = d['tags'] is List
        ? (d['tags'] as List).map((x) => x.toString()).toList()
        : <String>[];
    return AdSlot(
      id: id,
      title: title,
      body: (d['body'] ?? '').toString(),
      cta: (d['cta'] ?? 'Les mer').toString(),
      link: link,
      imageUrl: img.isEmpty ? null : img,
      tags: tags,
      isSponsored: d['isSponsored'] == true,
      bidCpm: (d['bidCpm'] as num?)?.toDouble() ?? 0.0,
      guaranteePerDay: (d['guaranteePerDay'] as num?)?.toInt() ?? 0,
      priority: (d['priority'] as num?)?.toInt() ?? 0,
      premiumOnly: d['premiumOnly'] == true,
    );
  }

  Future<List<AdSlot>> _inventory() async {
    final base = getCreative();
    try {
      final fresh = _remoteAt != null &&
          DateTime.now().difference(_remoteAt!) < _remoteTtl;
      if (!fresh) {
        final snap = await FirebaseFirestore.instance
            .collection('ads')
            .get()
            .timeout(const Duration(seconds: 4));
        final m = <String, AdSlot?>{};
        for (final doc in snap.docs) {
          m[doc.id] = _adFromDoc(doc.id, doc.data());
        }
        _remoteDocs = m;
        _remoteAt = DateTime.now();
      }
    } catch (_) {
      // Ingen nett / ingen tilgang: bruk forrige cache eller hardkodet liste.
      // Prøv igjen om ca. ett minutt.
      _remoteAt ??= DateTime.now().subtract(_remoteTtl - const Duration(minutes: 1));
    }
    final remote = _remoteDocs;
    if (remote == null || remote.isEmpty) return base;
    final out = <String, AdSlot>{for (final a in base) a.id: a};
    remote.forEach((id, ad) {
      if (ad == null) {
        out.remove(id);
      } else {
        out[id] = ad;
      }
    });
    return out.values.toList();
  }

'''
marker = "  Future<List<AdSlot>> pickAds({"
assert marker in s
s = s.replace(marker, block + marker, 1)

i = s.index(marker + "\n") if (marker + "\n") in s else s.index(marker)
j = s.index("final inv = getCreative();", i)
s = s[:j] + "final inv = await _inventory();" + s[j+len("final inv = getCreative();"):]
open(p, 'w', encoding='utf-8').write(s)
print("ad_service.dart: remote-annonser fra Firestore lagt inn")
PY

echo "== flutter analyze (kun feil)"
cd "$REPO"
OUT=$(flutter analyze --no-pub 2>&1 | grep -E "^\s*error" || true)
if [ -n "$OUT" ]; then
  echo "$OUT"
  cp "$F.bak_46" "$F"
  echo "FEIL - tilbakestilt."
  exit 1
fi
echo "Ingen feil. Backup: ad_service.dart.bak_46"
