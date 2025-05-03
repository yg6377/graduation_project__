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

async function updateRegions() {
  const snapshot = await db.collection('users').get();
  const batch = db.batch();

  snapshot.forEach(doc => {
    const data = doc.data();
    const regionStr = data.region;
    if (typeof regionStr === 'string' && regionMap[regionStr]) {
      const updatedRegion = regionMap[regionStr];
      const ref = db.collection('users').doc(doc.id);
      batch.update(ref, { region: updatedRegion });
      console.log(`✅ Updated ${doc.id} to ${JSON.stringify(updatedRegion)}`);
    } else {
      console.log(`❌ Skipped ${doc.id}, region: ${regionStr}`);
    }
  });

  await batch.commit();
  console.log('✅ Batch update complete.');
}

updateRegions().catch(console.error);
