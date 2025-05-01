import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String userName;

  const ChatRoomScreen({
    Key? key,
    required this.chatRoomId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgCtrl    = TextEditingController();
  final ScrollController        _scrollCtrl = ScrollController(initialScrollOffset: 1000000);
  final User?                   _meUser     = FirebaseAuth.instance.currentUser;
  late StreamSubscription<QuerySnapshot> _sub;

  String _myNick    = '나';
  String _otherNick = '상대방';
  late String otherUid;

  @override
  void initState() {
    super.initState();
    _resetUnread();
    _loadNicknames();
    _listenNewMessages();
  }

  @override
  void dispose() {
    _sub.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetUnread() async {
    final me = _meUser?.uid;
    if (me == null) return;
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .update({'unreadCounts.$me': 0});
  }

  void _listenNewMessages() {
    final me = _meUser?.uid;
    _sub = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('message')
        .orderBy('timestamp')
        .snapshots()
        .skip(1)
        .listen((snap) {
      for (var c in snap.docChanges) {
        if (c.type == DocumentChangeType.added) {
          final d      = c.doc.data()! as Map<String, dynamic>;
          final sender = d['sender'] as String;
          if (sender != me && mounted) {
            Flushbar(
              title:   '새 메시지',
              message: d['text'] as String,
              duration: Duration(seconds: 3),
            ).show(context);
          }
        }
      }
    });
  }

  Future<void> _loadNicknames() async {
    final me = _meUser?.uid ?? '';
    var parts = widget.chatRoomId.split('_');
    otherUid = parts.firstWhere((u) => u != me, orElse: () => '');

    final mine = await FirebaseFirestore.instance.collection('users').doc(me).get();
    if (mine.exists) _myNick = mine['nickname'] ?? _myNick;

    final other = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    if (other.exists) setState(() => _otherNick = other['nickname'] ?? _otherNick);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _meUser == null) return;
    final me  = _meUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId);

    // 메시지 추가
    await ref.collection('message').add({
      'text':      text,
      'sender':    me,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 마지막 메시지, 타임, 상대 unread 증가
    final room = (await ref.get()).data()! as Map<String, dynamic>;
    final parts = List<String>.from(room['participants']);
    final other = parts.firstWhere((u) => u != me);
    await ref.update({
      'lastMessage':          text,
      'lastTime':             FieldValue.serverTimestamp(),
      'unreadCounts.$other':  FieldValue.increment(1),
    });

    _msgCtrl.clear();
  }

  Widget _buildItem(QueryDocumentSnapshot doc) {
    final d      = doc.data()! as Map<String, dynamic>;
    final isMe   = d['sender'] == _meUser?.uid;
    final nick   = isMe ? _myNick : _otherNick;
    final ts     = (d['timestamp'] as Timestamp?)?.toDate();
    final time   = ts == null
        ? ''
        : '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:  EdgeInsets.symmetric(vertical:4, horizontal:12),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(d['text'] as String),
            SizedBox(height:4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nick, style: TextStyle(fontSize:12, color:Colors.black54)),
                SizedBox(width:6),
                Text(time, style: TextStyle(fontSize:10, color:Colors.black45)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || !snap.data!.exists) return SizedBox.shrink();
        final d     = snap.data!.data()! as Map<String, dynamic>;
        final title = d['productTitle']    as String? ?? '';
        final img   = d['productImageUrl'] as String? ?? '';
        final price = d['productPrice']    as String? ?? '';
        if (title.isEmpty) return SizedBox.shrink();
        return Container(
          color:  Colors.grey[100],
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              if (img.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(img, width:50, height:50, fit:BoxFit.cover),
                ),
              SizedBox(width:12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$price원'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_otherNick),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: _productHeader(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('message')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                return ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) => _buildItem(msgs[i]),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                SizedBox(width:8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





