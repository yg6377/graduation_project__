import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:graduation_project_1/screen/ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';

void main() {
  runApp(MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 🔹 탭마다 보여줄 페이지들
  final List<Widget> _pages = [
    ProductListScreen(),  // 홈 화면 (상품 목록)
    ChatListScreen(),     // 채팅 화면
    MyPageScreen(),       // 마이페이지 화면
  ];

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Chatting';
      case 2:
        return 'My Page';
      default:
        return 'Home';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notification');
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 상품 업로드 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductUploadScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}