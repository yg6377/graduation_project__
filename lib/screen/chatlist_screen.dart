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

  Future<void> _confirmAndDelete(BuildContext context, String chatRoomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('채팅방 삭제'),
        content: Text('정말로 이 채팅방을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final Map<String, QueryDocumentSnapshot> uniqueChats = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUid = participants.firstWhere((uid) => uid != currentUid, orElse: () => '');
            if (otherUid.isNotEmpty && !uniqueChats.containsKey(otherUid)) {
              uniqueChats[otherUid] = doc;
            }
          }

          final filteredDocs = uniqueChats.values.toList();

          if (filteredDocs.isEmpty) return Center(child: Text("No chats available."));

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              final otherUid = participants.firstWhere((uid) => uid != currentUid, orElse: () => '');

              return FutureBuilder<String>(
                future: fetchNickname(otherUid),
                builder: (context, snapshot) {
                  final nickname = snapshot.data ?? 'Loading...';
                  final location = data['location'] ?? 'No location info';
                  final lastMessage = data['lastMessage'] ?? '';
                  final lastTime = data['lastTime'] as Timestamp?;
                  final profileImageUrl = data['profileImageUrl'] ?? '';
                  final timeString = formatLastTime(lastTime);

                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _confirmAndDelete(context, doc.id);
                      return false;
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
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
                        final roomData = doc.data()! as Map<String, dynamic>;
                        final prodId = roomData['productId'] as String? ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              chatRoomId: doc.id,
                              userName:   nickname,

                            ),
                          ),
                        );
                      },
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
