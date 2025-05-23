// lib/screen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductUploadScreen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'ProductDetailScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'recommendation_service.dart';

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
  bool _showOnlyAvailable = false;
  bool _isLoadingRegion = false;

  @override
  void initState() {
    super.initState();
    _loadUserRegion();
    _checkRegionAfterLogin();
  }

  void _checkRegionAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final region = doc.data()?['region'];
    if (region == null || (region is String && region.trim().isEmpty)) {
      Future.microtask(() {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Verify your region!'),
            content: Text('Please verify your region to continue using the app.'),
            actions: [
              TextButton(
                child: Text('Go'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/changeRegion').then((result) {
                    if (result == true) {
                      _loadUserRegion();
                    }
                  });
                },
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _loadUserRegion() async {
    setState(() => _isLoadingRegion = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingRegion = false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final district = doc.data()?['region']?['district'];

    if (district != null) {
      // " District" 문자열 제거
      final cleaned = district.replaceAll(' District', '').trim();
      setState(() {
        _selectedRegion = cleaned;
        _isLoadingRegion = false;
      });
    } else {
      setState(() => _isLoadingRegion = false);
    }
  }

  Future<void> _changeRegion(String? region) async {
    if (region != null && region != _selectedRegion) {
      setState(() => _selectedRegion = region);
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) _loadUserRegion();
    setState(() => _selectedIndex = index);
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return ''; // we render custom Row
      case 1:
        return 'Chat';
      case 2:
        return 'My Page';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Placeholder; body will be handled below for index 0
      null,
      ChatListScreen(),
      MyPageScreen(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFEAF6FF),
        title: _selectedIndex == 0
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 4),
                _isLoadingRegion
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : Text(
                        _selectedRegion ?? 'Need Verify',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF3B82F6)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Available Only',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 13,
                    ),
                  ),
                  Checkbox(
                    value: _showOnlyAvailable,
                    onChanged: (v) =>
                        setState(() => _showOnlyAvailable = v ?? false),
                    activeColor: Color(0xFF3B82F6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        )
            : Text(_getAppBarTitle()),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF3B82F6)),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: Color(0xFF3B82F6)),
                      onPressed: () => Navigator.pushNamed(context, '/notification'),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
        elevation: 0,
      ),
      body: _selectedIndex == 0
          ? ((_selectedRegion == null || _isLoadingRegion)
              ? Center(child: CircularProgressIndicator())
              : ProductListScreen(
                  region: _selectedRegion,
                  showOnlyAvailable: _showOnlyAvailable,
                ))
          : pages[_selectedIndex],
      bottomNavigationBar: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF3B82F6),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
                builder: (ctx, snap) {
                  int totalUnread = 0;
                  final myUid = FirebaseAuth.instance.currentUser?.uid;
                  if (snap.hasData && myUid != null) {
                    for (var doc in snap.data!.docs) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final raw = data['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
                      final counts = Map<String, int>.from(
                        raw.map((k, v) => MapEntry(k as String, v as int)),
                      );
                      totalUnread += counts[myUid] ?? 0;
                    }
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.chat, size: 24),
                      if (totalUnread > 0)
                        Positioned(
                          right: -5,
                          top: -4,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Center(
                              child: Text(
                                '$totalUnread',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'CHAT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: 'MY PAGE',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF0277BD),
        heroTag: 'uploadProduct',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductUploadScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
