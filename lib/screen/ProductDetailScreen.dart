import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/product_comments.dart';
import 'package:graduation_project_1/screen/chatroom_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;
  final String sellerEmail;
  final String sellerUid;
  final String chatRoomId;
  final String userName;
  final String productTitle;
  final String productImageUrl;
  final String productPrice;

  const ProductDetailScreen({
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
    Key? key,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                widget.imageUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.image, size: 200),
            ),
            SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${widget.price}',
              style: TextStyle(fontSize: 20, color: Colors.blueAccent),
            ),
            SizedBox(height: 8),
            Text(
              'Uploaded by: ${widget.timestamp}',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              widget.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 50),
            if (FirebaseAuth.instance.currentUser?.uid == widget.sellerUid)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('수정 기능은 아직 미구현입니다.')),
                      );
                    },
                    child: Text('수정'),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      bool confirmed = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('삭제 확인'),
                          content: Text('정말 이 게시글을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('취소')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('삭제')),
                          ],
                        ),
                      );

                      if (confirmed) {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(widget.productId)
                            .delete();
                        Navigator.pop(context);
                      }
                    },
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productId)
                    .collection('comments')
                    .snapshots(),
                builder: (context, snapshot) {
                  int commentCount = 0;
                  if (snapshot.hasData) {
                    commentCount = snapshot.data!.size;
                  }
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCommentsScreen(
                            productId: widget.productId,
                          ),
                        ),
                      );
                    },
                    child: Text('Comments ($commentCount)'),
                  );
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인이 필요합니다.')),
                    );
                    return;
                  }

                  final myUid = currentUser.uid;
                  final sellerUid = widget.sellerUid;

                  if (myUid == sellerUid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('자기 자신에게 메시지를 보낼 수 없습니다.')),
                    );
                    return;
                  }

                  List<String> uids = [myUid, sellerUid]..sort();
                  final chatRoomId = uids.join('_');

                  final chatRef = FirebaseFirestore.instance
                      .collection('chatRooms')
                      .doc(chatRoomId);
                  final chatSnapshot = await chatRef.get();

                  if (!chatSnapshot.exists) {
                    await chatRef.set({
                      'participants': uids,
                      'lastMessage': '',
                      'lastTime': FieldValue.serverTimestamp(),
                      'location': '',
                      'profileImageUrl': '',
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatRoomId: chatRoomId,
                        userName: '', // ChatRoomScreen에서 닉네임 직접 fetch함
                        productTitle: widget.title,
                        productImageUrl: widget.imageUrl,
                        productPrice: widget.price,
                      ),
                    ),
                  );
                },
                child: Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
