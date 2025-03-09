import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 네비게이션 바 선택 인덱스
  final FirestoreService firestoreService = FirestoreService(); // FirestoreService 인스턴스 생성

  // 네비게이션 탭 화면
  final List<Widget> _pages = [
    ProductListScreen(),  // 홈 화면
    ChatListScreen(),         // 채팅 화면
    MyPageScreen(),       // 마이페이지 화면
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
          title: Text('중고거래 홈'),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Navigator.pushNamed(context, '/search'); //
              },
            ),
            IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          ],
        ),
        body: _pages[_selectedIndex], // 탭에 맞는 화면을 표시

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductUploadScreen()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

// 홈 화면의 상품 목록 화면
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getProducts(), // Firestore에서 상품 목록 가져오기
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // 로딩 화면
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('등록된 상품이 없습니다.'));
        }

        var products = snapshot.data!;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: product['imageUrl'] != null
                    ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.image, size: 50),
                title: Text(product['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${product['price']}원'),
                onTap: () {
                  // 클릭하면 상세 페이지 이동 (추후 추가 가능)
                },
              ),
            );
          },
        );
      },
    );
  }
}
