#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1014_real_trumf_scraper_$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old = '''// ── Trumf Netthandel kampanjer ────────────────────────────────────────────────
async function fetchTrumfCampaigns() {
  const stores = [
    { title: 'Gina Tricot', slug: 'gina-tricot', points: 60, multiplier: 6 },
    { title: 'Outnorth', slug: 'outnorth', points: 50, multiplier: 5 },
    { title: 'SmartBuyGlasses', slug: 'smartbuyglasses', points: 80, multiplier: 8 },
    { title: 'Blivakker', slug: 'blivakker', points: 30, multiplier: 3 },
    { title: 'Lyko', slug: 'lyko', points: 40, multiplier: 4 },
    { title: 'Holdit', slug: 'holdit', points: 40, multiplier: 4 },
    { title: 'XXL', slug: 'xxl', points: 30, multiplier: 3 },
    { title: 'Komplett', slug: 'komplett', points: 20, multiplier: 2 },
    { title: 'Elkjøp', slug: 'elkjop', points: 10, multiplier: 1 },
    { title: 'Scandic', slug: 'scandic', points: 50, multiplier: 5 },
    { title: 'Nordic Nest', slug: 'nordic-nest', points: 40, multiplier: 4 },
  ];
  return stores
    .filter(s => s.multiplier > 1)
    .map(s => ({ ...s, id: s.slug, source: 'trumf', url: `https://trumfnetthandel.no/butikk/${s.slug}` }));
}'''

new = '''// ── Trumf Netthandel kampanjer ────────────────────────────────────────────────
// Ekte, live skraping av https://trumfnetthandel.no/kategori/ukens-tilbud (offentlig
// side, bekreftet tilgjengelig uten innlogging). Erstatter tidligere hardkodet
// fantasidata - "multiplier" her er butikkens gjeldende Trumf-bonusprosent
// (ikke nødvendigvis "ekstra denne uken vs normalen", men ekte og ferskt tall).
async function fetchTrumfCampaigns() {
  try {
    const response = await fetch("https://trumfnetthandel.no/kategori/ukens-tilbud", {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept": "text/html",
      },
    });

    if (!response.ok) {
      throw new Error(`Trumf Netthandel skraping feilet: ${response.status}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    const mapped = [];
    $("#CategoryResults a.merchant-tile").each((_, el) => {
      const $el = $(el);
      const name = $el.attr("data-name");
      const percentageRaw = $el.attr("data-percentage") || "";
      const popularity = Number($el.attr("data-popularity") || 0);
      const href = $el.attr("href");
      if (!name || !href) return;

      const pctMatch = percentageRaw.match(/^([\\d,]+)\\s*%$/);
      if (!pctMatch) return;
      const multiplier = parseFloat(pctMatch[1].replace(",", "."));
      if (!Number.isFinite(multiplier) || multiplier <= 0) return;

      mapped.push({
        id: href,
        title: name,
        multiplier,
        url: `https://trumfnetthandel.no${href}`,
        slug: href.replace("/cashback/", ""),
        popularity,
      });
    });

    console.log("fetchTrumfCampaigns skrapet:", mapped.length, "butikker");
    return mapped;
  } catch (e) {
    console.error("fetchTrumfCampaigns feilet:", String(e));
    return [];
  }
}'''

if old not in src:
    print("❌ Fant ikke forventet fetchTrumfCampaigns()-blokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ fetchTrumfCampaigns() erstattet - henter nå ekte, live data fra trumfnetthandel.no")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
