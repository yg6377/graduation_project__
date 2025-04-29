const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 🔑 네 서비스 키

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addRandomConditionToProducts() {
  const productsSnapshot = await db.collection('products').get();

  // 상태 등급 리스트
  const conditions = ['S', 'A', 'B', 'C', 'D'];

  for (const productDoc of productsSnapshot.docs) {
    const data = productDoc.data();

    if (!data.hasOwnProperty('condition')) {
      // 랜덤하게 하나 선택
      const randomCondition = conditions[Math.floor(Math.random() * conditions.length)];

      await db.collection('products').doc(productDoc.id).update({
        condition: randomCondition,
        saleStatus: 'selling',
      });

      console.log(`✅ Updated product ${productDoc.id} with condition '${randomCondition}'`);
    } else {
      console.log(`ℹ️ Product ${productDoc.id} already has condition: ${data.condition}`);
    }
  }

  console.log('🎉 All products updated with random conditions!');
}

addRandomConditionToProducts().catch(console.error);