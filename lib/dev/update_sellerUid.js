const admin = require('firebase-admin');
const fs = require('fs');

// Firebase Admin 초기화
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateSellerUids() {
  const productsSnapshot = await db.collection('products').get();

  for (const doc of productsSnapshot.docs) {
    const product = doc.data();
    const sellerEmail = product.sellerEmail;

    if (!sellerEmail) {
      console.log(`🗑️ 문서 ${doc.id} 삭제됨 (sellerEmail 없음)`);
      await doc.ref.delete();
      continue;
    }

    const usersSnapshot = await db.collection('users')
      .where('email', '==', sellerEmail)
      .get();

    if (!usersSnapshot.empty) {
      const sellerUid = usersSnapshot.docs[0].id;

      await doc.ref.update({ sellerUid });
      console.log(`✅ ${doc.id} 문서에 sellerUid 추가 완료: ${sellerUid}`);
    } else {
      console.log(`⚠️ ${doc.id} 문서의 sellerEmail(${sellerEmail})과 일치하는 유저 없음`);
    }
  }
}

updateSellerUids()
  .then(() => console.log('모든 업데이트 완료'))
  .catch((err) => console.error('오류 발생:', err));