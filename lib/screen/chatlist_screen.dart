import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  String formatLastTime(Timestamp? ts) {
    if (ts == null) return "";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return "방금 전";
    if (diff.inHours   < 1) return "${diff.inMinutes}분 전";
    if (diff.inHours   < 24) return "${diff.inHours}시간 전";
    return "${diff.inDays}일 전";
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final nicknameFutures = <Future<void>>[];
          final nicknameMap = <String, String>{};

          for (var doc in docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final parts = List<String>.from(data['participants'] ?? []);
            final other = parts.firstWhere((u) => u != me, orElse: () => "");
            if (other.isNotEmpty && !nicknameMap.containsKey(other)) {
              nicknameFutures.add(FirebaseFirestore.instance
                  .collection('users')
                  .doc(other)
                  .get()
                  .then((userDoc) {
                nicknameMap[other] = userDoc.exists && userDoc.data()!.containsKey('nickname')
                    ? userDoc['nickname']
                    : '알 수 없음';
              }));
            }
          }

          final chats = docs;
          if (chats.isEmpty) return Center(child: Text('채팅이 없습니다.'));

          return FutureBuilder(
            future: Future.wait(nicknameFutures),
            builder: (context, nickSnap) {
              if (nickSnap.connectionState != ConnectionState.done) {
                return Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (ctx, i) {
                  final doc = chats[i];
                  final data = doc.data()! as Map<String, dynamic>;
                  final parts = List<String>.from(data['participants'] ?? []);
                  final otherUid = parts.firstWhere((u) => u != me, orElse: () => "");
                  final lastMsg = data['lastMessage'] as String? ?? "";
                  final lastTime = formatLastTime(data['lastTime'] as Timestamp?);

                  final raw = data['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
                  final counts = Map<String, dynamic>.from(raw);
                  final unread = counts[me] as int? ?? 0;

                  final profileUrl = data['profileImageUrl'] as String? ?? "";
                  final nick = nicknameMap[otherUid] ?? "알 수 없음";

                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => FirebaseFirestore.instance
                        .collection('chatRooms')
                        .doc(doc.id)
                        .delete(),
                    background: Container(color: Colors.red),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: profileUrl.isNotEmpty
                            ? NetworkImage(profileUrl)
                            : AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nick,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            lastTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.only(left: 8, top: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unread',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        print('이 채팅방의 uid는 ${doc.id} 입니다.');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              chatRoomId: doc.id,
                              userName: nick,
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
