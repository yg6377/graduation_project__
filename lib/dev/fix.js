const admin = require('firebase-admin');

// Firebase 서비스 계정 키 경로
const serviceAccount = require('./serviceAccountKey.json'); // ← 이 경로 수정

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function removePlaceholderImages() {
  const snapshot = await db.collection('products').get();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const imageUrl = data.imageUrl;

    if (typeof imageUrl === 'string' && imageUrl.includes('via.placeholder.com')) {
      await db.collection('products').doc(doc.id).update({
        imageUrl: admin.firestore.FieldValue.delete(),
      });
      console.log(`🧹 Removed imageUrl from product: ${doc.id}`);
      count++;
    }
  }

  console.log(`✅ Done. Total cleaned: ${count}`);
}

removePlaceholderImages().catch(console.error);