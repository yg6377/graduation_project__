const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // Replace with your key file

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Manually defined product list with title and price
const products = [
  { title: "iPhone 13 Pro", price: 29900 },
  { title: "Fleece Jacket", price: 990 },
  { title: "MUJI Mug Set", price: 499 },
  // Add more products as needed...
];

async function uploadProducts() {
  const batch = db.batch();
  products.forEach((product) => {
    const docRef = db.collection("products").doc(); // auto-generated ID
    batch.set(docRef, {
      ...product,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log("✅ All products uploaded successfully!");
}

uploadProducts().catch(console.error);