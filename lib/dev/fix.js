// fix.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateProductNames() {
  const productsRef = db.collection("products");
  const snapshot = await productsRef.get();

  const batch = db.batch();
  let count = 0;

  snapshot.forEach((doc) => {
    const data = doc.data();

    // 이미 productName이 있으면 건너뜀
    if (!data.productName && data.title) {
      const docRef = productsRef.doc(doc.id);
      batch.update(docRef, { productName: data.title });
      count++;
    }
  });

  if (count === 0) {
    console.log("✔ 모든 문서에 이미 productName이 존재합니다.");
    return;
  }

  // 배치 커밋
  await batch.commit();
  console.log(`✅ ${count}개의 문서에 productName 필드를 추가했습니다.`);
}

updateProductNames().catch((error) => {
  console.error("🔥 오류 발생:", error);
});