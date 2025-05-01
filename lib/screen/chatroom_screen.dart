import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'ProductDetailScreen.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final sender = data['sender'] as String;
          final text = data['text'] as String;
          if (sender != meUid && mounted) {
            Flushbar(
              title: 'New Message',
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

    final myDoc = await FirebaseFirestore.instance.collection('users').doc(meUid).get();
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

  Future<void> _loadSaleStatus() async {
    final doc = await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data.containsKey('saleStatus')) {
        setState(() {
          _saleStatus = data['saleStatus'] as String;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId);

    await chatRef.collection('message').add({
      'text': text,
      'sender': _currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text,
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

  Widget _buildMessageItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isSystem = data['sender'] == 'system';
    if (isSystem) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              data['text'],
              style: TextStyle(
                color: Colors.deepOrange[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    final isMine = data['sender'] == _currentUser?.uid;
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
            Text(data['text'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text(nickname, style: TextStyle(fontSize: 12, color: Colors.black54)),
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

        if (productId.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '⚠️ chatRoom에 productId가 없습니다.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (_saleStatus != saleStatusFromDb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _saleStatus = saleStatusFromDb;
              });
            }
          });
        }

        return Column(
          children: [
            Divider(height: 1),
            GestureDetector(
              child: Container(
                color: Color(0xFFCCE5FF),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (img.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(img, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _currentUser?.uid == sellerUid
                                  ? DropdownButton<String>(
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
                                        if (value == 'reserved') {
                                          await chatRef.collection('message').add({
                                            'text': 'You have scheduled a transaction with $_otherUserNickname.',
                                            'sender': 'system',
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                        }
                                        if (value == 'soldout') {
                                          await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Transaction Confirmation'),
                                              content: Text('Did you complete a transaction with this user?\nIf so, please leave a review!'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text('No'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    // Save to Firestore notifications
                                                    await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(otherUid)
                                                        .collection('notifications')
                                                        .add({
                                                      'type': 'transactionComplete',
                                                      'from': _currentUser?.uid,
                                                      'to': otherUid,
                                                      'nickname': _myNickname,
                                                      'message': '$_myNickname completed a transaction with you. Tap to leave a review!',
                                                      'timestamp': FieldValue.serverTimestamp(),
                                                      'read': false,
                                                      'chatRoomId': widget.chatRoomId,
                                                      'productId': productId,
                                                    });
                                                    // TODO: go to review page
                                                  },
                                                  child: Text('Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                          // Show Flushbar for buyer to review seller
                                          if (_currentUser?.uid != sellerUid) {
                                            Flushbar(
                                              title: 'Transaction Complete',
                                              message: 'Tap to confirm transaction and leave a review.',
                                              mainButton: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text('Transaction Confirmation'),
                                                      content: Text('Did you complete a transaction with this user?\nIf so, please leave a review!'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: Text('No'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            // TODO: navigate to review screen
                                                          },
                                                          child: Text('Yes'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: Text('Review', style: TextStyle(color: Colors.white)),
                                              ),
                                              duration: Duration(seconds: 5),
                                              backgroundColor: Colors.green,
                                              flushbarPosition: FlushbarPosition.TOP,
                                              margin: EdgeInsets.all(8),
                                              borderRadius: BorderRadius.circular(8),
                                            ).show(context);
                                          }
                                        }
                                      },
                                    )
                                  : Container(
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('$price NTD', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_otherUserNickname),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: _productHeader(),
        ),
      ),
      body: Container(
        color: Color(0xFFE6F2FF),
        child: Column(
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
                    return Center(child: Text('No messages yet.'));
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
                        hintText: 'Enter Message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(icon: Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}