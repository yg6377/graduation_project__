import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chatroom_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_ko;

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  String formatLastTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return "Just now";
    }

    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat List")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No chats available."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index];
              String chatId = chatData.id;
              Timestamp? lastTime = chatData['lastTime'];
              String lastMessage = chatData['lastMessage'] ?? ""; // Firestore Timestamp

              List<dynamic> participants = chatData['participants'] ?? [];
              String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
              String userName = participants.firstWhere(
                    (email) => email != currentUserEmail,
                orElse: () => "Unknown",
              );

              String userLocation = chatData['location'] ?? "No location info";
              String profileImageUrl = chatData['profileImageUrl'] ?? "";
              String lastTimeString = formatLastTime(lastTime);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                  radius: 25,
                ),
                // title 영역에서 Row를 사용해 왼쪽엔 이름, 오른쪽엔 시간 표시
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$userName ($userLocation)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lastTimeString, // 예: "Just now", "3 minutes ago" 등
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                // subtitle에 마지막 메시지
                subtitle: lastMessage.isNotEmpty
                    ? Text(
                  lastMessage,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  maxLines: 1,        // 한 줄로만 표시 (원하면 조절)
                  overflow: TextOverflow.ellipsis, // 길면 ... 처리
                )
                    : null,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: chatId,
                        userName: userName,
                        productTitle: '',
                        productImageUrl: '',
                        productPrice: '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
