const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // adjust path if needed

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const regions = ['Taipei', 'New Taipei', 'Danshui', 'Keelung', 'Taoyuan', 'Hsinchu', 'Taichung', 'Kaohsiung', 'Tainan', 'Hualien'];

const productTemplates = [
  { title: "iphone 13", minPrice: 10000, maxPrice: 12000, imageUrl: "https://m.media-amazon.com/images/I/61CpZkUmKQL._AC_UF894,1000_QL80_.jpg" },
  { title: "iphone 13 pro", minPrice: 13000, maxPrice: 15000, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMmfJaCYiKhz1e1eImPIAnUOxPESC4eRJAKw&s" },
  { title: "iPhone 14", minPrice: 15000, maxPrice: 20000, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1xGj5kC72f84oPlGro2YabqHFYqxCnNNKSw&s" },
  { title: "iphone 14 pro", minPrice: 20000, maxPrice: 25000, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7lcuTxTsJsPtAuPZLm_nSo2wQe-AcswWpsA&s" },
  { title: "iphone 15", minPrice: 20000, maxPrice: 250000, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSEeGm32C8hfCRf47-7RVjnvDlUoHjMGybWwA&s" },
  { title: "iphone 15 pro", minPrice: 30000, maxPrice: 35000, imageUrl: "https://i.insider.com/61716f84fee39f0018fa9d8d?width=700" },
  { title: "MacBook M3pro", minPrice: 40000, maxPrice: 50000, imageUrl: "https://cdn.thewirecutter.com/wp-content/media/2025/03/BEST-MACBOOKS-2048px-15inch-hero.jpg?auto=webp&quality=75&width=1024" },
  { title: "MacBook M4", minPrice: 50000, maxPrice: 60000, imageUrl: "https://shashinki.com/shop/getimage/products/app-mcbookpro-13-m2(2).jpg" },
  { title: "Sony WH-1000XM4", minPrice: 18000, maxPrice: 24000, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTEj-5ZlRUy01tEIhGDVc-Iy828BEJ5o5Jlcw&s" },
  { title: "IKEA Desk Lamp", minPrice: 500, maxPrice: 2000, imageUrl: "https://i.ebayimg.com/images/g/hr4AAOSwdppmWjFC/s-l1200.jpg" },
  { title: "Canon EOS M50", minPrice: 35000, maxPrice: 50000, imageUrl: "https://www.dpreview.com/files/p/articles/2486441171/body/EOS-M50-hand.jpeg" },
  { title: "Air Jordan 1", minPrice: 10000, maxPrice: 25000, imageUrl: "https://tshop.r10s.com/594/e53/ebbc/c77a/a049/20fd/f6e7/11e2ea93870242ac110004.jpg" },
  { title: "Apple Watch SE", minPrice: 18000, maxPrice: 25000, imageUrl: "https://i.pcmag.com/imagery/reviews/052mIuvYgv4rXkeLMZAu5xh-20..v1666983253.jpg" },
  { title: "LEGO Star Wars Set", minPrice: 6000, maxPrice: 15000, imageUrl: "https://lumiere-a.akamaihd.net/v1/images/5eea15e3ac52b7000116bf5a-image_723375c6.jpeg?region=0,0,1536,864&width=768" },
  { title: "UNIQLO Backpack", minPrice: 1000, maxPrice: 3500, imageUrl: "https://im.uniqlo.com/global-cms/spa/resad5bbad073ddbd63f1568e168692c97bfr.jpg" }
];

const conditions = ["S","A","B","C","D"];

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomDateInApril() {
  const start = new Date("2025-04-01T00:00:00Z").getTime();
  const end = new Date("2025-04-30T23:59:59Z").getTime();
  return new Date(randomInt(start, end));
}

async function uploadTestData() {
  // Fetch all user UIDs
  const usersSnap = await db.collection("users").get();
  const userIds = usersSnap.docs.map(doc => doc.id);
  if (userIds.length === 0) {
    console.error("No users found in users collection.");
    return;
  }

  const batch = db.batch();
  for (let i = 0; i < 100; i++) {
    const template = productTemplates[randomInt(0, productTemplates.length - 1)];
    const price = randomInt(template.minPrice, template.maxPrice);
    const sellerUid = userIds[randomInt(0, userIds.length - 1)];
    const condition = conditions[randomInt(0, conditions.length - 1)];
    const region = regions[randomInt(0, regions.length - 1)];
    const createdAt = randomDateInApril();

    const docRef = db.collection("products").doc();

    // Assign a random number of likes between 0 and 20
    const likeCount = randomInt(0, 20);

    // Add the likes count to the product document
    batch.set(docRef, {
      title: template.title,
      price,
      imageUrl: template.imageUrl,
      description: `${template.title} in test data`,
      sellerUid,
      condition,
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      region,
      likes: likeCount
    });

    // Randomly pick users to like this product
    const shuffledUsers = userIds.sort(() => 0.5 - Math.random());
    const likers = shuffledUsers.slice(0, likeCount);

    likers.forEach((uid) => {
      const likeRef = docRef.collection('likes').doc(uid);
      batch.set(likeRef, {
        likedAt: admin.firestore.Timestamp.fromDate(randomDateInApril())
      });
    });
  }

  await batch.commit();
  console.log("✅ 100 test products uploaded to Firestore!");
}

uploadTestData().catch(console.error);