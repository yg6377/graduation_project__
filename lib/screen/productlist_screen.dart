import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'home_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? region;
  const ProductListScreen({Key? key, this.region}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<DocumentSnapshot> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegionProducts();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.region != oldWidget.region) {
      setState(() {
        _isLoading = true;
        _products = [];
      });
      _loadRegionProducts();
    }
  }

  Future<void> _loadRegionProducts() async {
    final region = widget.region;
    if (region == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      print('📦 지역 기반 상품 로딩 시작: ${widget.region}');
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('region', isEqualTo: region)
          .get();
      print('📦 로드된 상품 개수: ${snap.docs.length}');
      for (var doc in snap.docs) {
        final data = doc.data();
        print(' - ${doc.id}: ${data['title']} [${data['region']}]');
      }
      setState(() {
        _products = snap.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('🔥 상품 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final productData = product.data() as Map<String, dynamic>;

          final timestampValue = productData['timestamp'];
          final String timestampString = (timestampValue is Timestamp)
              ? timestampValue.toDate().toString()
              : '';

          final String productId = productData['productId'] ?? product.id;
          final String title = productData['title'] ?? '';
          final String condition = productData['condition'] ?? '';
          final String price = productData['price'].toString();
          final String imageUrl = productData['imageUrl'] ?? '';
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
                            : Image.asset('assets/images/no image.png', fit: BoxFit.cover),
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
                    onTap: () async {
                      await Navigator.push(
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
                      setState(() {});
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FutureBuilder: 로그인한 사용자가 이 상품을 좋아요 눌렀는지 확인 (users/{uid}/likedProducts/{productId})
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                          future: (() {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null);
                            return FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('likedProducts')
                                .doc(productId)
                                .get();
                          })(),
                          builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>?> snapshot) {
                            final isLiked = snapshot.hasData && snapshot.data != null && snapshot.data?.exists == true;
                            return IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                print('🛠️ [ListScreen] 좋아요 토글 시작: $productId');
                                final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
                                final likeUserRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('likedProducts')
                                    .doc(productId);
                                final likeProductRef = FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(productId)
                                    .collection('likes')
                                    .doc(user.uid);
                                final likeUserDoc = await likeUserRef.get();
                                final alreadyLiked = likeUserDoc.exists;
                                print('🛠️ [ListScreen] 이전 좋아요 상태: $alreadyLiked');
                                if (alreadyLiked) {
                                  // Unlike: Remove from both user and product collections, decrement counter
                                  await likeUserRef.delete();
                                  await likeProductRef.delete();
                                  await productRef.update({'likes': FieldValue.increment(-1)});
                                } else {
                                  // Like: Add to both user and product collections, increment counter
                                  await likeUserRef.set({
                                    'productId': productId,
                                    'likedAt': Timestamp.now(),
                                  });
                                  await likeProductRef.set({'likedAt': Timestamp.now()});
                                  await productRef.update({'likes': FieldValue.increment(1)});
                                }
                                print('🛠️ [ListScreen] Firestore 좋아요 상태 변경 완료 for $productId');
                                setState(() {});
                              },
                            );
                          },
                        ),
                        // 좋아요 수 텍스트 표시 (실시간 반영)
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .snapshots(),
                          builder: (context, snapLikes) {
                            int likeCount = 0;
                            if (snapLikes.hasData && snapLikes.data!.exists) {
                              final data = snapLikes.data!.data();
                              likeCount = data?['likes'] is int ? data!['likes'] as int : 0;
                            }
                            return Text(
                              '$likeCount',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}