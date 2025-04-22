const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const regions = ['Taipei', 'New Taipei', 'Danshui', 'Keelung', 'Taoyuan', 'Hsinchu', 'Taichung', 'Kaohsiung', 'Tainan', 'Hualien'];

async function updateUsers() {
  const usersSnapshot = await db.collection('users').get();

  for (const userDoc of usersSnapshot.docs) {
    const data = userDoc.data();
    if (!data.region) {
      const randomRegion = regions[Math.floor(Math.random() * regions.length)];
      await userDoc.ref.update({ region: randomRegion });
      console.log(`✅ Added region "${randomRegion}" to user ${userDoc.id}`);
    }
  }
}

async function updateProducts() {
  const productsSnapshot = await db.collection('products').get();

  for (const productDoc of productsSnapshot.docs) {
    const product = productDoc.data();

    if (!product.region && product.sellerUid) {
      const sellerRef = db.collection('users').doc(product.sellerUid);
      const sellerDoc = await sellerRef.get();

      if (sellerDoc.exists) {
        const sellerRegion = sellerDoc.data().region;
        if (sellerRegion) {
          await productDoc.ref.update({ region: sellerRegion });
          console.log(`📦 Updated product ${productDoc.id} with region "${sellerRegion}"`);
        }
      }
    }
  }
}

/*
async function fixInvalidRegions() { //얘도 다쓰고 지워도됨.
  const snapshot = await db.collection('users').get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const invalidRegion = data.region;

    if (invalidRegion === '서울' || invalidRegion === '부산' || invalidRegion === '대구') {
      const newRegion = regions[Math.floor(Math.random() * regions.length)];
      await doc.ref.update({ region: newRegion });
      console.log(`🔁 Changed region from "${invalidRegion}" to "${newRegion}" for user ${doc.id}`);
    }
  }
}
*/

async function main() {
  console.log('🔥 Starting region update...');
  //await fixInvalidRegions(); //얘는 다쓰고 지워도 됨.
  await updateUsers();
  await updateProducts();
  console.log('✅ All region updates completed!');
}

main();