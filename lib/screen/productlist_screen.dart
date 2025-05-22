import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'recommendation_service.dart';

Widget buildProductCard(BuildContext context, DocumentSnapshot doc, Future<void> Function() reloadProducts) {
  final data = doc.data() as Map<String, dynamic>;
  final title = data['title'] ?? '';
  final condition = data['condition'] ?? '';
  final price = data['price'].toString();
  final List<dynamic>? imageUrls = data['imageUrls'];
  final String imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
      ? imageUrls.first.toString()
      : (data['imageUrl'] ?? 'assets/images/huanhuan_no_image.png').toString();
  final Map<String, dynamic> regionMap =
      (data['region'] is Map<String, dynamic>)
          ? data['region'] as Map<String, dynamic>
          : (data['region'] is String)
              ? {'city': data['region'], 'district': ''}
              : {};
  final saleStatus = data['saleStatus'] ?? '';
  final productId = doc.id;
  final description = data['description'] ?? '';
  final sellerEmail = data['sellerEmail'] ?? '';
  final sellerUid = data['sellerUid'] ?? '';
  final timestampValue = data['timestamp'];
  final String timestampString = (timestampValue is Timestamp) ? timestampValue.toDate().toString() : '';
  final int likeCount = (data['likes'] ?? 0) is int ? data['likes'] : 0;
  final int chatCount = (data['chats'] ?? 0) is int ? data['chats'] : 0;

  return ProductCard(
    title: title,
    imageUrl: imageUrl,
    price: price,
    region: regionMap,
    saleStatus: saleStatus,
    condition: condition,
    likeCount: likeCount,
    chatCount: chatCount,
    onTap: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('clickedProducts')
            .doc(productId)
            .set({'clickedAt': Timestamp.now()});
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: productId,
            title: title,
            price: price,
            description: description,
            imageUrl: imageUrl,
            imageUrls: imageUrls?.cast<String>(),
            timestamp: timestampString,
            sellerEmail: sellerEmail,
            chatRoomId: '',
            userName: sellerEmail,
            sellerUid: sellerUid,
            productTitle: title,
            productImageUrl: imageUrl,
            productPrice: price,
            region: regionMap,
          ),
        ),
      );

      await reloadProducts();
    },
  );
}


class ProductCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String price;
  final Map<String, dynamic> region;
  final String saleStatus;
  final String condition;
  final int likeCount;
  final int chatCount;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.region,
    required this.saleStatus,
    required this.condition,
    required this.likeCount,
    required this.chatCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: _buildImage(imageUrl),
            ),
            // 텍스트 내용
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (condition.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConditionColor(condition),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            condition,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                        region.isNotEmpty
                            ? '${region['city'] ?? ''}, ${region['district'] ?? ''}'
                            : '지역 정보 없음',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$price NTD',
                    style: TextStyle(color: Colors.blue, fontSize: 15),
                  ),
                  // Add Row for chat and like counts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('$chatCount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      SizedBox(width: 12),
                      Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('$likeCount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'S':
        return Colors.green;
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.deepOrange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        'assets/images/huanhuan_no_image.png',
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}

class ProductListScreen extends StatefulWidget {
  final String? region;
  final List<DocumentSnapshot>? recommendedProducts;
  final bool showOnlyAvailable;
  const ProductListScreen({Key? key, this.region, this.recommendedProducts, this.showOnlyAvailable = false}) : super(key: key);

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

  Future<void> updateChatCountForProduct(String productId) async {
    final chatRoomSnapshot = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('productId', isEqualTo: productId)
        .get();

    final chatCount = chatRoomSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'chats': chatCount});
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
        final snap = await FirebaseFirestore.instance
            .collection('products')
            .orderBy('updatedAt', descending: true)
            .get();
        // Update chat count for each product
        for (final doc in snap.docs) {
          final productId = doc.id;
          await updateChatCountForProduct(productId);
        }
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userDistrict = userDoc.data()?['region']?['district'];

      if (userDistrict == null) {
        print('❗ 사용자 지역 정보 없음');
        setState(() => _isLoading = false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('region.district', isEqualTo: userDistrict)
          .orderBy('updatedAt', descending: true)
          .get();
      // Update chat count for each product
      for (final doc in snap.docs) {
        final productId = doc.id;
        await updateChatCountForProduct(productId);
      }
      print('📦 $userDistrict 지역 상품 로드 완료: ${snap.docs.length}개');
      setState(() {
        _products = snap.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('🔥 지역 기반 상품 로딩 중 오류 발생: $e');
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

    final showRecommended = widget.recommendedProducts != null && widget.recommendedProducts!.isNotEmpty;

    // Filter recommended products if showOnlyAvailable is true
    final filteredRecommended = showRecommended && widget.showOnlyAvailable
        ? widget.recommendedProducts!.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final saleStatus = data['saleStatus'] ?? '';
            return saleStatus != 'reserved' && saleStatus != 'soldout';
          }).toList()
        : widget.recommendedProducts;

    // Filter _products if showOnlyAvailable is true, and exclude empty or deleted documents
    final filteredProducts = widget.showOnlyAvailable
        ? _products.where((product) {
            if (!product.exists || product.data() == null || (product.data() as Map<String, dynamic>).isEmpty) return false;
            final productData = product.data() as Map<String, dynamic>;
            final saleStatus = productData['saleStatus'] ?? '';
            return saleStatus != 'reserved' && saleStatus != 'soldout';
          }).toList()
        : _products.where((product) {
            return product.exists && product.data() != null && (product.data() as Map<String, dynamic>).isNotEmpty;
          }).toList();

    return Scaffold(
      body: Container(
        color: Color(0xFFEAF6FF),
        child: ListView(
          children: [
            // 추천 알고리즘은 나중에 손 볼 예정
            // if (filteredRecommended != null && filteredRecommended.isNotEmpty) ...[
            //   Padding(
            //     padding: const EdgeInsets.all(12.0),
            //     child: Text('For you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            //   ),
            //   ...filteredRecommended.map((doc) => buildProductCard(context, doc, _loadRegionProducts)).toList(),
            // ],
            ...filteredProducts.map((product) => buildProductCard(context, product, _loadRegionProducts)).toList(),
          ],
        ),
      ),
    );
  }
}
