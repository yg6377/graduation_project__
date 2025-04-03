import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String productTitle;
  final String productImageUrl;
  final String productPrice;

  const ChatRoomScreen({
    Key? key,
    required this.chatRoomId,
    required this.userName,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _otherUserNickname = '상대방';
  late String otherUid;

  @override
  void initState() {
    super.initState();

    final currentUid = _currentUser?.uid ?? '';
    final uids = widget.chatRoomId.split('_');
    otherUid = uids.firstWhere((uid) => uid != currentUid, orElse: () => '');

    // 닉네임 가져오기
    if (otherUid.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(otherUid).get().then((doc) {
        if (doc.exists && doc.data()!.containsKey('nickname')) {
          setState(() {
            _otherUserNickname = doc['nickname'];
          });
        }
      });
    }
  }

  void _sendMessage() async {
    final String message = _messageController.text.trim();

    if (message.isNotEmpty && _currentUser != null) {
      FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('message')
          .add({
        'text': message,
        'sender': _currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      // 최신 메시지 정보 업데이트
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': message,
        'lastTime': FieldValue.serverTimestamp(),
      });

      // 자동 스크롤
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_otherUserNickname)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('message')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('대화가 없습니다.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['sender'] == _currentUser?.uid;

                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(message['sender']).get(),
                              builder: (context, snapshot) {
                                String senderNickname = '알 수 없음';
                                if (snapshot.hasData && snapshot.data != null) {
                                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                                  if (userData.containsKey('nickname')) {
                                    senderNickname = userData['nickname'];
                                  }
                                }

                                return Text(
                                  senderNickname,
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
