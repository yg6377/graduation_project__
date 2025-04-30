import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';

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
  late StreamSubscription<QuerySnapshot> _msgSub;

  String _myNickname = '나';
  String _otherUserNickname = '상대방';
  late String otherUid;

  @override
  void initState() {
    super.initState();
    _loadNicknames();
    _listenForNewMessages();
  }

  void _listenForNewMessages() {
    final currentUid = _currentUser?.uid;
    _msgSub = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('message')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .skip(1)
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final sender = data['sender'] as String;
          final text = data['text'] as String;
          if (sender != currentUid && mounted) {
            // 인앱 배너 알림
            Flushbar(
              title: '새 메시지',
              message: text,
              duration: Duration(seconds: 3),
              flushbarPosition: FlushbarPosition.TOP,
              margin: EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(8),
            ).show(context);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNicknames() async {
    final currentUid = _currentUser?.uid ?? '';
    final uids = widget.chatRoomId.split('_');
    otherUid = uids.firstWhere((uid) => uid != currentUid, orElse: () => '');

    final myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    if (myDoc.exists && myDoc.data()!.containsKey('nickname')) {
      _myNickname = myDoc['nickname'];
    }

    final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    if (otherDoc.exists && otherDoc.data()!.containsKey('nickname')) {
      setState(() {
        _otherUserNickname = otherDoc['nickname'];
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUser == null) return;

    final msgData = {
      'text': message,
      'sender': _currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId);
    await chatRef.collection('message').add(msgData);
    await chatRef.update({
      'lastMessage': message,
      'lastTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageItem(QueryDocumentSnapshot message) {
    final senderUid = message['sender'];
    final isMine = senderUid == _currentUser?.uid;
    final nickname = isMine ? _myNickname : _otherUserNickname;

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
            Text(
              nickname,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
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
                  itemBuilder: (context, index) => _buildMessageItem(messages[index]),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
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

