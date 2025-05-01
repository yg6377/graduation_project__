import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
              final displayTitle = condition.isNotEmpty ? '[$condition] $title' : title;
              final imageUrl = data['imageUrl'] ?? '';
              final price = data['price']?.toString() ?? '';
              final nickname = data['userName'] ?? '';
              final region = data['region'] ?? '';
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
                        productImageUrl: imageUrl,
                        productPrice: price,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.asset('assets/images/huanhuan_no_image.png'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('$price NTD', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 4),
                              Text('$nickname • $region', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(formattedTime, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
