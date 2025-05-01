import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'recommendation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.blue),
        titleTextStyle: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
      ),
    ),
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadUserRegion();
  }

  Future<void> _loadUserRegion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    print('🔥 현재 유저 UID: $uid');
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final regionFromUser = doc.data()?['region'];
    print('🔥 Firestore에서 불러온 region: $regionFromUser');
    if (_selectedRegion == null && regionFromUser != null) {
      setState(() {
        _selectedRegion = regionFromUser;
      });
    }
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 0) {
      return 'Current Location: ${_selectedRegion ?? '<Select Region>'}';
    }
    switch (_selectedIndex) {
      case 1:
        return 'Chatting';
      case 2:
        return 'My Page';
      default:
        return 'Home';
    }
  }

  void _onItemTapped(int index) async {
    if (index == 0) {
      await _loadUserRegion();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _changeRegion(String? newRegion) async {
    if (newRegion != null && newRegion != _selectedRegion) {
      setState(() {
        _selectedRegion = newRegion;
      });
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'region': newRegion});
        print('🔥 사용자 지역 업데이트 완료: $newRegion');
      }
      setState(() {}); // Refresh ProductListScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FutureBuilder(
        future: fetchRecommendedProducts(_selectedRegion ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('추천 상품 로딩 실패: ${snapshot.error}'));
          }
          final recommended = snapshot.data ?? [];
          for (final doc in recommended) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '제목 없음';
            print('✅ 추천 상품: $title');
          }
          return ProductListScreen(
            key: ValueKey(_selectedRegion),
            region: _selectedRegion,
          );
        },
      ),
      ChatListScreen(),
      MyPageScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _selectedIndex == 0
            ? GestureDetector(
          onTap: () async {
            final selected = await showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text('Select Region'),
                children: [
                  for (final region in [
                    'Danshui',
                    'Taipei',
                    'New Taipei',
                    'Kaohsiung',
                    'Taichung',
                    'Tainan',
                    'Hualien',
                    'Keelung',
                    'Taoyuan',
                    'Hsinchu',
                  ])
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, region),
                      child: Text(region),
                    ),
                ],
              ),
            );
            if (selected != null) {
              await _changeRegion(selected);
            }
          },
          child: Row(
            children: [
              Text(
                _selectedRegion ?? '<Select Region>',
                style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.blue),
            ],
          ),
        )
            : Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              await Navigator.pushNamed(context, '/search');
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () async {
              await Navigator.pushNamed(context, '/notification');
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedIndex == 0) SizedBox(height: 12),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
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
        heroTag: 'uploadProduct',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductUploadScreen()),
          );
          if (result != null && result == true) {
            setState(() {});
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Upload Product',
      ),
    );
  }
}