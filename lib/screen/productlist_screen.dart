import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'recommendation_service.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String price;
  final String region;
  final String saleStatus;

  const ProductCard({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.region,
    required this.saleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB6DBF8).withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/huanhuan_no_image.png',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          // 텍스트 내용
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    if (saleStatus == 'reserved')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(0xFFDFF0FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Reserved',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    if (saleStatus == 'soldout')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Sold Out',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      region,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '$price NTD',
                  style: TextStyle(color: Colors.blue, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final String? region;
  const ProductListScreen({Key? key, this.region}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<DocumentSnapshot> _products = [];
  bool _isLoading = false; // initState에서 바로 로딩 시작

  @override
  void initState() {
    super.initState();
    _loadRegionProducts();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.region != oldWidget.region) {
      print('📦 지역 변경 감지: ${oldWidget.region} -> ${widget.region}');
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
      print('📦 지역이 선택되지 않음. 전체 상품 로드.');
      setState(() {
        _isLoading = true;
        _products = [];
      });
      try {
        final snap = await FirebaseFirestore.instance.collection('products').get();
        print('📦 전체 상품 로드 완료: ${snap.docs.length}개');
        setState(() {
          _products = snap.docs;
          _isLoading = false;
        });
      } catch (e) {
        print('🔥 전체 상품 로딩 중 오류 발생: $e');
        setState(() => _isLoading = false);
      }
      return;
    }
    print('📦 특정 지역 상품 로딩 시작: $region');
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('region', isEqualTo: region)
          .get();
      print('📦 $region 지역 상품 로드 완료: ${snap.docs.length}개');
      setState(() {
        _products = snap.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('🔥 $region 지역 상품 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  // 점수 기반 추천 상품을 가져오는 함수 (클릭, 좋아요, 검색 히스토리 기반)
  Future<List<DocumentSnapshot>> fetchRecommendedProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentRegion = widget.region;
    if (user == null || currentRegion == null) return [];

    final clickedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clickedProducts')
        .get();

    final likedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('likedProducts')
        .get();

    final searchSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('searchHistory')
        .orderBy('searchedAt', descending: true)
        .limit(5)
        .get();

    final clickedProductIds = clickedSnap.docs.map((d) => d.id).toSet();
    final likedProductIds = likedSnap.docs.map((d) => d.id).toSet();
    final keywords = searchSnap.docs
        .map((d) => d.data()['keyword']?.toString().toLowerCase())
        .whereType<String>()
        .toSet();

    final productsSnap = await FirebaseFirestore.instance
        .collection('products')
        .where('region', isEqualTo: currentRegion)
        .get();

    final scoredProducts = <Map<String, dynamic>>[];

    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final productId = doc.id;
      final title = data['title']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final sellerUid = data['sellerUid'];

      if (sellerUid == user.uid) continue;

      int score = 0;

      if (clickedProductIds.contains(productId)) score += 2;
      if (likedProductIds.contains(productId)) score += 5;

      for (final keyword in keywords) {
        if (title.contains(keyword) || description.contains(keyword)) {
          score += 3;
          break;
        }
      }

      if (score > 0) {
        scoredProducts.add({'doc': doc, 'score': score});
      }
    }

    scoredProducts.sort((a, b) => b['score'].compareTo(a['score']));

    // Print each recommended product with its actual integer score
    for (final item in scoredProducts) {
      final doc = item['doc'] as DocumentSnapshot;
      final score = item['score'] as int;
      final title = doc['title'] ?? '제목 없음';
      print('✅ 추천 상품: $title (점수: $score)');
    }

    final recommended = scoredProducts.map((e) => e['doc'] as DocumentSnapshot).toList();

    print('📊 점수 기반 추천 상품 ${recommended.length}개 로드 완료');
    return recommended;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return Scaffold(
        body: Center(child: Text('There are no products in this location')),
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

          // region 값은 Firestore의 상품 데이터에 들어있는 region 사용
          final String region = productData['region'] ?? 'Unknown';
          final String saleStatus = productData['saleStatus'] ?? '';

          return Stack(
            children: [
              GestureDetector(
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
                child: ProductCard(
                  title: displayTitle,
                  imageUrl: imageUrl,
                  price: price,
                  region: region,
                  saleStatus: saleStatus
                ),
              ),
              Positioned(
                bottom: 20,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
          );
        },
      ),
    );
  }
}