const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addUpdatedAtToProducts() {
  const productsRef = db.collection('products');
  const snapshot = await productsRef.get();

  const batch = db.batch();
  let count = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    const hasUpdatedAt = data.hasOwnProperty('updatedAt');
    const hasTimestamp = data.hasOwnProperty('timestamp');

    if (!hasUpdatedAt && hasTimestamp) {
      batch.update(doc.ref, { updatedAt: data.timestamp });
      count++;
    }
  });

  await batch.commit();
  console.log(`✅ ${count}개의 상품 문서에 updatedAt 필드를 추가했습니다.`);
}

addUpdatedAtToProducts();