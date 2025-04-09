import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';

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
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'uploadProduct',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductUploadScreen()),
                );
              },
              child: Icon(Icons.add),
              tooltip: 'Upload Product',
            ),
          ),
          Positioned(
            bottom: 5,
            right: 80,
            child: FloatingActionButton(
              heroTag: 'generateTestData',
              mini: true,
              backgroundColor: Colors.orange,
              onPressed: () async {
                final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
                final users = usersSnapshot.docs;

                if (users.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No users found to assign as sellers.')),
                  );
                  return;
                }

                final random = Random();
                final sampleTitles = ['Laptop', 'Phone', 'Book', 'Chair', 'Shoes', 'Watch', 'Backpack', 'Keyboard', 'Monitor', 'Jacket'];
                final sampleImages = [
                  'https://picsum.photos/seed/item1/300',
                  'https://picsum.photos/seed/item2/300',
                  'https://picsum.photos/seed/item3/300',
                  'https://picsum.photos/seed/item4/300',
                  'https://picsum.photos/seed/item5/300',
                ];

                for (int i = 0; i < 5; i++) {
                  final randomUser = users[random.nextInt(users.length)].data();
                  final productName = sampleTitles[random.nextInt(sampleTitles.length)];
                  final price = ((random.nextInt(96) + 5) * 100); 

                  await FirebaseFirestore.instance.collection('products').add({
                    'title': productName,
                    'price': '$price NTD',
                    'description': 'This is a sample description.',
                    'imageUrl': sampleImages[random.nextInt(sampleImages.length)],
                    'likes': 0,
                    'timestamp': FieldValue.serverTimestamp(),
                    'sellerEmail': randomUser['email'] ?? 'test@example.com',
                    'sellerUid': users[random.nextInt(users.length)].id,
                    'isTest': true,
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Test products uploaded!')),
                );
              },
              child: Text('Generate Test Data'),
              tooltip: 'Generate Test Products',
            ),
          ),
        ],
      ),
    );
  }
}