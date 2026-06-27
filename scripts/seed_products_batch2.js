// seed_products_batch2.js
// Kjør med: node scripts/seed_products_batch2.js
// Krever: npm install firebase-admin (i prosjektmappa)
// Sett GOOGLE_APPLICATION_CREDENTIALS til din serviceAccount.json

const admin = require('firebase-admin');

// Hvis du bruker serviceAccount-fil:
// const serviceAccount = require('../serviceAccount.json');
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Eller bruk application default credentials (hvis logget inn med gcloud):
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'marketplace-app-f5152',
});

const db = admin.firestore();

const products = [
  { name: 'Proteinpulver - Vanilje 1kg', description: 'Høykvalitets whey-protein med 25g protein per porsjon. Naturlig smak, uten kunstige søtningsstoffer.', price: 349.0, imageUrl: 'https://picsum.photos/seed/protein1/400/300', category: 'Helse & Trening', stock: 80 },
  { name: 'Treningsstrikk sett (3 stk)', description: 'Motstandsstrikker i tre nivåer – lett, medium og tung. Perfekt for hjemmetrening.', price: 149.0, imageUrl: 'https://picsum.photos/seed/bands/400/300', category: 'Sport', stock: 120 },
  { name: 'Løpesko - Herre', description: 'Lette løpesko med god demping og pustende materiale. Passer for asfalt og lette stier.', price: 799.0, imageUrl: 'https://picsum.photos/seed/shoes1/400/300', category: 'Sport', stock: 40 },
  { name: 'Vannflaske 750ml - BPA-fri', description: 'Isolert vannflaske som holder drikken kald i 24 timer og varm i 12 timer.', price: 199.0, imageUrl: 'https://picsum.photos/seed/bottle1/400/300', category: 'Sport', stock: 150 },
  { name: 'Bluetooth høyttaler - Kompakt', description: 'Vanntett Bluetooth-høyttaler med 12 timers batteritid. IPX6-sertifisert.', price: 449.0, imageUrl: 'https://picsum.photos/seed/speaker1/400/300', category: 'Elektronikk', stock: 60 },
  { name: 'USB-C lader 65W', description: 'Rask lader kompatibel med MacBook, iPad, Samsung og de fleste USB-C-enheter.', price: 249.0, imageUrl: 'https://picsum.photos/seed/charger1/400/300', category: 'Elektronikk', stock: 90 },
  { name: 'Powerbank 20 000mAh', description: 'Bærbar batteripakke med to USB-A og én USB-C port. Ladetid ca 3.5 timer.', price: 349.0, imageUrl: 'https://picsum.photos/seed/powerbank/400/300', category: 'Elektronikk', stock: 70 },
  { name: 'Kaffetrakter med termos', description: 'Drypp-kaffetrakter med integrert termos. Holder kaffen varm i opptil 3 timer.', price: 499.0, imageUrl: 'https://picsum.photos/seed/coffee1/400/300', category: 'Kjøkken', stock: 45 },
  { name: 'Knivblokk sett - 5 kniver', description: 'Rustfritt stål, ergonomiske håndtak. Inkluderer kokkekniv, brødkniv, filekniv og to universalkniver.', price: 599.0, imageUrl: 'https://picsum.photos/seed/knives/400/300', category: 'Kjøkken', stock: 35 },
  { name: 'Airfryer 4.5 liter', description: 'Stek, bak og grill med lite eller ingen olje. Kapasitet 4.5L, passer for 2–4 personer.', price: 899.0, imageUrl: 'https://picsum.photos/seed/airfryer/400/300', category: 'Kjøkken', stock: 25 },
  { name: 'Camping telt 2-person', description: 'Lett og kompakt 2-personstelt. Vanntett med sydd gulv og full innsektsbarriere.', price: 999.0, imageUrl: 'https://picsum.photos/seed/tent/400/300', category: 'Friluftsliv', stock: 20 },
  { name: 'Pannelykte - LED oppladbar', description: 'Kraftig LED-pannelykke med 300 lumen, 3 lysmodi og innebygget USB-lading.', price: 249.0, imageUrl: 'https://picsum.photos/seed/headlamp/400/300', category: 'Friluftsliv', stock: 85 },
  { name: 'Termosdrikke-sekk 2L', description: 'Drikkesekk for sykkel, løping og vandring. 2 liters kapasitet, isolert slange.', price: 299.0, imageUrl: 'https://picsum.photos/seed/hydration/400/300', category: 'Friluftsliv', stock: 55 },
  { name: 'Solkrem SPF 50 - 200ml', description: 'Vannresistent solkrem SPF 50. Parfymefri og testet for sensitiv hud.', price: 149.0, imageUrl: 'https://picsum.photos/seed/sunscreen/400/300', category: 'Helse & Trening', stock: 200 },
  { name: 'Massasjepistol', description: 'Perkusjons-massasjepistol med 6 hastigheter og 4 ulike hoder. 3 timers batteritid.', price: 699.0, imageUrl: 'https://picsum.photos/seed/massage/400/300', category: 'Helse & Trening', stock: 30 },
  { name: 'Yogaklær sett - Dame', description: 'Behagelig og pustende yogasett i resirkulert materiale. Inkluderer leggings og topp.', price: 399.0, imageUrl: 'https://picsum.photos/seed/yoga2/400/300', category: 'Sport', stock: 60 },
  { name: 'Snøresko - Herre vinter', description: 'Isolerte vinterstøvler med Vibram-såle og vanntett membran. God for temperaturer ned til -20°C.', price: 1299.0, imageUrl: 'https://picsum.photos/seed/winterboots/400/300', category: 'Sport', stock: 22 },
  { name: 'Smart LED-pære E27 - 3-pk', description: 'Dimmbar smart-pære, 9W, 800 lumen. Styres via app eller stemme (Alexa/Google).', price: 199.0, imageUrl: 'https://picsum.photos/seed/bulb/400/300', category: 'Elektronikk', stock: 110 },
  { name: 'Nettbrettdeksel - iPad 10.9"', description: 'Trifold smart-deksel med innebygget penn-holder og auto-sleep-funksjon.', price: 299.0, imageUrl: 'https://picsum.photos/seed/ipadcase/400/300', category: 'Elektronikk', stock: 40 },
  { name: 'Multivitamin 90 tabletter', description: 'Komplett daglig multivitamin med 23 vitaminer og mineraler. Glutenfri og vegansk.', price: 199.0, imageUrl: 'https://picsum.photos/seed/vitamins/400/300', category: 'Helse & Trening', stock: 150 },
];

async function seedProducts() {
  const batch = db.batch();
  const col = db.collection('products');
  
  for (const p of products) {
    const ref = col.doc();
    batch.set(ref, {
      ...p,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      bestseller: false,
      rating: 0,
      reviewCount: 0,
    });
  }
  
  await batch.commit();
  console.log(`✅ La til ${products.length} produkter i Firestore!`);
  process.exit(0);
}

seedProducts().catch(err => {
  console.error('❌ Feil:', err.message);
  process.exit(1);
});
