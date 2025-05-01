import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatlist_screen.dart';
import 'mypage_screen.dart';
import 'productlist_screen.dart';
import 'ProductUploadScreen.dart';
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

  void _onItemTapped(int index) {
    if (index == 0) _loadUserRegion();
    setState(() => _selectedIndex = index);
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Location: ${_selectedRegion ?? "<Select>"}';
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
      ProductListScreen(region: _selectedRegion),
      ChatListScreen(),
      MyPageScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.white,
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
          selectedFontSize: 14,
          unselectedFontSize: 14,
          selectedLabelStyle: TextStyle(fontSize: 14),
          unselectedLabelStyle: TextStyle(fontSize: 14),
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
                          top: -5,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductUploadScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
