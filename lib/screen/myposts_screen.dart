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
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['price'] ?? ''),
                  leading: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                      ? Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 60),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: posts[index].id,
                          title: data['title'] ?? '',
                          price: data['price'] ?? '',
                          description: data['description'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          timestamp: data['timestamp']?.toDate().toString() ?? '',
                          sellerUid: data['sellerUid'] ?? 'unknown',
                          sellerEmail: data['sellerUid'] ?? '',
                          chatRoomId: '', userName: '',
                          productTitle: '',
                          productImageUrl: '',
                          productPrice: '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
