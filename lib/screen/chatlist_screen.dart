import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  String formatLastTime(Timestamp? ts) {
    if (ts == null) return "";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return "just now";
    if (diff.inHours   < 1) return "${diff.inMinutes}min ago";
    if (diff.inHours   < 24) return "${diff.inHours}hr ago";
    return "${diff.inDays}days ago";
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
                    : 'Unknown';
              }));
            }
          }

          final chats = docs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final leavers = List<String>.from(data['leavers'] ?? []);
            return !leavers.contains(me);
          }).toList();
          if (chats.isEmpty) return Center(child: Text('No chats available.'));

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
                  final leavers = List<String>.from(data['leavers'] ?? []);
                  final lastMsg = (!leavers.contains(me) && leavers.contains(otherUid))
                      ? "The other user has left the chat."
                      : data['lastMessage'] as String? ?? "";
                  final lastTime = formatLastTime(data['lastTime'] as Timestamp?);

                  final raw = data['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
                  final counts = Map<String, dynamic>.from(raw);
                  final unread = counts[me] as int? ?? 0;

                  final profileUrl = data['profileImageUrl'] as String? ?? "";
                  final nick = nicknameMap[otherUid] ?? "Unknown";

                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(doc.id);
                      final data = doc.data()! as Map<String, dynamic>;
                      final participants = List<String>.from(data['participants'] ?? []);
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;

                      if (currentUid == null) return;

                      // 1. leavers 필드에 현재 유저 추가
                      await chatRoomRef.update({
                        'leavers': FieldValue.arrayUnion([currentUid])
                      });

                      // 2. 상대방도 나간 경우 전체 삭제
                      final updatedDoc = await chatRoomRef.get();
                      final updatedData = updatedDoc.data() as Map<String, dynamic>;
                      final leavers = List<String>.from(updatedData['leavers'] ?? []);

                      final allLeft = participants.every((uid) => leavers.contains(uid));

                      if (allLeft) {
                        final messages = await chatRoomRef.collection('message').get();
                        for (final message in messages.docs) {
                          await message.reference.delete();
                        }
                        await chatRoomRef.delete();
                      }
                    },
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
                        print('The UID of this chat room is ${doc.id}');
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
