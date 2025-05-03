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

  @override
  void initState() {
    super.initState();
    _loadUserRegion();
  }

  Future<void> _loadUserRegion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() => _selectedRegion = doc.data()?['region']);
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
      ProductListScreen(
        region: _selectedRegion,
        showOnlyAvailable: _showOnlyAvailable,
      ),
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
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: Text('Select Region'),
                      children: [
                        for (final r in [
                          'Danshui', 'Taipei', 'New Taipei',
                          'Kaohsiung', 'Taichung', 'Tainan',
                          'Hualien', 'Keelung', 'Taoyuan', 'Hsinchu',
                        ])
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, r),
                            child: Text(r),
                          ),
                      ],
                    ),
                  );
                  await _changeRegion(selected);
                },
                child: Row(
                  children: [
                    Text(
                      _selectedRegion ?? '<None>',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),
            Text('Available Only',
                style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 17 )
            ),

            Checkbox(
              value: _showOnlyAvailable,
              onChanged: (v) =>
                  setState(() => _showOnlyAvailable = v ?? false),
              activeColor: Color(0xFF3B82F6),
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
            IconButton(
              icon: Icon(Icons.map, color: Color(0xFF3B82F6)),
              onPressed: () => Navigator.pushNamed(context, '/maptest'),
            ),
          ],
        ],
        elevation: 0,
      ),
      body: pages[_selectedIndex],
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
