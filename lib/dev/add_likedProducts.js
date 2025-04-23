const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 🔑 위치 확인

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateLikesToLikedProducts() {
  const productsSnapshot = await db.collection('products').get();

  for (const productDoc of productsSnapshot.docs) {
    const productId = productDoc.id;
    const likesSnapshot = await db.collection('products').doc(productId).collection('likes').get();

    for (const likeDoc of likesSnapshot.docs) {
      const userUid = likeDoc.id;
      const likedAt = likeDoc.data().likedAt || admin.firestore.FieldValue.serverTimestamp();

      const userRef = db.collection('users').doc(userUid).collection('likedProducts').doc(productId);
      await userRef.set({
        productId,
        likedAt,
      });

      console.log(`✅ added ${productId} to ${userUid}/likedProducts`);
    }
  }

  console.log('🎉 add likedProducts Collections complete!');
}

migrateLikesToLikedProducts().catch(console.error);