import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/edit_profile_screen.dart';
import 'package:graduation_project_1/screen/myposts_screen.dart';
import 'package:graduation_project_1/screen/favoritelist_screen.dart';

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
      backgroundColor: Color(0xFFF4F9FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // 프로필 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFB6DBF8).withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 프로필 이미지
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : AssetImage('assets/images/default_profile.png') as ImageProvider,
                        ),
                        SizedBox(width: 16),
                        // 닉네임 수정
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.displayName ?? 'No nickname',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey[900],
                                  fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily,
                                ),
                              ),
                              SizedBox(height: 6),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(_currentUser?.uid).get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text("Your Location: ...", style: TextStyle(fontSize: 14, color: Colors.blueGrey));
                                  }
                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    final region = snapshot.data!.get('region');
                                    return Text("Your Location: $region", style: TextStyle(fontSize: 14, color: Colors.blueGrey));
                                  }
                                  return Text("Your Location: Unknown", style: TextStyle(fontSize: 14, color: Colors.blueGrey));
                                },
                              ),
                              SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      color: Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(8),
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
                                      child: Text(
                                        'Edit Profile',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      color: Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () async {
                                        await FirebaseAuth.instance.signOut();
                                        if (!mounted) return;
                                        Navigator.of(context).pushReplacementNamed('/login');
                                      },
                                      child: Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.blueGrey[900], fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyPostsScreen()),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Color(0xFFB6DBF8), width: 1),
                      ),
                      shadowColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFFB6DBF8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFB6DBF8).withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.list_alt, size: 28, color: Color(0xFF60A5FA)),
                              SizedBox(width: 12),
                              Text(
                                "My Posts",
                                style: TextStyle(fontSize: 16, color: Colors.blueGrey[800], fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FavoriteListScreen()),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Color(0xFFB6DBF8), width: 1),
                      ),
                      shadowColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFFB6DBF8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFB6DBF8).withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.favorite, size: 28, color: Color(0xFF60A5FA)),
                              SizedBox(width: 12),
                              Text(
                                "Favorite List",
                                style: TextStyle(fontSize: 16, color: Colors.blueGrey[800], fontFamily: CupertinoTheme.of(context).textTheme.textStyle.fontFamily),
                              ),
                            ],
                          ),
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
