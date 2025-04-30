// functions/index.js
const admin = require('firebase-admin');
admin.initializeApp();

// import the v2 Firestore trigger
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

exports.sendChatNotification = onDocumentCreated(
  'chatRooms/{chatRoomId}/message/{messageId}',
  async (event) => {
    const snap        = event.data;                // DocumentSnapshot
    const { sender, text } = snap.data();   // path param

    const { sender, text } = snap.data();
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
