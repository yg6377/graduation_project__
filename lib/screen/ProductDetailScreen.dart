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
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  void _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('likedProducts')
        .doc(widget.productId)
        .get();
    setState(() {
      _isLiked = doc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Product');
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final saleStatus = data['saleStatus'] ?? 'selling';
            String saleStatusText = 'Selling';
            if (saleStatus == 'inProgress') {
              saleStatusText = 'Reserved';
            } else if (saleStatus == 'soldOut') {
              saleStatusText = 'Sold Out';
            }

            final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.sellerUid;

            if (isOwner) {
              return DropdownButton<String>(
                value: saleStatus,
                underline: SizedBox(),
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                iconEnabledColor: Colors.black,
                items: [
                  DropdownMenuItem(value: 'selling', child: Text('Selling')),
                  DropdownMenuItem(value: 'inProgress', child: Text('Reserved')),
                  DropdownMenuItem(value: 'soldOut', child: Text('Sold Out')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.productId)
                        .update({'saleStatus': value});
                    setState(() {});
                  }
                },
              );
            } else {
              return Text(
                '<$saleStatusText>',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              );
            }
          },
        ),
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
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure delete your post?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
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
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ];
              } else {
                return [
                  PopupMenuItem(value: 'report', child: Text('Report')),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 300,
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(widget.imageUrl, fit: BoxFit.cover)
                    : Image.asset('assets/images/no image.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Uploaded: ${widget.timestamp}',
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final likedRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('likedProducts')
                    .doc(widget.productId);
                final likedSnapshot = await likedRef.get();
                if (likedSnapshot.exists) {
                  await likedRef.delete();
                } else {
                  await likedRef.set({
                    'productId': widget.productId,
                    'likedAt': FieldValue.serverTimestamp(),
                  });
                }
                setState(() {
                  _isLiked = !_isLiked;
                });
              },
            ),
            Text(
              '${widget.price} NTD',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      chatRoomId: widget.chatRoomId,
                      userName: widget.userName,
                      productTitle: widget.productTitle,
                      productImageUrl: widget.productImageUrl,
                      productPrice: widget.productPrice,
                    ),
                  ),
                );
              },
              child: Text('Go Chat'),
            ),
          ],
        ),
      ),
    );
  }
}