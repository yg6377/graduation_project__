import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  String formatLastTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final Duration diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes} minutes ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }

  Future<String> fetchNickname(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('nickname')) {
        return doc['nickname'];
      } else {
        return 'Not registered in database';
      }
    } catch (e) {
      return 'Not registered in database';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Chat List")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return Center(child: Text("No chats available."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final List participants = data['participants'] ?? [];

              final otherUid = participants.firstWhere((uid) => uid != currentUid, orElse: () => null);

              return FutureBuilder<String>(
                future: fetchNickname(otherUid),
                builder: (context, nicknameSnapshot) {
                  final nickname = nicknameSnapshot.data ?? 'Loading...';
                  final location = data['location'] ?? 'No location info';
                  final lastMessage = data['lastMessage'] ?? '';
                  final lastTime = data['lastTime'] as Timestamp?;
                  final profileImageUrl = data['profileImageUrl'] ?? '';
                  final timeString = formatLastTime(lastTime);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                      radius: 25,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$nickname ($location)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: TextStyle(fontSize: 13, color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            chatRoomId: doc.id,
                            userName: otherUid, // 여전히 UID 전달 (ChatRoomScreen에서 닉네임 처리됨)
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
          );
        },
      ),
    );
  }
}
