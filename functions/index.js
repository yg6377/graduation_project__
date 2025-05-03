const admin = require('firebase-admin');
admin.initializeApp();

// v1 functions
const functions = require("firebase-functions");

// v2 functions - 별도 import
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

// v2 함수에 대한 리전 설정
const region = 'asia-northeast3'; // 서울 리전 (또는 원하는 리전으로 변경)

exports.sendChatNotification = onDocumentCreated({
  document: 'chatRooms/{chatRoomId}/message/{messageId}',
  region: region
}, async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const { sender, text } = snap.data();
    const chatRoomId = event.params.chatRoomId;
    const messageText = text || '';

    // 1) sender 닉네임 조회
    const userDoc = await admin.firestore().collection('users').doc(sender).get();
    const senderName = userDoc.exists && userDoc.data().nickname
      ? userDoc.data().nickname
      : 'Anonymous';

    // 2) 참가자 토큰 배열
    const roomDoc = await admin.firestore().collection('chatRooms').doc(chatRoomId).get();
    if (!roomDoc.exists) return null;

    const participants = roomDoc.data().participants || [];
    const tokenDocs = await Promise.all(
      participants.map(uid =>
        admin.firestore().collection('deviceTokens').doc(uid).get()
      )
    );
    const tokens = tokenDocs
      .map(d => d.exists ? d.data().fcmToken : null)
      .filter(t => !!t);

    if (tokens.length === 0) return null;

    // 3) 페이로드 구성
    const payload = {
      data: {
        chatRoomId: chatRoomId,
        senderName: senderName,
        message: messageText,
        productTitle: roomDoc.data().productTitle || '',
        productImageUrl: roomDoc.data().productImageUrl || '',
        productPrice: roomDoc.data().productPrice || '',
      },
    };

    // 4) FCM 발송
    return admin.messaging().sendToDevice(tokens, payload);
});

exports.onProductPriceChange = onDocumentUpdated({
  document: "products/{productId}",
  region: region
}, async (event) => {
    const change = event.data;
    if (!change) return null;

    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after || before.price === after.price) {
      return null;
    }

    const productId = event.params.productId;
    const newPrice = after.price;

    try {
      const likedByRef = admin.firestore()
        .collectionGroup('likedProducts')
        .where('productId', '==', productId);

      const snapshot = await likedByRef.get();

      if (snapshot.empty) {
        console.log(`No users have liked product ${productId}`);
        return null;
      }

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
    } catch (error) {
      console.error('Error processing price change:', error);
      return null;
    }
});