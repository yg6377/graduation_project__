import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String sellerUid;
  final String condition;
  final Timestamp timestamp;
  final String region;
  final String saleStatus;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.sellerUid,
    required this.condition,
    required this.timestamp,
    required this.region,
    required this.saleStatus,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      price: data['price'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sellerUid: data['sellerUid'] ?? '',
      condition: data['condition'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      region: data['region'] ?? '',
      saleStatus: data['saleStatus'] ?? 'selling',
    );
  }
}