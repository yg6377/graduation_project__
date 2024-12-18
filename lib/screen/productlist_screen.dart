import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 홈 화면의 상품 목록 화면
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터
    final List<Map<String, String>> products = [
      {'title': '아이폰 13', 'price': '800,000원', 'image': 'https://via.placeholder.com/150'},
      {'title': '맥북 프로', 'price': '1,500,000원', 'image': 'https://via.placeholder.com/150'},
      {'title': '갤럭시 S21', 'price': '700,000원', 'image': 'https://via.placeholder.com/150'},
      {'title': '에어팟 프로', 'price': '200,000원', 'image': 'https://via.placeholder.com/150'},
    ];

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    products[index]['image']!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                // 제목과 가격
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          products[index]['title']!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          products[index]['price']!,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}