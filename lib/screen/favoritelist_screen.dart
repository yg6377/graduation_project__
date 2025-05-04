import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  _FavoriteListScreenState createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  Future<List<DocumentSnapshot>> _fetchFavoriteProducts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final likedRefs = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('likedProducts')
        .get();

    final futures = likedRefs.docs.map((doc) async {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(doc.id)
          .get();
      return productDoc.exists ? productDoc : null;
    }).toList();

    final results = await Future.wait(futures);
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
              final displayTitle = title;
              final saleStatus = data['saleStatus'] ?? '';
              final imageUrl = (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
                  ? data['imageUrls'].first.toString()
                  : ((data['imageUrl'] ?? '').toString().isNotEmpty
                      ? data['imageUrl']
                      : 'assets/images/huanhuan_no_image.png');
              final regionRaw = data['region'];
              final Map<String, dynamic> regionMap = regionRaw is Map<String, dynamic>
                  ? regionRaw
                  : (regionRaw is String
                      ? {'city': regionRaw, 'district': ''}
                      : <String, dynamic>{});

              return Card(
                margin: EdgeInsets.all(8),
                child: ProductCard(
                  title: displayTitle,
                  imageUrl: imageUrl,
                  price: (data['price'] ?? '').toString(),
                  region: regionMap,
                  saleStatus: saleStatus,
                  condition: condition,
                  chatCount: (data['chats'] ?? 0) is int ? data['chats'] : 0,
                  likeCount: (data['likes'] ?? 0) is int ? data['likes'] : 0,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: products[index].id,
                          title: displayTitle,
                          price: (data['price'] ?? '').toString(),
                          description: data['description'] ?? '',
                          imageUrl: imageUrl,
                          timestamp: data['timestamp']?.toDate().toString() ?? '',
                          sellerUid: data['sellerUid'] ?? 'unknown',
                          sellerEmail: data['sellerUid'] ?? '',
                          chatRoomId: '',
                          userName: '',
                          productTitle: title,
                          productImageUrl: imageUrl,
                          productPrice: (data['price'] ?? '').toString(),
                          imageUrls: (data['imageUrls'] != null)
                              ? List<String>.from(data['imageUrls'])
                              : [],
                          region: regionMap,
                        ),
                      ),
                    );
                    setState(() {});
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