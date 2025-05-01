import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;
  final String sellerEmail;
  final String sellerUid;

  // 아래 4개는 기존에 다른 화면에서 넘기던 파라미터들입니다.
  final String chatRoomId;
  final String userName;
  final String productTitle;
  final String productImageUrl;
  final String productPrice;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    required this.sellerEmail,
    required this.sellerUid,
    required this.chatRoomId,
    required this.userName,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _auth = FirebaseAuth.instance;

  Future<void> _goChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 필요')),
      );
      return;
    }
    final myUid     = user.uid;
    final sellerUid = widget.sellerUid;
    if (myUid == sellerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자기 자신에게는 메시지를 보낼 수 없습니다.')),
      );
      return;
    }

    // 채팅방 ID 생성 및 participants 정리
    List<String> uids = [myUid, sellerUid]..sort();
    final chatRoomId = uids.join('_');
    final chatRef    = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);

    // 신규 생성 시 unreadCounts 포함 초기화
    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        'participants'    : uids,
        'lastMessage'     : '',
        'lastTime'        : FieldValue.serverTimestamp(),
        'unreadCounts'    : { uids[0]: 0, uids[1]: 0 },
        'productId'       : widget.productId,
        'productTitle'    : widget.title,
        'productImageUrl' : widget.imageUrl,
        'productPrice'    : widget.price,
      });
    }

    // 채팅방 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chatRoomId: chatRoomId,
          userName:   widget.sellerEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // … 상단 상품 이미지 · 설명 등 …
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: _goChat,
          child: Text('Go Chat'),
        ),
      ),
    );
  }
}
