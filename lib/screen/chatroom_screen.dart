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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러 추가

  void _sendMessage() async {
    final String message = _messageController.text.trim();

    if (message.isNotEmpty && _currentUser != null) {
      FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('message')
          .add({
        'text': message,
        'sender': _currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      //메시지를 보낸 후 가장 아래로 스크롤 이동
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({

        'lastMessage': message,
        'lastTime': FieldValue.serverTimestamp(),
      });
      _messageController.clear(); // 입력창 초기화
      _messageController.clear();

    }
  }



  @override
  Widget build(BuildContext context) {
    final String currentUserEmail = _currentUser?.email ?? '';
    String otherUserEmail = widget.userName;
    if (widget.chatRoomId.contains('_')) {
      List<String> emails = widget.chatRoomId.split('_');
      otherUserEmail = emails.firstWhere(
            (email) => email != currentUserEmail,
        orElse: () => widget.userName,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(otherUserEmail),),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('message')
                  .orderBy('timestamp', descending: false) // 최신 메시지가 아래로 옴
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
                  controller: _scrollController, // 스크롤 컨트롤러 연결
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['sender'] == _currentUser?.email;

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
                            Text(message['text'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              message['sender'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
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
