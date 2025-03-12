import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPageScreen extends StatefulWidget {

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 초기 닉네임 설정
    _nicknameController.text = _currentUser?.displayName ?? 'Enter your name';
  }

  // 닉네임 업데이트
  void _updateNickname() async {
    String newNickname = _nicknameController.text.trim();
    if (newNickname.isNotEmpty) {
      await _currentUser?.updateDisplayName(newNickname);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('changed nickname')),
      );
      setState(() {});
    }
  }

  // 좋아요 목록 가져오기
  Stream<QuerySnapshot> _getLikedProducts() {
    return FirebaseFirestore.instance
        .collection('likedProducts')
        .where('userId', isEqualTo: _currentUser?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // 프로필 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 프로필 이미지
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // 임시 프로필 이미지
                    ),
                  ),
                  SizedBox(width: 16),
                  // 닉네임 수정
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: 'Nickname',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _updateNickname,
                          child: Text('Change nickname'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(thickness: 2),
            // 좋아요 목록 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Like list",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            // 좋아요 누른 상품 리스트
            StreamBuilder<QuerySnapshot>(
              stream: _getLikedProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('There are no posts you have liked.'),
                    ),
                  );
                }

                final likedProducts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // 내부 스크롤 비활성화
                  itemCount: likedProducts.length,
                  itemBuilder: (context, index) {
                    final product = likedProducts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: Row(
                        children: [
                          // 상품 이미지
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  product['imageUrl'] ??
                                      'https://via.placeholder.com/100',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // 상품 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'] ?? '제목 없음',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  product['price'] ?? '가격 정보 없음',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '(내가 좋아요 누른 상품)',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
