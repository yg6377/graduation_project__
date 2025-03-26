import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateAllPrices() async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final price = data['price'];

    if (price is int || !price.toString().contains('NTD')) {
      await doc.reference.update({
        'price': '${price.toString()} NTD',
      });
    }
  }

  print("✅ 가격 업데이트 완료!");
}