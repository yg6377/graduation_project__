const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 너의 키 파일 이름에 맞게 수정

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 무작위 상태 중 하나를 반환
function getRandomStatus() {
  const statuses = ['selling', 'reserved', 'soldout'];
  const randomIndex = Math.floor(Math.random() * statuses.length);
  return statuses[randomIndex];
}

async function updateSaleStatuses() {
  const snapshot = await db.collection('products').get();
  console.log(`📦 전체 상품 수: ${snapshot.size}`);

  let updatedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    if (!data.saleStatus) {
      const newStatus = getRandomStatus();
      await doc.ref.update({ saleStatus: newStatus });
      console.log(`✅ ${doc.id} → saleStatus: ${newStatus}`);
      updatedCount++;
    }
  }

  console.log(`🎉 작업 완료! 총 ${updatedCount}개의 문서에 saleStatus 필드를 추가했습니다.`);
}

updateSaleStatuses().catch(console.error);