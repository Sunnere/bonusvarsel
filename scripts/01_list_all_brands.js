const admin = require('firebase-admin');
const sa = require('../serviceAccount.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function run() {
  const productsSnap = await db.collection('products').get();
  const brands = new Set();
  productsSnap.forEach(doc => brands.add(doc.data().brand || '(ukjent)'));

  console.log(`\n=== ${brands.size} unike brands i products-collection (${productsSnap.size} produkter totalt) ===\n`);
  [...brands].sort((a, b) => a.localeCompare(b, 'nb')).forEach(b => console.log('-', b));

  const brSnap = await db.collection('brand_restrictions').get();
  const brMap = {};
  brSnap.forEach(doc => { brMap[doc.id] = doc.data(); });

  console.log(`\n=== Cashback-status per brand ===\n`);
  [...brands].sort((a, b) => a.localeCompare(b, 'nb')).forEach(b => {
    const data = brMap[b];
    if (!data) {
      console.log(`  ${b.padEnd(30)} ⚠️  MANGLER i brand_restrictions`);
    } else {
      const eligible = data.cashbackEligible !== false;
      const pct = data.cashbackPercent ? `${data.cashbackPercent}%` : 'ingen %';
      console.log(`  ${b.padEnd(30)} ${eligible ? '✓ cashback ' + pct : '✗ ikke cashback'}`);
    }
  });

  console.log(`\n${brSnap.size} docs i brand_restrictions totalt\n`);
  process.exit(0);
}

run().catch(err => {
  console.error('Feil:', err.message);
  process.exit(1);
});
