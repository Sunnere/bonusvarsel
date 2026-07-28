// scripts/apply_notification_model_fix.mjs
//
// Retter notification_service.dart mot den faktiske OfferFeedItem-modellen:
//   - item.store        -> item.storeName      (feltet heter storeName)
//   - i.hasCampaign     -> i.campaign.isNotEmpty (campaign er en String)
//   - rate ?? 0 / rate! -> rate direkte        (rate er ikke-nullbar double)
//
// Kjør med: node scripts/apply_notification_model_fix.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'lib', 'services', 'notification_service.dart');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('item.storeName')) {
  console.error('FEIL: notification_service.dart ser allerede patchet ut (fant "item.storeName"). Avbryter uten å endre noe.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen endringer gjort.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter.`);
  }
  return content.replace(search, replace);
}

content = replaceOnce(
  content,
  `      final all = await repo.fetchActiveItems(program: 'sas_online', forceRefresh: true);
      if (sasFavs.isNotEmpty) {
        final fav = all.where((item) => sasFavs.any((f) =>
          item.store.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final defaults = all.where((item) => _sasDefaultShops.any((s) =>
        item.store.toLowerCase().contains(s.toLowerCase()))).toList();
      defaults.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));`,
  `      final all = await repo.fetchActiveItems(program: 'sas_online', forceRefresh: true);
      if (sasFavs.isNotEmpty) {
        final fav = all.where((item) => sasFavs.any((f) =>
          item.storeName.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final defaults = all.where((item) => _sasDefaultShops.any((s) =>
        item.storeName.toLowerCase().contains(s.toLowerCase()))).toList();
      defaults.sort((a, b) => b.rate.compareTo(a.rate));`,
  '_fetchSasOffers'
);

content = replaceOnce(
  content,
  `      final all = await repo.fetchActiveItems(program: 'trumf_netthandel', forceRefresh: true);
      if (trumfFavs.isNotEmpty) {
        final fav = all.where((item) => trumfFavs.any((f) =>
          item.store.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final withCamp = all.where((i) => i.hasCampaign == true).toList();
      withCamp.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));
      if (withCamp.isNotEmpty) return withCamp.take(3).toList();
      all.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));`,
  `      final all = await repo.fetchActiveItems(program: 'trumf_netthandel', forceRefresh: true);
      if (trumfFavs.isNotEmpty) {
        final fav = all.where((item) => trumfFavs.any((f) =>
          item.storeName.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final withCamp = all.where((i) => i.campaign.isNotEmpty).toList();
      withCamp.sort((a, b) => b.rate.compareTo(a.rate));
      if (withCamp.isNotEmpty) return withCamp.take(3).toList();
      all.sort((a, b) => b.rate.compareTo(a.rate));`,
  '_fetchTrumfOffers'
);

content = replaceOnce(
  content,
  `      for (final item in trumfItems) {
        final rate = item.rate != null ? ' – \${item.rate!.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• \${item.store}\$rate');
      }`,
  `      for (final item in trumfItems) {
        final rate = item.rate > 0 ? ' – \${item.rate.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• \${item.storeName}\$rate');
      }`,
  '_buildMessage trumf-løkke'
);

content = replaceOnce(
  content,
  `      for (final item in sasItems) {
        final rate = item.rate != null ? ' – \${item.rate!.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• \${item.store}\$rate');
      }`,
  `      for (final item in sasItems) {
        final rate = item.rate > 0 ? ' – \${item.rate.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• \${item.storeName}\$rate');
      }`,
  '_buildMessage sas-løkke'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_notification_model_fix.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: notification_service.dart oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Rettelser:');
console.log('  - item.store -> item.storeName (5 steder)');
console.log('  - i.hasCampaign == true -> i.campaign.isNotEmpty');
console.log('  - (rate ?? 0) og rate! -> rate direkte (rate er ikke-nullbar)');
console.log('');
console.log('Kjør nå: flutter analyze');
