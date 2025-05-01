import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  String formatLastTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final diff = DateTime.now().difference(timestamp.toDate());
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
      }
    } catch (_) {}
    return 'Unknown';
  }

  Future<void> _confirmAndDelete(BuildContext context, String chatRoomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('채팅방 삭제'),
        content: Text('정말 삭제하시겠습니까?'),
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('채팅 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final unique = <String, QueryDocumentSnapshot>{};
          for (var doc in docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final parts = List<String>.from(data['participants'] ?? []);
            final other = parts.firstWhere((u) => u != currentUid, orElse: () => '');
            if (other.isNotEmpty && !unique.containsKey(other)) {
              unique[other] = doc;
            }
          }
          final chats = unique.values.toList();
          if (chats.isEmpty) return Center(child: Text("No chats available."));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, idx) {
              final doc = chats[idx];
              final data = doc.data()! as Map<String, dynamic>;
              final parts = List<String>.from(data['participants'] ?? []);
              final otherUid = parts.firstWhere((u) => u != currentUid, orElse: () => '');

              return FutureBuilder<String>(
                future: fetchNickname(otherUid),
                builder: (context, snapNick) {
                  final nickname = snapNick.data ?? 'Loading...';
                  final region = data['region'] ?? 'Unknown';
                  final lastMessage = data['lastMessage'] ?? '';
                  final timeString = formatLastTime(data['lastTime'] as Timestamp?);
                  final profileImageUrl = data['profileImageUrl'] ?? '';

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
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$nickname ($region)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(timeString,
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  chatRoomId: doc.id,
                                  userName: nickname,
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, thickness: 2),
                      ],
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
