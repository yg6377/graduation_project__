const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 경로 확인

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteUsersAndTheirProducts() {
  const keepUid = 'AMITUUjBIygX6zFgfRGcGhOzNAD2';
  const uidsToDelete = [
    'EEwMyQOuWvXH6MzvFmkpMyNh51n2',
    'JnUtK2dd3MTm9WQknadHw1z5ubf2',
    'Zh3EpDttv8TC4daRBxYcL1L9KPl2',
    'alPsD7gFQCbYkISSRV0fZCJmb8h1',
    'iMDoRLyaBka21ZH5aiODi8vxaZw2',
    'o6n39cEoHEh0FcYRAahLCs2r7bf2',
    'qQ8Wjy0TPybIEORzuGqs4KM1ds22',
  ];

  for (const uid of uidsToDelete) {
    try {
      // 1. products 삭제
      const productsSnapshot = await db.collection('products').where('sellerUid', '==', uid).get();
      for (const productDoc of productsSnapshot.docs) {
        await productDoc.ref.delete();
        console.log(`🛒 상품 삭제: ${productDoc.id}`);
      }

      // 2. user 문서 삭제
      await db.collection('users').doc(uid).delete();
      console.log(`🗑️ 사용자 삭제: ${uid}`);
    } catch (err) {
      console.error(`❌ 삭제 중 오류 (${uid}):`, err);
    }
  }

  console.log('✅ 모든 지정된 사용자 및 상품 삭제 완료');
}

deleteUsersAndTheirProducts().catch(console.error);