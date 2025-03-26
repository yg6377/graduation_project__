import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chatroom_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;

  final String sellerEmail;
  final String productId;

  const ProductDetailScreen({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    required this.sellerEmail,
    required this.productId,
    super.key,
  });

  // 🔹 채팅방 ID 생성 또는 불러오기
  Future<String> _createOrGetChatRoom(String myEmail, String otherEmail) async {
    List<String> emails = [myEmail, otherEmail];
    emails.sort();
    final combinedId = emails.join('_');

    final docRef = FirebaseFirestore.instance.collection('chats').doc(combinedId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'participants': [myEmail, otherEmail],
        'lastMessage': '',
        'lastTime': FieldValue.serverTimestamp(),
      });
    }

    return combinedId;
  }

  @override
  Widget build(BuildContext context) {
    final String? myEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: Text(title)),

      // 🔹 상품 상세 내용
      body: SingleChildScrollView(
        child: Padding(
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
              Text(
                title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // 🔹 가격
              Text(
                '$price',
                style: TextStyle(fontSize: 20, color: Colors.blueAccent),
              ),
              SizedBox(height: 8),

              // 🔹 업로드 시간
              Text(
                'Uploaded by : $timestamp',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),

              // 🔹 상품 설명
              Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 100), // 하단 버튼과 겹치지 않게 여유 공간
            ],
          ),
        ),
      ),

      // 🔹 하단 고정 채팅하기 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: () async {
                if (myEmail == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인이 필요합니다.')),
                  );
                  return;
                }

                // 🔹 채팅방 생성 또는 이동
                final chatRoomId = await _createOrGetChatRoom(myEmail, sellerEmail);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      chatRoomId: chatRoomId,
                      userName: sellerEmail,
                      productTitle: title,
                      productImageUrl: imageUrl,
                      productPrice: price,
                    ),
                  ),
                );
              },
              child: Text('채팅하기'),
            ),
          ),
        ),
      ),
    );
  }
}
/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chatroom_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;

  final String sellerEmail;
  final String productId;

  const ProductDetailScreen({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,

    required this.sellerEmail,
    required this.productId,
    super.key,
  });




  @override
  Widget build(BuildContext context) {
    print("ProductDetailScreen build() called"); // 디버그용
    final String? myEmail = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      appBar: AppBar(title: Text(title)),


      body: SingleChildScrollView(
       child: Padding(
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
            SizedBox(height: 8),

            // 🔹 상품 설명
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10)

          ]
        ),
       ),
      ),
    );
  }
}*/
