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
  final String sellerEmail; // 0327
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
    required this.sellerEmail,//0327
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
    final myEmail = FirebaseAuth.instance.currentUser?.email;
    final sellerEmail = widget.sellerEmail;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                '${widget.price} ',
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
              SizedBox(height: 50), // 하단 버튼들과 공간 확보
              // 게시글 수정 및 삭제 버튼 (작성자일 때만 표시)
              if (FirebaseAuth.instance.currentUser?.uid == widget.sellerUid)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // 수정 페이지 이동 로직
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 기능은 아직 미구현입니다.')));
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
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
                            ],
                          ),
                        );

                        if (confirmed) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(widget.productId)
                              .delete();
                          Navigator.pop(context); // 삭제 후 이전 화면으로 이동
                        }
                      },
                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // (1) 댓글 버튼
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
                      // 댓글 페이지로 이동
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
            // (2) Send Message 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

                  if (currentUserEmail == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인이 필요합니다.')),
                    );
                    return;
                  }

                  if (currentUserEmail == widget.sellerEmail) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('자기 자신에게 메시지를 보낼 수 없습니다.')),
                    );
                    return;
                  }

                  // ✅ 채팅방 ID 생성 (이메일 2개 정렬해서 고유값 만들기)
                  List<String> emails = [myEmail!, sellerEmail]; // 두 참여자의 이메일
                  emails.sort(); // 알파벳 순 정렬
                  String chatRoomId = emails.join('_');

                  // ✅ 채팅방 Firestore 문서가 없으면 생성
                  final chatRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);
                  final chatSnapshot = await chatRef.get();

                  if (!chatSnapshot.exists) {
                    await chatRef.set({
                      'participants': emails,
                      'lastMessage': '',
                      'lastTime': FieldValue.serverTimestamp(),
                      'userName': widget.sellerEmail,
                      'location': '', // 원하면 location도 저장 가능
                      'profileImageUrl': '',
                    });
                  }

                  // ✅ 채팅방으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatRoomId: chatRoomId,
                        userName: widget.sellerEmail,
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