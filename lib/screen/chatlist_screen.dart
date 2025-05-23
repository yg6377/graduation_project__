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
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('participants', arrayContains: me)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final chats = docs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final leavers = List<String>.from(data['leavers'] ?? []);
            return !leavers.contains(me);
          }).toList();

          chats.sort((a, b) {
            final aTs = (a.data()! as Map<String, dynamic>)['lastTime'] as Timestamp?;
            final bTs = (b.data()! as Map<String, dynamic>)['lastTime'] as Timestamp?;

            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;    // aTs 없으면 뒤로
            if (bTs == null) return -1;   // bTs 없으면 a가 앞으로

            return bTs.compareTo(aTs);    // 내림차순
          });
          if (chats.isEmpty) return Center(child: Text('No chats available.'));

          final nicknameFutures = <Future<void>>[];
          final nicknameMap = <String, String>{};
          final profileUrlMap = <String, String>{};
          final productNameMap = <String, String>{};


          for (var doc in chats) {
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
                profileUrlMap[other] = userDoc.exists && userDoc.data()!.containsKey('profileImageUrl') // ⭐ 추가
                    ? userDoc['profileImageUrl']
                    : '';

              }));
            }
            if (!productNameMap.containsKey(doc.id)) { //이름+상품명
              productNameMap[doc.id] = data['productName'] ?? 'Unknown Product';
            }
          }

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

                  final profileUrl = profileUrlMap[otherUid] ?? "";
                  final nick = nicknameMap[otherUid] ?? "Unknown";
                  final productName = productNameMap[doc.id] ?? data['productName'] ?? 'Unknown Product';


                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Leave Chat'),
                          content: Text('Are you sure you want to leave this chat?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Leave'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(doc.id);

                      final data = doc.data()! as Map<String, dynamic>;
                      final participants = List<String>.from(data['participants'] ?? []);
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;

                      if (currentUid == null) return;

                      final updatedDoc = await chatRoomRef.get();
                      final updatedData = updatedDoc.data() as Map<String, dynamic>;
                      final leavers = List<String>.from(updatedData['leavers'] ?? []);

                      if (leavers.contains(currentUid)) {
                        // Already left, do nothing
                        return;
                      }

                      // 1. leavers 필드에 현재 유저 추가
                      await chatRoomRef.update({
                        'leavers': FieldValue.arrayUnion([currentUid])
                      });

                      // 2. 상대방도 나간 경우 전체 삭제
                      final updatedDoc2 = await chatRoomRef.get();
                      final updatedData2 = updatedDoc2.data() as Map<String, dynamic>;
                      final leavers2 = List<String>.from(updatedData2['leavers'] ?? []);

                      final allLeft = participants.every((uid) => leavers2.contains(uid));

                      if (allLeft) {
                        final messages = await chatRoomRef.collection('message').get();
                        for (final message in messages.docs) {
                          await message.reference.delete();
                        }
                        await chatRoomRef.delete();
                      } else {
                        // Only send "user has left" system message if current user is first to leave
                        final otherUid = participants.firstWhere((u) => u != currentUid, orElse: () => "");
                        if (!leavers.contains(currentUid) && !leavers.contains(otherUid)) {
                          await chatRoomRef.collection('message').add({
                            'senderId': 'system',
                            'text': '${nicknameMap[currentUid] ?? 'A user'} has left the chat.',
                            'timestamp': FieldValue.serverTimestamp(),
                            'type': 'system',
                          });
                        }
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

                      title: Text(
                        '$nick ($productName)',  // ✅ 상품명 (상대 닉네임) 형태로!
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),

                      subtitle: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            lastTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 6),
                          if (unread > 0)
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),

                      onTap: () {
                        print('The UID of this chat room is ${doc.id}');
                        FirebaseFirestore.instance
                            .collection('chatRooms')
                            .doc(doc.id)
                            .update({'unreadCounts.$me': 0});


                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              chatRoomId: doc.id,
                              userName: nick,
                              saleStatus: data['saleStatus'] as String? ?? 'selling',
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
