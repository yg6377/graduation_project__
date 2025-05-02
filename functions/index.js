// functions/index.js
const admin = require('firebase-admin');
admin.initializeApp();
const functions = require("firebase-functions");

// import the v2 Firestore trigger
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

exports.sendChatNotification = onDocumentCreated(
  'chatRooms/{chatRoomId}/message/{messageId}',
  async (event) => {
    const snap        = event.data;                // DocumentSnapshot
    const { sender, text } = snap.data();   // path param

    // 1) sender 닉네임 조회
    const userDoc = await admin.firestore().collection('users').doc(sender).get();
    const senderName = userDoc.exists && userDoc.data().nickname
      ? userDoc.data().nickname
      : 'Anonymous';

    // 2) 참가자 토큰 배열
    const roomDoc = await admin.firestore().collection('chatRooms').doc(chatRoomId).get();
    const participants = roomDoc.data().participants || [];
    const tokenDocs = await Promise.all(
      participants.map(uid =>
        admin.firestore().collection('deviceTokens').doc(uid).get()
      )
    );
    const tokens = tokenDocs
      .map(d => d.exists ? d.data().fcmToken : null)
      .filter(t => !!t);

    if (tokens.length === 0) return;

    // 3) 페이로드 구성
    const payload = {

      data: {
        chatRoomId:   chatRoomId,
        senderName:   senderName,
        message:      messageText,
        productTitle:    roomDoc.data().productTitle  || '',
        productImageUrl: roomDoc.data().productImageUrl || '',
        productPrice:    roomDoc.data().productPrice  || '',
      },
    };

    // 4) FCM 발송
    return admin.messaging().sendToDevice(tokens, payload);
  }
);

exports.onProductPriceChange = onDocumentUpdated("products/{productId}", async (event) => {
  const change = event.data;
  const before = change.before.data();
  const after = change.after.data();

  if (before.price !== after.price) {
    const productId = event.params.productId;
    const newPrice = after.price;

    const likedByRef = admin.firestore()
      .collectionGroup('likedProducts')
      .where('productId', '==', productId)

    return likedByRef.get().then(snapshot => {
      const batch = admin.firestore().batch();

      snapshot.forEach(doc => {
        const userId = doc.ref.parent.parent.id;
        const notificationRef = admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .doc();

        batch.set(notificationRef, {
          productId,
          message: `Price updated to ${newPrice}`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          seen: false,
        });
      });

      return batch.commit();
    });
  }

  return null;
});
