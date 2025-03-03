import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 다른 파일들 import
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/screen/chatlist_screen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 네비게이션 바 선택 인덱스

  // ⚠️ 바텀네비게이션 아이템 3개 = _pages도 3개
  final List<Widget> _pages = [
    ProductListScreen(), // index 0 - HOME
    ChatListScreen(),    // index 1 - CHATTING
    MyPageScreen(),      // index 2 - MY PAGE
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 뒤로가기 버튼 감지 및 동작
  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/login');
    return false; // 뒤로가기 액션 취소
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 뒤로가기 감지
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // 기본 뒤로가기 버튼 제거
          title: Row(
            children: [
              // 검색창
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '현재지역(EX.송도동)',
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // 검색 기능
                },
                child: const Text('검색'),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        // 바텀네비게이션으로 선택된 화면을 표시
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'CHATTING',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'MY PAGE',
            ),
          ],
        ),
      ),
    );
  }
}