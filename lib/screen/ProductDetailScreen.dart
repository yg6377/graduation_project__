import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;

  const ProductDetailScreen({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 상품 이미지
            Center(
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 200, height: 200, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 200),
            ),
            SizedBox(height: 16),

            // 🔹 상품명
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            // 🔹 가격
            Text('$price', style: TextStyle(fontSize: 20, color: Colors.blueAccent)),
            SizedBox(height: 8),

            // 🔹 업로드 시간
            Text('Uploaded by : $timestamp', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 16),

            // 🔹 상품 설명
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}