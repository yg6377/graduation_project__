import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductListScreen extends StatelessWidget {
  final String? region;

  const ProductListScreen({super.key, this.region});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: (region != null)
            ? FirebaseFirestore.instance
                .collection('products')
                .where('region', isEqualTo: region)
                .snapshots()
            : FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productData = product.data() as Map<String, dynamic>;

              final timestampValue = productData['timestamp'];
              final String timestampString = (timestampValue is Timestamp)
                  ? timestampValue.toDate().toString()
                  : '';

              final String productId = productData['productId'] ?? product.id;
              final String title = productData['title'] ?? '';
              final String price = productData['price'] ?? '';
              final String imageUrl = productData['imageUrl'] ?? '';
              final int likes = int.tryParse(productData['likes'].toString()) ?? 0;
              final String description = productData['description'] ?? '';
              final String sellerEmail = productData['sellerEmail'] ?? '';
              final String sellerUid = productData['sellerUid'] ?? '';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Stack(
                    children: [
                      ListTile(
                        leading: SizedBox(
                          width: 80,
                          height: 80,
                          child: Center(
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.asset('assets/images/no_image_pig.png', fit: BoxFit.cover),
                          ),
                        ),
                        title: Text(title, style: TextStyle(fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price, style: TextStyle(fontSize: 16)),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(sellerUid).get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text('Loading user info...', style: TextStyle(fontSize: 12, color: Colors.grey));
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return Text('Unknown user', style: TextStyle(fontSize: 12, color: Colors.grey));
                                }

                                final data = snapshot.data!.data() as Map<String, dynamic>;
                                final nickname = data['nickname'] ?? 'Unknown';
                                final region = data['region'] ?? 'Unknown';

                                final timestamp = productData['timestamp'];
                                String timeDisplay = '';
                                if (timestamp is Timestamp) {
                                  final date = timestamp.toDate();
                                  final now = DateTime.now();
                                  final difference = now.difference(date);

                                  if (difference.inDays > 7) {
                                    timeDisplay = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                  } else {
                                    timeDisplay = timeago.format(date, locale: 'en');
                                  }
                                }
                                return Text('$nickname - $region • $timeDisplay', style: TextStyle(fontSize: 12, color: Colors.grey));
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: productId,
                                title: title,
                                price: price,
                                description: description,
                                imageUrl: imageUrl,
                                timestamp: timestampString,
                                sellerEmail: sellerEmail,
                                chatRoomId: '',
                                userName: sellerEmail,
                                sellerUid: sellerUid,
                                productTitle: title,
                                productImageUrl: imageUrl,
                                productPrice: price,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId)
                                  .collection('likes')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .get(),
                              builder: (context, snapshot) {
                                final isLiked = snapshot.data?.exists ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final docRef = FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(productId)
                                        .collection('likes')
                                        .doc(user?.uid);

                                    final productRef = FirebaseFirestore.instance.collection('products').doc(productId);

                                    final likeDoc = await docRef.get();
                                    final isLiked = likeDoc.exists;

                                    if (isLiked) {
                                      await docRef.delete();
                                      await productRef.update({'likes': FieldValue.increment(-1)});
                                    } else {
                                      await docRef.set({'likedAt': Timestamp.now()});
                                      await productRef.update({'likes': FieldValue.increment(1)});
                                    }
                                  },
                                );
                              },
                            ),
                            Text(
                              '$likes',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
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