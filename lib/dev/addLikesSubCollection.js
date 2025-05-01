const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // adjust path if needed

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function ensureLikes() {
  // Fetch all user UIDs
  const usersSnap = await db.collection("users").get();
  const userIds = usersSnap.docs.map((d) => d.id);
  if (userIds.length === 0) {
    console.error("No users found; aborting.");
    return;
  }

  // Fetch all products
  const productsSnap = await db.collection("products").get();
  console.log(`Found ${productsSnap.size} products.`);

  const batch = db.batch();

  for (const prodDoc of productsSnap.docs) {
    const prodRef = prodDoc.ref;

    // Choose a random like count: 0 to 20
    const likeCount = randomInt(0, 20);

    // Update or set the product's likes field if desired
    batch.update(prodRef, { likes: likeCount });

    // Shuffle user IDs and pick the first likeCount as likers
    const shuffled = userIds.sort(() => 0.5 - Math.random());
    const likers = shuffled.slice(0, likeCount);

    // Remove existing likes documents (optional)
    // const existingLikes = await prodRef.collection("likes").listDocuments();
    // existingLikes.forEach(doc => batch.delete(doc));

    // Create new likes subcollection documents
    likers.forEach((uid) => {
      const likeDocRef = prodRef.collection("likes").doc(uid);
      batch.set(likeDocRef, {
        likedAt: admin.firestore.Timestamp.now(),
      });
    });
  }

  // Commit batch in chunks of 500 operations
  await batch.commit();
  console.log("✅ Likes subcollections ensured for all products.");
}

ensureLikes().catch(console.error);