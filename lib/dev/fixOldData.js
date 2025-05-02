const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Replace with your path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

//users/userId 누락된 유저들 수정
async function addMissingUserIds() {
  const usersSnapshot = await db.collection('users').get();

  const batch = db.batch();

  usersSnapshot.forEach((doc) => {
    const data = doc.data();
    const uid = doc.id;
    if (!uid) {
      console.error(`❌ Failed to get UID for document: ${doc.ref.path}`);
      return;
    }

    if (!data.userId) {
      const userRef = db.collection('users').doc(uid);
      batch.update(userRef, { userId: uid });
      console.log(`🔧 Added userId to user: ${uid}`);
    }
  });

  await batch.commit();
  console.log('✅ All missing userId fields have been added.');
}

addMissingUserIds().catch(console.error);

//products/productId 누락된 상품들 수정
async function addMissingProductIds() {
  const productsSnapshot = await db.collection('products').get();
  const batch = db.batch();

  productsSnapshot.forEach((doc) => {
    const data = doc.data();
    const productId = doc.id;

    if (!productId) {
      console.error(`❌ Failed to get productId for document: ${doc.ref.path}`);
      return;
    }

    if (!data.productId) {
      const productRef = db.collection('products').doc(productId);
      batch.update(productRef, { productId });
      console.log(`🛠️  Added productId to product: ${productId}`);
    }
  });

  await batch.commit();
  console.log('✅ All missing productId fields have been added.');
}

addMissingProductIds().catch(console.error);

// 🔁 chatRooms/productId 누락된 채팅방 수정
async function addMissingProductIdsToChatRooms() {
  const chatroomsSnapshot = await db.collection('chatRooms').get();
  const batch = db.batch();

  chatroomsSnapshot.forEach((doc) => {
    const data = doc.data();
    const chatroomId = doc.id;

    if (!chatroomId) {
      console.error(`❌ Failed to get chatRoomId for document: ${doc.ref.path}`);
      return;
    }

    if (!data.productId) {
      const chatroomRef = db.collection('chatRooms').doc(chatroomId);
      batch.update(chatroomRef, { productId: '' }); // or set to 'unknown'
      console.log(`💬 Added productId to chatRoom: ${chatroomId}`);
    }
  });

  await batch.commit();
  console.log('✅ All missing productId fields in chatRooms have been added.');
}

addMissingProductIdsToChatRooms().catch(console.error);

// 🛒 products/sellerUid 누락된 상품들 수정
async function addMissingSellerUidsToProducts() {
  const productsSnapshot = await db.collection('products').get();
  const batch = db.batch();

  productsSnapshot.forEach((doc) => {
    const data = doc.data();
    const productId = doc.id;

    if (!productId) {
      console.error(`❌ Failed to get productId for document: ${doc.ref.path}`);
      return;
    }

    if (!data.sellerUid) {
      // Assume seller info might be embedded or use userId if applicable
      const sellerUidGuess = data.userId || data.sellerUid || ''; // fallback
      if (sellerUidGuess) {
        const productRef = db.collection('products').doc(productId);
        batch.update(productRef, { sellerUid: sellerUidGuess });
        console.log(`🛍️  Added sellerUid to product: ${productId}`);
      } else {
        console.warn(`⚠️ Could not determine sellerUid for product: ${productId}`);
      }
    }
  });

  await batch.commit();
  console.log('✅ All missing sellerUid fields in products have been added (if guessable).');
}

addMissingSellerUidsToProducts().catch(console.error);
