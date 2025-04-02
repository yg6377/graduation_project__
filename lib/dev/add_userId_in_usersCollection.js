const admin = require('firebase-admin');

// serviceAccountKey.json 파일은 이 스크립트와 같은 폴더에 있어야 해
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function addUserIdToUsers() {
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();

  for (const doc of snapshot.docs) {
    const userId = doc.id; // 문서 ID = UID
    const userData = doc.data();

    if (!userData.userId) {
      await doc.ref.update({
        userId: userId,
      });
      console.log(`✅ userId 필드 추가됨: ${userId}`);
    } else {
      console.log(`⚠️ 이미 userId 존재: ${userId}`);
    }
  }

  console.log('작업 완료!');
}

addUserIdToUsers().catch(console.error);