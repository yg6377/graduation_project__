import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProductDetailScreen.dart'; // Adjust the import path as needed

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  Future<List<DocumentSnapshot>> _fetchFavoriteProducts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final likedProductIds = <String>[];

    final likesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('likes')
        .where('uid', isEqualTo: currentUser.uid)
        .get();

    for (var likeDoc in likesSnapshot.docs) {
      final productRef = likeDoc.reference.parent.parent;
      if (productRef != null) {
        likedProductIds.add(productRef.id);
      }
    }

    final productSnapshots = await Future.wait(
      likedProductIds.map((productId) async {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        return productDoc.exists ? productDoc : null;
      }).where((e) => e != null),
    );

    return productSnapshots.cast<DocumentSnapshot>();
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
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text((data['price'] ?? '').toString()),
                  leading: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                      ? Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 60),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                              productId: products[index].id,
                          title: data['title'] ?? '',
                          price: (data['price'] ?? '').toString(),
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
