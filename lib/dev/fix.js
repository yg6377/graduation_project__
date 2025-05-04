// fix.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const regionMap = {
  'Danshui':        { city: 'New Taipei City', district: 'Tamsui District' },
  'Taipei':         { city: 'Taipei City', district: 'Zhongzheng District' },
  'New Taipei':     { city: 'New Taipei City', district: 'Banqiao District' },
  'Kaohsiung':      { city: 'Kaohsiung City', district: 'Sanmin District' },
  'Taichung':       { city: 'Taichung City', district: 'Xitun District' },
  'Tainan':         { city: 'Tainan City', district: 'East District' },
  'Hualien':        { city: 'Hualien City', district: 'Hualien District' },
  'Keelung':        { city: 'Keelung City', district: 'Ren’ai District' },
  'Taoyuan':        { city: 'Taoyuan City', district: 'Zhongli District' },
  'Hsinchu':        { city: 'Hsinchu City', district: 'East District' },
};


async function migrateProductRegions() {
  const productsSnap = await db.collection('products').get();
  const batch = db.batch();

  for (const doc of productsSnap.docs) {
    const data = doc.data();
    const sellerUid = data.sellerUid;
    if (!sellerUid) {
      console.log(`⚠️ Product ${doc.id} has no sellerUid, skipped.`);
      continue;
    }

    const userDoc = await db.collection('users').doc(sellerUid).get();
    if (!userDoc.exists) {
      console.log(`⚠️ No user doc for sellerUid=${sellerUid}, skipped ${doc.id}.`);
      continue;
    }

    const userRegion = userDoc.data().region;
    if (userRegion && typeof userRegion === 'object') {
      batch.update(doc.ref, { region: userRegion });
      console.log(`🗺️ ${doc.id}: region set to ${JSON.stringify(userRegion)}`);
    } else {
      console.log(`⚠️ User ${sellerUid} has invalid region, skipped ${doc.id}.`);
    }
  }

  await batch.commit();
  console.log('✅ All product regions have been migrated!');
}

migrateProductRegions()
  .catch(err => console.error('🔥 Migration error:', err));