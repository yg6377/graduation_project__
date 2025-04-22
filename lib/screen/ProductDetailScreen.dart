import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/product_comments.dart';
import 'package:graduation_project_1/screen/chatroom_screen.dart';
import 'package:graduation_project_1/screen/edit_product_screen.dart';

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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditScreen(
                      productId: widget.productId,
                      title: widget.title,
                      price: widget.price,
                      description: widget.description,
                      imageUrl: widget.imageUrl,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                bool confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Comfirm Delete'),
                    content: Text('Are you sure delete your post?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('delete')),
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
              } else if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Thank you! Your report has been received!')),
                );
              }
            },
            itemBuilder: (context) {
              final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.sellerUid;
              if (isOwner) {
                return [
                  PopupMenuItem(value: 'edit', child: Text('edit')),
                  PopupMenuItem(value: 'delete', child: Text('delete')),
                ];
              } else {
                return [
                  PopupMenuItem(value: 'report', child: Text('report')),
                ];
              }
            },
          ),
        ],
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
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(widget.sellerUid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading uploader info...', style: TextStyle(fontSize: 14, color: Colors.grey));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text('Uploader: Unknown', style: TextStyle(fontSize: 14, color: Colors.grey));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final nickname = data['nickname'] ?? 'Unknown';

                return Text('Uploader: $nickname', style: TextStyle(fontSize: 14, color: Colors.grey));
              },
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
                      SnackBar(content: Text('You can’t send a message to yourself.')),
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
                        userName: '', // 닉네임은 ChatRoomScreen 내에서 fetch
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
