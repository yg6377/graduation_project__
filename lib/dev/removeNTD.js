const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 🔐 update path if needed

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function removeNTDFromPrices() {
  const productsSnapshot = await db.collection('products').get();

  for (const doc of productsSnapshot.docs) {
    const data = doc.data();
    let price = data.price;

    if (typeof price === 'string' && price.includes('NTD')) {
      price = price.replace(' NTD', '');
      await db.collection('products').doc(doc.id).update({ price });
      console.log(`✅ Updated price for product ${doc.id}: ${price}`);
    }
  }

  console.log('🎉 Finished removing "NTD" from all product prices.');
}

removeNTDFromPrices().catch(console.error);
