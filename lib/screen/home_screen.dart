import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart'; // Show 구문 제거
import 'ProductDetailScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: HomeScreen()));
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
      setState(() {}); // To refresh ProductListScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductListScreen(
        key: ValueKey(_selectedRegion),
        region: _selectedRegion,
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
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Danshui'),
                    child: Text('Danshui'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Taipei'),
                    child: Text('Taipei'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'New Taipei'),
                    child: Text('New Taipei'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Kaohsiung'),
                    child: Text('Kaohsiung'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Taichung'),
                    child: Text('Taichung'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Tainan'),
                    child: Text('Tainan'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Hualien'),
                    child: Text('Hualien'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Keelung'),
                    child: Text('Keelung'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Taoyuan'),
                    child: Text('Taoyuan'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, 'Hsinchu'),
                    child: Text('Hsinchu'),
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
          if (_selectedIndex == 0)
            SizedBox(height: 12),
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
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'uploadProduct',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductUploadScreen()),
                );
                // ProductUploadScreen에서 상품 업로드 후 HomeScreen으로 돌아올 때,
                // 현재 지역의 상품 목록을 다시 로드하기 위해 setState를 호출합니다.
                if (result != null && result == true) {
                  // result가 true이면 상품 업로드가 완료되었음을 의미합니다.
                  setState(() {});
                }
              },
              child: Icon(Icons.add),
              tooltip: 'Upload Product',
            ),
          ),
        ],
      ),
    );
  }
}