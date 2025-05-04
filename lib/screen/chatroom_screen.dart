import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'ProductDetailScreen.dart';
import 'package:graduation_project_1/screen/reviewForm.dart';

class ChatBubbleClipperLeft extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(10, 0);
    path.lineTo(size.width - 10, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 10);
    path.lineTo(size.width, size.height - 10);
    path.quadraticBezierTo(size.width, size.height, size.width - 10, size.height);
    path.lineTo(10, size.height); //왼쪽 아래
    path.quadraticBezierTo(0, size.height, 0, size.height - 10);
    path.lineTo(0, 10);
    path.quadraticBezierTo(0, 0, 10, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ChatBubbleClipperRight extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 10, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 10);
    path.lineTo(size.width, size.height - 10);
    path.quadraticBezierTo(size.width, size.height, size.width - 10, size.height);
    path.lineTo(10, size.height); //왼쪽 아래
    path.quadraticBezierTo(0, size.height, 0, size.height - 10);
    path.lineTo(0, 10);
    path.quadraticBezierTo(0, 0, 10, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String saleStatus;

  const ChatRoomScreen({
    Key? key,
    required this.chatRoomId,
    required this.userName,
    required this.saleStatus,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late User? _currentUser = FirebaseAuth.instance.currentUser;
  late StreamSubscription<QuerySnapshot> _msgSub;

  String _myNickname = 'Me';
  String _otherUserNickname = 'Other User';
  late String otherUid;



  String _saleStatus = 'selling';

  bool _otherUserLeft = false;

  String _myProfileUrl = '';
  String _otherUserProfileUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
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
    if (myDoc.exists && myDoc.data()!.containsKey('profileImageUrl')) {
      _myProfileUrl = myDoc['profileImageUrl'];
    }

    final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    if (otherDoc.exists && otherDoc.data()!.containsKey('nickname')) {
      setState(() {
        if (otherDoc.exists && otherDoc.data()!.containsKey('nickname')) {
          _otherUserNickname = otherDoc['nickname'];
        }
        if (otherDoc.exists && otherDoc.data()!.containsKey('profileImageUrl')) {
          _otherUserProfileUrl = otherDoc['profileImageUrl'];
        }
      });
    }
  }

  Future<void> _loadSaleStatus() async {
    final doc = await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data.containsKey('saleStatus')) {
        setState(() {
          if (data.containsKey('nickname')) {
            _otherUserNickname = data['nickname'];
          }
          if (data.containsKey('profileImageUrl')) {
            _otherUserProfileUrl = data['profileImageUrl'];
          }
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
      'unreadCounts.$otherUid': FieldValue.increment(1),
    });

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,

        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);  // reverse:true 면 0이 최신 메시지 위치

      }
    });
  }

  Widget _buildMessageItem(QueryDocumentSnapshot doc, String? previousSender) {
    final data = doc.data() as Map<String, dynamic>;
    final isMine = data['sender'] == _currentUser?.uid;
    final nickname = isMine ? _myNickname : _otherUserNickname;
    final profileUrl = isMine ? _myProfileUrl : _otherUserProfileUrl;
    final isSystem = data['sender'] == 'system';
    if (isSystem) {
      final type = data['type'] ?? '';
      final isReviewPrompt = type == 'review_prompt';
      final isReserved = type == 'reserved'; // <<< 추가

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: isReviewPrompt
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Did you have a good transaction with $_otherUserNickname?',
                  style: TextStyle(color: Colors.deepOrange[900]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewForm(
                          toUserId: otherUid,
                          fromUserId: _currentUser!.uid,
                          fromNickname: _myNickname,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Leave a review',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.deepOrange[900],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
                : isReserved
                ? Text(
              'You have scheduled a transaction with $_otherUserNickname.',
              style: TextStyle(
                color: Colors.deepOrange[900],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                : Text(
              data['text'],
              style: TextStyle(
                color: Colors.deepOrange[900],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final type = data['type'] ?? '';



    String time = '';
    if (data['timestamp'] != null) {
      final dt = (data['timestamp'] as Timestamp).toDate();
      time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final showTail = previousSender != data['sender']; // 이전 발신자랑 다르면 꼬리 O

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine)
            CircleAvatar(
              radius: 16,
              backgroundImage: profileUrl.isNotEmpty
                  ? NetworkImage(profileUrl)
                  : AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
          if (!isMine) SizedBox(width: 8),
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showTail) // 꼬리 있을 때만 닉네임 보여주기
                Text(
                  nickname,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              if (showTail) SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: isMine
                    ? [
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  SizedBox(width: 4),
                  showTail
                      ? ClipPath(
                    clipper: ChatBubbleClipperRight(),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 250),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[200],
                      ),
                      child: Text(
                        data['text'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                      : Container(
                    constraints: BoxConstraints(maxWidth: 250),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['text'],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ]
                    : [
                  showTail
                      ? ClipPath(
                    clipper: ChatBubbleClipperLeft(),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 250),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                      ),
                      child: Text(
                        data['text'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                      : Container(
                    constraints: BoxConstraints(maxWidth: 250),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['text'],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          if (isMine) SizedBox(width: 8),
          if (isMine)
            CircleAvatar(
              radius: 16,
              backgroundImage: profileUrl.isNotEmpty
                  ? NetworkImage(profileUrl)
                  : AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
        ],
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
        final imgList = List<String>.from(data['imageUrls'] ?? []);
        final img = data.containsKey('imageUrls') && imgList.isNotEmpty
            ? imgList.first
            : (data['imageUrl'] as String? ?? '');
        final price = data['productPrice'] as String? ?? '';
        final saleStatusFromDb = data['saleStatus'] as String? ?? 'selling';
        final productId = data['productId'] as String? ?? '';
        // final sellerUid = data['sellerUid'] as String? ?? '';

        // --- Leaver check ---
        final leavers = List<String>.from(data['leavers'] ?? []);
        if (leavers.contains(otherUid)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _otherUserLeft = true;
              });
            }
          });
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '⚠️ The other user has left the chat.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _otherUserLeft) {
              setState(() {
                _otherUserLeft = false;
              });
            }
          });
        }
        // --- End leaver check ---

        if (productId.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '⚠️ No productId found for this chat room.',
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: img.isNotEmpty
                          ? FadeInImage.assetNetwork(
                        placeholder: 'assets/images/huanhuan_no_image.png',
                        image: img,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/huanhuan_no_image.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                          : Image.asset(
                        'assets/images/huanhuan_no_image.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || !snapshot.data!.exists) return SizedBox.shrink();
                                  final productData = snapshot.data!.data() as Map<String, dynamic>;
                                  final isOwner = _currentUser?.uid == productData['sellerUid'];
                                  final productSaleStatus = productData['saleStatus'] as String? ?? 'selling';
                                  return isOwner
                                      ? DropdownButton<String>(
                                    value: ['selling', 'reserved', 'soldout'].contains(productSaleStatus) ? productSaleStatus : 'selling',

                                    items: [
                                      DropdownMenuItem(value: 'selling', child: Text('Selling')),
                                      DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                                      DropdownMenuItem(value: 'soldout', child: Text('Sold Out')),
                                    ],
                                    onChanged: (value) async {
                                      if (value == null || value == productSaleStatus) return;
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
                                          'type': 'reserved',
                                        });
                                      }
                                      if (value == 'soldout') {
                                        final reviewPrompt = 'Did you have a good transaction with $_otherUserNickname? Leave a review. [Review]';
                                        await chatRef.collection('message').add({
                                          'text': reviewPrompt,
                                          'sender': 'system',
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'type': 'review_prompt',
                                        });
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
                                      }
                                    },
                                  )
                                      : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: productSaleStatus == 'soldout'
                                          ? Colors.grey
                                          : productSaleStatus == 'reserved'
                                          ? Colors.lightBlueAccent
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      productSaleStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
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
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            tooltip: 'Leave',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Do you want to leave the chat room?'),
                  actions: [
                    TextButton(
                      child: Text('No'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    TextButton(
                      child: Text('Yes'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );

              if (confirmed == true && _currentUser?.uid != null) {
                final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId);
                final doc = await chatRoomRef.get();
                final data = doc.data() ?? {};
                final participants = List<String>.from(data['participants'] ?? []);
                final uid = _currentUser!.uid;

                await chatRoomRef.update({
                  'leavers': FieldValue.arrayUnion([uid]),
                });

                final updatedDoc = await chatRoomRef.get();
                final updatedLeavers = List<String>.from(updatedDoc.data()?['leavers'] ?? []);

                final allLeft = participants.every((uid) => updatedLeavers.contains(uid));
                if (allLeft) {
                  final messages = await chatRoomRef.collection('message').get();
                  for (final msg in messages.docs) {
                    await msg.reference.delete();
                  }
                  await chatRoomRef.delete();
                }

                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
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
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final messages = snap.data!.docs;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  });
                  if (messages.isEmpty) {
                    return Center(child: Text('No messages yet.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final current = messages[i];
                      final previous = i + 1 < messages.length ? messages[i + 1] : null;
                      final previousSender = previous != null ? (previous.data() as Map<String, dynamic>)['sender'] : null;


                      return _buildMessageItem(current, previousSender);
                    },
                  );

                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: _otherUserLeft
                  ? Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You cannot send a message because the other user has left the chat.',
                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
                  : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
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