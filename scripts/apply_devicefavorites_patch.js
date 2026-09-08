// scripts/apply_devicefavorites_patch.js
//
// Kjøres én gang for å koble server.js til deviceFavoritesStore.
// Gjør 3 presise tekst-erstatninger. Feiler tydelig (uten å endre filen)
// hvis ankerteksten ikke finnes nøyaktig, eller hvis patchen allerede er
// anvendt fra før.

const fs = require('fs');
const path = require('path');

const SERVER_PATH = path.join(__dirname, '..', 'api', 'server.js');

let content = fs.readFileSync(SERVER_PATH, 'utf8');
const original = content;

if (content.includes('deviceFavoritesStore.init()')) {
  console.error('FEIL: server.js er allerede patchet (fant "deviceFavoritesStore.init()"). Avbryter uten å endre noe.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen endringer gjort. Sjekk at server.js matcher det forventede.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter for sikkerhets skyld.`);
  }
  return content.replace(search, replace);
}

content = replaceOnce(
  content,
  `const sentKeysStore = require('./lib/sentKeysStore');`,
  `const sentKeysStore = require('./lib/sentKeysStore');\nconst deviceFavoritesStore = require('./lib/deviceFavoritesStore');`,
  'require deviceFavoritesStore'
);

content = replaceOnce(
  content,
  `const deviceFavorites = {};`,
  `const deviceFavorites = {};\n\ndeviceFavoritesStore.init();\n(async () => {\n  const loaded = await deviceFavoritesStore.loadAll();\n  Object.assign(deviceFavorites, loaded);\n  console.log(\`[deviceFavorites] Lastet \${Object.keys(loaded).length} enheter fra Firestore (mode=\${deviceFavoritesStore.getMode()})\`);\n})();`,
  'init + hydrering av deviceFavorites'
);

content = replaceOnce(
  content,
  `  deviceFavorites[deviceId] = { trumf: trumfCapped, sas: sasCapped, email, telegram, tier, updatedAt: new Date().toISOString() };`,
  `  deviceFavorites[deviceId] = { trumf: trumfCapped, sas: sasCapped, email, telegram, tier, updatedAt: new Date().toISOString() };\n\n  deviceFavoritesStore.persist(deviceId, deviceFavorites[deviceId]).catch((err) => {\n    console.error(\`[v1/devices/favorites] Persistering feilet for \${deviceId}:\`, err.message);\n  });`,
  'persist ved skriving'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet - sjekk scriptet).');
  process.exit(1);
}

const backupPath = SERVER_PATH + `.bak_devicefavorites_patch.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(SERVER_PATH, content, 'utf8');

console.log(`OK: server.js oppdatert. Backup lagret som ${path.basename(backupPath)}`);
console.log('Endringer gjort:');
console.log('  1. require deviceFavoritesStore');
console.log('  2. init + hydrering av deviceFavorites ved oppstart');
console.log('  3. persist() kalt ved hver skriving i POST /v1/devices/favorites');
