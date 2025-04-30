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
                  DropdownMenuItem(value: 'selling', child: Text('Selling', style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 'inProgress', child: Text('Reserved', style: TextStyle(color: Colors.black))),
                  DropdownMenuItem(value: 'soldOut', child: Text('Sold Out', style: TextStyle(color: Colors.black))),
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
            Container(
              width: double.infinity,
              height: 400, // 원하는 높이 설정
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.image, size: 100),
            ),
            SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final saleStatus = data['saleStatus'] ?? 'selling';
                final price = data['price'] ?? widget.price;
                final condition = data['condition'] ?? '';

                String saleStatusText;
                if (saleStatus == 'selling') {
                  saleStatusText = 'Selling';
                } else if (saleStatus == 'inProgress') {
                  saleStatusText = 'Reserved';
                } else if (saleStatus == 'soldOut') {
                  saleStatusText = 'Sold Out';
                } else {
                  saleStatusText = 'Selling';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.title}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
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
                final profileImageUrl = data['image'] ?? '';

                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (profileImageUrl.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                          radius: 20,
                        )
                      else
                        CircleAvatar(
                          child: Icon(Icons.person),
                          radius: 20,
                        ),
                      SizedBox(width: 8),
                      Text(
                        nickname,
                        style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                );
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
        padding: EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 좋아요 버튼 + 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    // TODO: Implement like toggle logic
                  },
                ),
                SizedBox(width: 5), // 아이콘과 구분선 사이 여백
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.grey,
                ),
                SizedBox(width: 8), // 구분선과 가격 사이 여백
                Text(
                  '${widget.price} NTD',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // 댓글 버튼
            StreamBuilder<QuerySnapshot>(
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
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment),
                      iconSize: 30,
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
                    ),
                    if (commentCount > 0)
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$commentCount',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),

            // 메세지 버튼
            IconButton(
              icon: Icon(Icons.message),
              iconSize: 30,
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Need to Login')),
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
                      userName: '',
                      productTitle: widget.title,
                      productImageUrl: widget.imageUrl,
                      productPrice: widget.price,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
