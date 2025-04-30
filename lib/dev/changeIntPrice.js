const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function convertPricesToInt() {
  const productsRef = db.collection("products");
  const snapshot = await productsRef.get();

  const batch = db.batch();
  let count = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    const price = data.price;

    // 문자열인지 확인
    if (typeof price === "string") {
      const intPrice = parseInt(price.replace(/[^0-9]/g, '')); // 숫자만 추출

      if (!isNaN(intPrice)) {
        const docRef = productsRef.doc(doc.id);
        batch.update(docRef, { price: intPrice });
        count++;
      }
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`✅ ${count}개의 price 값을 Integer로 변환했습니다.`);
  } else {
    console.log("변경할 문서가 없습니다.");
  }
}

convertPricesToInt().catch(console.error);