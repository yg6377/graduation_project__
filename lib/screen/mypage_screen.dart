import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/edit_profile_screen.dart';

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
    if (newNickname.isNotEmpty && _currentUser != null) {
      await _currentUser!.updateDisplayName(newNickname);

      // Firebase에서도 업데디트할 수 있게 바꿈.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'nickname': newNickname});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('nickname successfully changed!')),
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
                    backgroundImage: _currentUser?.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : NetworkImage('https://via.placeholder.com/150'),
                  ),
                  SizedBox(width: 16),
                  // 닉네임 수정
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.displayName ?? 'No nickname',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditProfileScreen()),
                            );
                            if (result == true) {
                              setState(() {
                                _nicknameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
                              });
                            }
                          },
                          child: Text('Edit Profile'),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushReplacementNamed('/login'); // replace with your actual login route
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Divider(thickness: 2),
            // 내 거래 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: 내가 올린 게시글 리스트 페이지로 이동
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.list_alt, size: 28, color: Colors.blue),
                            SizedBox(width: 12),
                            Text("My Posts", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: 좋아요 누른 게시글 리스트 페이지로 이동
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, size: 28, color: Colors.red),
                            SizedBox(width: 12),
                            Text("Favorite List", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
