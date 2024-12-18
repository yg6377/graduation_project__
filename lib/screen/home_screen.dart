import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_screen.dart'; // 게시글 작성 화면 import
import 'package:graduation_project_1/screen/chatroom_screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';      // MyPageScreen 정의
import 'package:graduation_project_1/screen/chatlist_screen.dart';         // ChatScreen 정의
import 'package:graduation_project_1/screen/mypage_screen.dart';       // MyPageScreen 정의
import 'package:graduation_project_1/screen/post_screen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 네비게이션 바 선택 인덱스

  // 네비게이션 탭 화면
  final List<Widget> _pages = [
    ProductListScreen(), // 홈 화면
    ChatlistScreen(), // 채팅방 리스트
    MyPageScreen(), // 마이페이지 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 뒤로가기 버튼 감지 및 동작
  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
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
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // 검색 기능 구현
                },
                child: Text('검색'),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // 로그아웃
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CHATTING'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'MY PAGE'),
          ],
        ),
        // 우측 하단 게시글 등록 버튼
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostScreen()),
            );
          },
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white), // 플러스 아이콘
          tooltip: '게시글 작성',
        ),
      ),
    );
  }
}

