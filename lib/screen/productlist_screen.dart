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
              final String condition = productData['condition'] ?? '';
              final String price = productData['price'] ?? '';
              final String imageUrl = productData['imageUrl'] ?? '';
              final int likes = int.tryParse(productData['likes'].toString()) ?? 0;
              final String description = productData['description'] ?? '';
              final String sellerEmail = productData['sellerEmail'] ?? '';
              final String sellerUid = productData['sellerUid'] ?? '';
              final String displayTitle = condition.isNotEmpty ? '[$condition] $title' : title;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Stack(
                    children: [
                      ListTile(
                        leading: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.asset('assets/images/sad image.png', fit: BoxFit.cover),
                          ),
                        ),
                        title: Text(
                          displayTitle,
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$price NTD', style: TextStyle(fontSize: 16)),
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
                                title: displayTitle,
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
                            // FutureBuilder: 로그인한 사용자가 이 상품을 좋아요 눌렀는지 확인
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId) // 현재 상품 문서 ID
                                  .collection('likes')
                                  .doc(FirebaseAuth.instance.currentUser?.uid) // 현재 로그인한 유저의 좋아요 여부
                                  .get(),
                              builder: (context, snapshot) {
                                final isLiked = snapshot.data?.exists ?? false; // 좋아요 문서가 있으면 이미 좋아요 누른 상태
                                return IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border, // 상태에 따라 하트 아이콘 변경
                                    color: isLiked ? Colors.red : Colors.grey, // 색상도 변경
                                  ),
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final docRef = FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(productId)
                                        .collection('likes')
                                        .doc(user?.uid); // 좋아요 문서 참조

                                    final productRef = FirebaseFirestore.instance.collection('products').doc(productId); // 상품 문서 참조

                                    final likeDoc = await docRef.get(); // 문서 존재 여부 확인
                                    final isLiked = likeDoc.exists;

                                    if (isLiked) {
                                      // 이미 좋아요를 눌렀으면 → 좋아요 취소
                                      await docRef.delete(); // 좋아요 문서 삭제
                                      await productRef.update({'likes': FieldValue.increment(-1)}); // 상품 좋아요 수 -1
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user?.uid)
                                          .collection('likedProducts')
                                          .doc(productId)
                                          .delete();
                                    } else {
                                      // 좋아요를 안 눌렀으면 → 좋아요 추가
                                      await docRef.set({'likedAt': Timestamp.now()}); // 문서 생성
                                      await productRef.update({'likes': FieldValue.increment(1)}); // 상품 좋아요 수 +1
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user?.uid)
                                          .collection('likedProducts')
                                          .doc(productId)
                                          .set({
                                            'productId': productId,
                                            'likedAt': Timestamp.now(),
                                          });
                                    }
                                  },
                                );
                              },
                            ),
                            // 좋아요 수 텍스트 표시
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