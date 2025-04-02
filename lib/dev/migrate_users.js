const admin = require('firebase-admin');
const fs = require('fs');
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json'))
});

const db = admin.firestore();

async function migrateUsersToFirestore() {
  const listAllUsers = async (nextPageToken) => {
    const result = await admin.auth().listUsers(1000, nextPageToken);

    for (const user of result.users) {
      const uid = user.uid;
      const email = user.email || 'noemail@example.com';
      const nickname = 'User' + Math.floor(Math.random() * 100000);

      // Firestore에 존재하지 않으면 추가
      const doc = await db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await db.collection('users').doc(uid).set({
          email,
          nickname,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ ${email} → 등록됨`);
      } else {
        console.log(`⚠️ ${email} → 이미 존재`);
      }
    }

    if (result.pageToken) {
      await listAllUsers(result.pageToken);
    }
  };

  await listAllUsers();
  console.log('마이그레이션 완료!');
}

migrateUsersToFirestore().catch(console.error);