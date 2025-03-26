import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductCommentsScreen extends StatefulWidget {
  final String productId;  // 어느 상품의 댓글인지 구분하기 위해 필요

  const ProductCommentsScreen({
    required this.productId,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductCommentsScreen> createState() => _ProductCommentsScreenState();
}

class _ProductCommentsScreenState extends State<ProductCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          // 댓글 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.productId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['text'] ?? ''),
                      subtitle: Text(data['userId'] ?? 'Unknown'),
                      );
                  },
                );
              },
            ),
          ),

          // 댓글 입력창
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Enter Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final userId = FirebaseAuth.instance.currentUser?.uid ?? '익명';
                    if (_commentController.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.productId)
                          .collection('comments')
                          .add({
                        'text': _commentController.text.trim(),
                        'userId': userId,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      _commentController.clear();
                    }
                  },
                  child: Text('upload'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}