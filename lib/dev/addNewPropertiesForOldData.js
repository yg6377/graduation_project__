const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 너의 서비스키 경로

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeUserSubcollections() {
  const usersSnapshot = await db.collection('users').get();

  for (const userDoc of usersSnapshot.docs) {
    const uid = userDoc.id;

    const dummyProductId = `dummy-${Date.now()}`;

    console.log(`➕ 사용자 ${uid} 에게 likedProducts / clickedProducts 추가 중...`);

    // clickedProducts 더미
    await db.collection('users').doc(uid).collection('clickedProducts').doc(dummyProductId).set({
      productId: dummyProductId,
      clickedAt: admin.firestore.Timestamp.now(),
    });

    // likedProducts 더미
    await db.collection('users').doc(uid).collection('likedProducts').doc(dummyProductId).set({
      productId: dummyProductId,
      likedAt: admin.firestore.Timestamp.now(),
    });
  }

  console.log('✅ 모든 유저에게 likedProducts / clickedProducts 컬렉션 생성 완료');
}

initializeUserSubcollections().catch(console.error);