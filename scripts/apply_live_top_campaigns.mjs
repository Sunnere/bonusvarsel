// scripts/apply_live_top_campaigns.mjs
//
// Del A: Legger til ApiService.getTopCampaigns() og erstatter de to
// hardkodede butikklistene i eb_shopping_page.dart med live topp-1-kort
// per program, hentet fra /api/campaigns.
//
// Kjør med: node scripts/apply_live_top_campaigns.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const API_FILE = path.join(__dirname, '..', 'lib', 'services', 'api_service.dart');
const PAGE_FILE = path.join(__dirname, '..', 'lib', 'pages', 'eb_shopping_page.dart');

const apiContent = fs.readFileSync(API_FILE, 'utf8');
const pageContent = fs.readFileSync(PAGE_FILE, 'utf8');

if (apiContent.includes('getTopCampaigns')) {
  console.error('FEIL: api_service.dart har allerede getTopCampaigns(). Avbryter uten å endre noe.');
  process.exit(1);
}
if (pageContent.includes('_topCampaignCard')) {
  console.error('FEIL: eb_shopping_page.dart er allerede patchet. Avbryter uten å endre noe.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen filer er endret.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter.`);
  }
  return content.replace(search, replace);
}

let newApiContent = replaceOnce(
  apiContent,
  `  static Future<List<FeedItem>> getFeed() async {`,
  `  /// Henter live kampanjer fra /api/campaigns og plukker ut den beste
  /// (høyest multiplier) fra hvert program. Trumf og SAS bruker ulike
  /// poengskalaer og kan ikke rangeres mot hverandre - vi henter derfor
  /// "beste av hver" i stedet for en samlet topp-2.
  static Future<Map<String, Map<String, dynamic>?>> getTopCampaigns() async {
    try {
      final res = await http.get(_uri('/api/campaigns')).timeout(const Duration(seconds: 4));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {'trumf': null, 'sas': null};
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return {'trumf': null, 'sas': null};
      }

      final campaigns = (decoded['campaigns'] as List?) ?? const [];

      Map<String, dynamic>? bestFor(String source) {
        Map<String, dynamic>? best;
        double bestMultiplier = -1;

        for (final raw in campaigns) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          if (item['source'] != source) continue;

          final multiplier = (item['multiplier'] is num)
              ? (item['multiplier'] as num).toDouble()
              : 0.0;

          if (multiplier > bestMultiplier) {
            bestMultiplier = multiplier;
            best = item;
          }
        }
        return best;
      }

      return {
        'trumf': bestFor('trumf'),
        'sas': bestFor('sas'),
      };
    } catch (_) {
      return {'trumf': null, 'sas': null};
    }
  }

  static Future<List<FeedItem>> getFeed() async {`,
  'getTopCampaigns i api_service.dart'
);

let newPageContent = pageContent;

newPageContent = replaceOnce(
  newPageContent,
  `import '../widgets/info_video.dart';`,
  `import '../widgets/info_video.dart';\nimport '../services/api_service.dart';`,
  'import ApiService'
);

newPageContent = replaceOnce(
  newPageContent,
  `  int _sasCatIdx = 0;`,
  `  int _sasCatIdx = 0;

  Map<String, dynamic>? _topTrumf;
  Map<String, dynamic>? _topSas;
  bool _loadingTop = true;

  @override
  void initState() {
    super.initState();
    _loadTopCampaigns();
  }

  Future<void> _loadTopCampaigns() async {
    final result = await ApiService.getTopCampaigns();
    if (!mounted) return;
    setState(() {
      _topTrumf = result['trumf'];
      _topSas = result['sas'];
      _loadingTop = false;
    });
  }

  Widget _topCampaignCard({
    required String program,
    required Color accent,
    required Color bg,
  }) {
    if (_loadingTop) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final top = program == 'trumf' ? _topTrumf : _topSas;

    if (top == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Ingen aktive kampanjer akkurat nå',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      );
    }

    final title = (top['title'] ?? '').toString();
    final multiplier = (top['multiplier'] is num) ? (top['multiplier'] as num).toDouble() : 0.0;
    final url = (top['url'] ?? '').toString();

    return _shopRow(
      name: title,
      pts: multiplier.toStringAsFixed(1),
      isCampaign: true,
      badge: "BESTE NÅ",
      accent: accent,
      bg: bg,
      border: AppTheme.borderColor(EntitlementService.instance.isElite, EntitlementService.instance.isPremium),
      onTap: () => _open(url),
    );
  }`,
  'state, initState og hjelpemetoder'
);

newPageContent = replaceOnce(
  newPageContent,
  `              ..._trumfShops.map((shop) {
                final isCamp = shop["camp"] as bool;
                return _shopRow(
                  name: shop["name"] as String,
                  pts: shop["pts"] as String,
                  isCampaign: isCamp,
                  badge: isCamp ? "KAMPANJE" : null,
                  accent: _tGreen,
                  bg: _tBg,
                  border: AppTheme.borderColor(EntitlementService.instance.isElite, EntitlementService.instance.isPremium),
                  onTap: () => _open(shop["url"] as String),
                );
              }),`,
  `              _topCampaignCard(program: 'trumf', accent: _tGreen, bg: _tBg),`,
  'erstatte trumf-liste'
);

newPageContent = replaceOnce(
  newPageContent,
  `              ..._sasShops.map((shop) {
                final isPop = shop["pop"] as bool;
                return _shopRow(
                  name: shop["name"] as String,
                  pts: shop["pts"] as String,
                  isCampaign: isPop,
                  badge: isPop ? "POPULÆR" : null,
                  accent: _sBlue,
                  bg: _sBg,
                  border: AppTheme.borderColor(EntitlementService.instance.isElite, EntitlementService.instance.isPremium),
                  onTap: () => _open(shop["url"] as String),
                );
              }),`,
  `              _topCampaignCard(program: 'sas', accent: _sBlue, bg: _sBg),`,
  'erstatte sas-liste'
);

newPageContent = replaceOnce(
  newPageContent,
  `  static const _trumfShops = [
    {"name": "Gina Tricot",     "pts": "60", "camp": true,  "url": "https://trumfnetthandel.no/kategori/mote"},
    {"name": "SmartBuyGlasses", "pts": "80", "camp": true,  "url": "https://trumfnetthandel.no/cashback/smartbuyglasses-trumf"},
    {"name": "Scandic Hotels",  "pts": "40", "camp": false, "url": "https://trumfnetthandel.no/kategori/hotell"},
    {"name": "Hotels.com",      "pts": "35", "camp": false, "url": "https://trumfnetthandel.no/kategori/hotell"},
    {"name": "Expedia",         "pts": "35", "camp": false, "url": "https://trumfnetthandel.no/kategori/reise"},
    {"name": "Blivakker",       "pts": "30", "camp": false, "url": "https://trumfnetthandel.no/cashback/blivakker-trumf"},
    {"name": "H&M",             "pts": "20", "camp": false, "url": "https://trumfnetthandel.no/kategori/mote"},
  ];

  static const _sasShops = [
    {"name": "Outnorth",       "pts": "50", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO/kampanjer/1"},
    {"name": "Scandic Hotels", "pts": "20", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"name": "Expedia",        "pts": "20", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"name": "Booking.com",    "pts": "15", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"name": "Hotels.com",     "pts": "15", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"name": "Hertz",          "pts": "15", "pop": false, "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"name": "H&M",            "pts": "10", "pop": true,  "url": "https://onlineshopping.flysas.com/nb-NO"},
  ];`,
  ``,
  'fjerne hardkodede lister'
);

if (newApiContent === apiContent && newPageContent === pageContent) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const apiBackup = API_FILE + `.bak_top_campaigns.${Date.now()}`;
const pageBackup = PAGE_FILE + `.bak_top_campaigns.${Date.now()}`;
fs.writeFileSync(apiBackup, apiContent, 'utf8');
fs.writeFileSync(pageBackup, pageContent, 'utf8');
fs.writeFileSync(API_FILE, newApiContent, 'utf8');
fs.writeFileSync(PAGE_FILE, newPageContent, 'utf8');

console.log('OK: api_service.dart og eb_shopping_page.dart oppdatert');
console.log(`Backup: ${path.basename(apiBackup)}, ${path.basename(pageBackup)}`);
console.log('');
console.log('Kjør nå: flutter analyze');
