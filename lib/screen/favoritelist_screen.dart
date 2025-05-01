import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart'; // Adjust the import path as needed

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  Future<List<DocumentSnapshot>> _fetchFavoriteProducts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Get liked product IDs
    final likedRefs = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('likedProducts')
        .get();

    // Fetch each product document
    final futures = likedRefs.docs.map((doc) async {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(doc.id)
          .get();
      return productDoc.exists ? productDoc : null;
    }).toList();

    // Await all fetches
    final results = await Future.wait(futures);

    // Filter out any nulls and cast to DocumentSnapshot
    return results.whereType<DocumentSnapshot>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Favorite List')),
        body: Center(child: Text('You must be logged in to view favorites.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Favorite List')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchFavoriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No favorites yet.'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final condition = data['condition'] ?? '';
              final title = data['title'] ?? '';
              final displayTitle = condition.isNotEmpty ? '[$condition] $title' : title;
              final saleStatus = data['saleStatus'] ?? '';
              final region = data['region'] ?? '';
              return Card(
                margin: EdgeInsets.all(8),
                child: ProductCard(
                  title: displayTitle,
                  imageUrl: data['imageUrl'] ?? '',
                  price: (data['price'] ?? '').toString(),
                  region: region,
                  saleStatus: saleStatus,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                              productId: products[index].id,
                          title: displayTitle,
                          price: (data['price'] ?? '').toString(),
                          description: data['description'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          timestamp: data['timestamp']?.toDate().toString() ?? '',
                          sellerUid: data['sellerUid'] ?? 'unknown',
                          sellerEmail: data['sellerUid'] ?? '',
                          chatRoomId: '',
                          userName: '',
                          productTitle: title,
                          productImageUrl: data['imageUrl'] ?? '',
                          productPrice: (data['price'] ?? '').toString(),
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
