import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chatroom_screen.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("채팅 목록")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("채팅이 없습니다."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index];
              String chatId = chatData.id;
              Timestamp? lastTime = chatData['lastTime']; // Firestore Timestamp

              String userName = chatData['userName'] ?? "알 수 없음";
              String userLocation = chatData['location'] ?? "지역 정보 없음";
              String profileImageUrl = chatData['profileImageUrl'] ?? "";

              String lastMessage = chatData['lastMessage'] ?? "";
              String lastTimeString = "";
              if (lastTime != null) {
                // timeago를 쓰려면 pubspec.yaml에 timeago 의존성을 추가해 주세요 (timeago: ^3.0.2 등)
                lastTimeString = timeago.format(lastTime.toDate(), locale: 'ko');
              }


              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                  radius: 25,
                ),
                title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userLocation, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 2),

                  ],
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: chatId,
                        userName: userName,
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
  }}
