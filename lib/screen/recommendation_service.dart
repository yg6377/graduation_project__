import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List<DocumentSnapshot>> fetchRecommendedProducts(String currentRegion) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || currentRegion.isEmpty) return [];

  final clickedSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('clickedProducts')
      .orderBy('clickedAt', descending: true)
      .limit(5)
      .get();

  final likedSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('likedProducts')
      .orderBy('likedAt', descending: true)
      .limit(3)
      .get();

  final searchSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('searchHistory')
      .orderBy('searchedAt', descending: true)
      .limit(3)
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

  for (final item in scoredProducts) {
    final doc = item['doc'] as DocumentSnapshot;
    final score = item['score'] as int;
    final title = doc['title'] ?? '제목 없음';
    print('✅ 추천 상품: $title (점수: $score)');
  }

  return scoredProducts.map((e) => e['doc'] as DocumentSnapshot).toList();
}