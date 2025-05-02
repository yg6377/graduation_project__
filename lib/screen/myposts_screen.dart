import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart'; // Replace with your actual import path

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('My Posts')),
        body: Center(child: Text('You must be logged in to view your posts.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Posts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerUid', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No posts found.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final condition = data['condition'] ?? '';
              final title = data['title'] ?? '';
              final displayTitle = title;
              final imageUrls = data['imageUrls'];
              final imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
                  ? imageUrls.first.toString()
                  : ((data['imageUrl'] ?? '').toString().isNotEmpty
                      ? data['imageUrl']
                      : 'assets/images/huanhuan_no_image.png');
              final price = data['price']?.toString() ?? '';
              final nickname = data['userName'] ?? '';
              final region = data['region'] ?? '';
              final saleStatus = data['saleStatus'] ?? '';
              final timestamp = data['timestamp']?.toDate();

              String formattedTime = 'Unknown';
              if (timestamp != null) {
                final difference = DateTime.now().difference(timestamp);
                if (difference.inDays > 7) {
                  formattedTime = '${timestamp.month}/${timestamp.day}/${timestamp.year}';
                } else if (difference.inDays >= 1) {
                  formattedTime = '${difference.inDays}days before';
                } else if (difference.inHours >= 1) {
                  formattedTime = '${difference.inHours}hours before';
                } else if (difference.inMinutes >= 1) {
                  formattedTime = '${difference.inMinutes}minutes before';
                } else {
                  formattedTime = 'a moment ago';
                }
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: posts[index].id,
                        title: displayTitle,
                        price: price,
                        description: data['description'] ?? '',
                        imageUrl: imageUrl,
                        timestamp: formattedTime,
                        sellerUid: data['sellerUid'] ?? '',
                        sellerEmail: data['sellerUid'] ?? '',
                        chatRoomId: '',
                        userName: nickname,
                        productTitle: title,
                        productImageUrl: (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
                            ? data['imageUrls'].first.toString()
                            : ((data['imageUrl'] ?? '').toString().isNotEmpty
                                ? data['imageUrl']
                                : 'assets/images/huanhuan_no_image.png'),
                        productPrice: price,
                      ),
                    ),
                  );
                },
                child: ProductCard(
                  title: displayTitle,
                  imageUrl: imageUrl,
                  price: price,
                  region: region,
                  saleStatus: saleStatus,
                  condition: condition,
                  chatCount: (data['chats'] ?? 0) is int ? data['chats'] : 0,
                  likeCount: (data['likes'] ?? 0) is int ? data['likes'] : 0,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
