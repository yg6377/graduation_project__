import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp();

export const sendChatNotification = onDocumentCreated(
  'chatRooms/{chatRoomId}/message/{messageId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const senderId = message.sender;
    const text = message.text;
    const chatRoomId = event.params.chatRoomId;

    // receiverId를 message 문서에서 직접 추출
    const receiverId = message.receiver;
    if (!receiverId) {
      console.log('Receiver ID not found.');
      return;
    }

    // FCM 토큰 가져오기
    const receiverDoc = await getFirestore().collection('users').doc(receiverId).get();
    const token = receiverDoc.data()?.fcmToken;



    // FCM 알림 페이로드 구성
    const payload = {
      notification: {
        title: 'New Message',
        body: text,
      },
      data: {
        chatRoomId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

     console.log('▶️ Sending to token:', token);
        console.log('▶️ About to send payload:', JSON.stringify(payload));
        console.log('▶️ Calling sendToDevice for receiverId:', receiverId);

        if (!token || typeof token !== 'string') {
          console.log('⛔ Invalid or missing token for', receiverId);
          return;
        }

    try {
      await getMessaging().send({
          token,
          notification: payload.notification,
          data: payload.data,
        });
      console.log('✅ Message sent to', receiverId);
    } catch (error) {
      console.error('🚨 FCM send error:', error);
    }
  }
);