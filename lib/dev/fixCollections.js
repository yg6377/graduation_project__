const admin = require('firebase-admin');

// Firebase 서비스 계정 키 로드
const serviceAccount = require('./serviceAccountKey.json'); // ← 너의 서비스키 파일 이름에 맞게 수정

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function clearUserInteractions() {
  const usersSnapshot = await db.collection('users').get();
  console.log(`🔍 전체 유저 수: ${usersSnapshot.size}`);

  for (const userDoc of usersSnapshot.docs) {
    const uid = userDoc.id;

    console.log(`🧹 ${uid} 유저의 clickedProducts 및 likedProducts 삭제 중...`);

    // 클릭 삭제
    const clickedRef = db.collection('users').doc(uid).collection('clickedProducts');
    const clickedDocs = await clickedRef.get();
    for (const doc of clickedDocs.docs) {
      await doc.ref.delete();
    }

    // 좋아요 삭제
    const likedRef = db.collection('users').doc(uid).collection('likedProducts');
    const likedDocs = await likedRef.get();
    for (const doc of likedDocs.docs) {
      await doc.ref.delete();
    }

    console.log(`✅ ${uid} 정리 완료 (clicked: ${clickedDocs.size}, liked: ${likedDocs.size})`);
  }

  console.log('🎉 모든 유저의 인터랙션 정보 삭제 완료');
}

clearUserInteractions().catch(console.error);