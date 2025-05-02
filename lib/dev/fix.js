const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addMissingFieldsToProducts() {
  const snapshot = await db.collection('products').get();

  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const updates = {};
    if (data.likes === undefined) updates.likes = 0;
    if (data.chats === undefined) updates.chats = 0;

    if (Object.keys(updates).length > 0) {
      batch.update(doc.ref, updates);
    }
  });

  await batch.commit();
  console.log("✅ likes, chats 필드 일괄 추가 완료");
}

addMissingFieldsToProducts();