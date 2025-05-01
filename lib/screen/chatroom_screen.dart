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
  // 초기 오프셋을 크게 줘서 리스트가 맨 아래(최신 메시지)에서 시작하도록 함
  final ScrollController _scrollController =
  ScrollController(initialScrollOffset: 1000000);
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late StreamSubscription<QuerySnapshot> _msgSub;

  String _myNickname = '나';
  String _otherUserNickname = '상대방';
  late String otherUid;
  String _saleStatus = 'selling';

  @override
  void initState() {
    super.initState();
    _loadNicknames();
    _listenForNewMessages();
    _loadSaleStatus();
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenForNewMessages() {
    final meUid = _currentUser?.uid;
    _msgSub = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('message')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .skip(1)
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final msg = change.doc.data()! as Map<String, dynamic>;
          final sender = msg['sender'] as String;
          final text = msg['text'] as String;
          if (sender != meUid && mounted) {
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

  Future<void> _loadNicknames() async {
    final meUid = _currentUser?.uid ?? '';
    final parts = widget.chatRoomId.split('_');
    otherUid = parts.firstWhere((u) => u != meUid, orElse: () => '');

    final myDoc =
    await FirebaseFirestore.instance.collection('users').doc(meUid).get();
    if (myDoc.exists && myDoc.data()!.containsKey('nickname')) {
      _myNickname = myDoc['nickname'];
    }

    final otherDoc =
    await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    if (otherDoc.exists && otherDoc.data()!.containsKey('nickname')) {
      setState(() {
        _otherUserNickname = otherDoc['nickname'];
      });
    }
  }

  Future<void> _loadSaleStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .get();
    if (doc.exists) {
      final map = doc.data()!;
      if (map.containsKey('saleStatus')) {
        setState(() {
          _saleStatus = map['saleStatus'] as String;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final myUid = _currentUser!.uid;
    final chatRef = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId);

    await chatRef.collection('message').add({
      'text': text,
      'sender': myUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // lastMessage, lastTime 업데이트
    await chatRef.update({
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Widget _buildMessageItem(QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final isMine = data['sender'] == _currentUser?.uid;
    final nick = isMine ? _myNickname : _otherUserNickname;

    // 시간 포맷
    String timeString = '';
    if (data['timestamp'] != null) {
      final dt = (data['timestamp'] as Timestamp).toDate();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      timeString = '$h:$m';
    }

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
          crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(data['text'] as String, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nick, style: TextStyle(fontSize: 12, color: Colors.black54)),
                SizedBox(width: 6),
                Text(timeString,
                    style: TextStyle(fontSize: 10, color: Colors.black45)),
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
        final data = snap.data!.data()! as Map<String, dynamic>;
        final title = data['productTitle'] as String? ?? '';
        final img = data['productImageUrl'] as String? ?? '';
        final price = data['productPrice'] as String? ?? '';
        final saleStatusFromDb = data['saleStatus'] as String? ?? 'selling';
        final productId = data['productId'] as String? ?? '';
        final sellerUid = data['sellerUid'] as String? ?? '';

        // saleStatus가 바뀌면 state 갱신
        if (_saleStatus != saleStatusFromDb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _saleStatus = saleStatusFromDb;
              });
            }
          });
        }

        if (title.isEmpty) return SizedBox.shrink();

        return Column(
          children: [
            Divider(height: 1),
            GestureDetector(
              onTap: () {
                // 상품 상세로 이동하려면 여기에 Navigator.push
              },
              child: Container(
                color: Color(0xFFCCE5FF),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (img.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                        Image.network(img, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 판매자가 본인일 때 상태 변경 드롭다운
                              if (_currentUser?.uid == sellerUid)
                                DropdownButton<String>(
                                  value: _saleStatus,
                                  items: [
                                    DropdownMenuItem(value: 'selling', child: Text('Selling')),
                                    DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                                    DropdownMenuItem(value: 'soldout', child: Text('Sold Out')),
                                  ],
                                  onChanged: (value) async {
                                    if (value == null || value == _saleStatus) return;
                                    final chatRef = FirebaseFirestore.instance
                                        .collection('chatRooms')
                                        .doc(widget.chatRoomId);
                                    await chatRef.update({'saleStatus': value});
                                    if (productId.isNotEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('products')
                                          .doc(productId)
                                          .update({'saleStatus': value});
                                    }
                                    setState(() {
                                      _saleStatus = value;
                                    });
                                    // reserved/soldout 시 추가 메시지나 dialog 처리…
                                  },
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _saleStatus == 'soldout'
                                        ? Colors.grey
                                        : _saleStatus == 'reserved'
                                        ? Colors.lightBlueAccent
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _saleStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('$price NTD',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserNickname),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
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
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snap.data!.docs;
                if (messages.isEmpty) {
                  return Center(child: Text('대화가 없습니다.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _buildMessageItem(messages[i]),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



