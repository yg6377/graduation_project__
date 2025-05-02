const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function syncProductRegionWithUserRegion() {
  const productsSnapshot = await db.collection('products').get();

  for (const productDoc of productsSnapshot.docs) {
    const productData = productDoc.data();
    const sellerUid = productData.sellerUid;

    if (!sellerUid) continue;

    try {
      const userDoc = await db.collection('users').doc(sellerUid).get();
      if (!userDoc.exists) {
        console.log(`❌ 사용자 없음: ${sellerUid}`);
        continue;
      }

      const userData = userDoc.data();
      const userRegion = (userData.region || '').toString().trim();

      if (!userRegion) {
        console.log(`⚠️ 사용자 ${sellerUid}의 지역이 비어있음`);
        continue;
      }

      await productDoc.ref.update({ region: userRegion });
      console.log(`✅ ${productDoc.id} 상품의 region을 '${userRegion}'로 업데이트`);
    } catch (err) {
      console.error(`🔥 오류 발생 (productId: ${productDoc.id}):`, err);
    }
  }

  console.log('🎉 모든 상품의 지역 동기화 완료');
}

syncProductRegionWithUserRegion().catch(console.error);