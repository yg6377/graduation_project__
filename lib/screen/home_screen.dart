import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  runApp(MaterialApp(home: HomeScreen()));
}

// 🔹 Firestore Timestamp 변환 함수
String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    DateTime dateTime = timestamp.toDate();
    return timeago.format(dateTime, locale: 'en'); // 🔹 "5분 전" 같은 형식
  } else {
    return "날짜 없음";
  }
}

/// 🔹 홈 화면 (네비게이션 + 상품 목록)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 네비게이션 바 선택 인덱스

  final List<Widget> _pages = [
    ProductListScreen(),  // 홈 화면
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
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
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

/// 🔹 상품 목록 화면 (클릭 시 상세 화면 이동)
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('등록된 상품이 없습니다.'));
        }

        var products = snapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];
            var productData = product.data() as Map<String, dynamic>;

            String title = productData['title'] ?? "제목 없음";
            String price = productData['price']?.toString() ?? "가격 없음";
            String imageUrl = productData['imageUrl'] ?? "";
            String description = productData['description'] ?? "설명 없음";
            Timestamp? timestamp = productData['timestamp'];
            String formattedTimestamp = timestamp != null ? _formatTimestamp(timestamp) : "날짜 없음";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      title: title,
                      price: price,
                      description: description,
                      imageUrl: imageUrl,
                      timestamp: formattedTimestamp,
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Icon(Icons.image, size: 80),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('$price''NTD', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 6),
                            Text(formattedTimestamp, style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 🔹 상품 상세 화면
class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;

  const ProductDetailScreen({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 200, height: 200, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 200),
            ),
            SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('$price원', style: TextStyle(fontSize: 20, color: Colors.blueAccent)),
            SizedBox(height: 8),
            Text('업로드된 시간: $timestamp', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 16),
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}