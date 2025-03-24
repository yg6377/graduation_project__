import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/product_comments.dart';
// ─────────────────────────────────────────────────────────────────────────────
// 2. "상품 상세 페이지" 화면
// ─────────────────────────────────────────────────────────────────────────────
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;

  const ProductDetailScreen({
    required this.productId,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
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

      // 🔹 상품 정보 부분
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(widget.imageUrl, width: 200, height: 200, fit: BoxFit.cover)
                    : Icon(Icons.image, size: 200),
              ),
              SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '${widget.price}원',
                style: TextStyle(fontSize: 20, color: Colors.blueAccent),
              ),
              SizedBox(height: 8),
              Text(
                '업로드 시간: ${widget.timestamp}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                widget.description,
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 50), // 하단 버튼들과 공간 확보
            ],
          ),
        ),
      ),

      // 🔹 하단 버튼 2개: 댓글 + Send Message
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
                onPressed: () {
                  // 친구가 구현할 채팅 로직 대신 간단 안내만
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Send Message 버튼 클릭됨! (채팅 미구현)')),
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
