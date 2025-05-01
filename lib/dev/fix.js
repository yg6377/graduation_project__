const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

function convertCityName(koreanCity) {
  const cityMap = {
    '서울': 'Taipei',
    '인천': 'Keelung',
    '부산': 'Danshui',
    '대구': 'Taichung',
    '광주': 'Tainan',
    '대전': 'Tainan',
    '울산': 'Tainan',
    '세종': 'Tainan'
  };

  return cityMap[koreanCity] || koreanCity;
}

async function updateRegionFields() {
  const productsSnapshot = await db.collection('products').get();

  for (const doc of productsSnapshot.docs) {
    const data = doc.data();
    const region = data.region;

    if (typeof region === 'string') {
      const convertedRegion = convertCityName(region);
      if (convertedRegion !== region) {
        await doc.ref.update({ region: convertedRegion });
        console.log(`✅ ${doc.id}의 region 필드를 '${convertedRegion}'으로 업데이트`);
      }
    }
  }

  console.log('🎉 모든 region 필드 업데이트 완료');
}

updateRegionFields().catch(console.error);