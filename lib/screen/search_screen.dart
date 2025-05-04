import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'package:graduation_project_1/screen/productlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProductDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = []; // 🔹 Initially empty list
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches_${user!.uid}') ?? [];
      _isLoading = false;
    });
  }

  void _addRecentSearch(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lowerQuery = query.toLowerCase();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList('recentSearches_${user.uid}') ?? [];

    // Remove case-insensitive duplicates
    existing.removeWhere((q) => q.toLowerCase() == lowerQuery);

    // Insert at front
    existing.insert(0, query);

    // Limit to max 10
    if (existing.length > 10) {
      existing = existing.sublist(0, 10);
    }

    await prefs.setStringList('recentSearches_${user.uid}', existing);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('searchHistory')
        .add({
          'keyword': query,
          'searchedAt': Timestamp.now(),
        });

    // Update UI
    setState(() {
      _recentSearches = existing;
    });
  }

  void _search() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    _addRecentSearch(query);

    final allDocs = await FirebaseFirestore.instance.collection('products').get();
    final results = allDocs.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultScreen(results: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjust search bar height
        child: AppBar(
          backgroundColor: Color(0xFFEAF6FF),
          automaticallyImplyLeading: false, // Remove default back button
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // 🔙 Go back to the previous screen
            },
          ),
          title: TextField(
            controller: _searchController,
            autofocus: true, // Automatically focus on search input
            decoration: InputDecoration(
              hintText: 'Enter search keyword...',
              border: InputBorder.none,
            ),
            onSubmitted: (value) => _search(), // Execute search on Enter key
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _search, // Execute search when button is clicked
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(0xFFEAF6FF),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Expanded(
                      child: _recentSearches.isEmpty
                          ? Center(
                              child: Text(
                                'No recent searches.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recentSearches.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_recentSearches[index]),
                                  trailing: IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () async {
                                      setState(() {
                                        _recentSearches.removeAt(index);
                                      });
                                      final user = FirebaseAuth.instance.currentUser;
                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      prefs.setStringList('recentSearches_${user!.uid}', _recentSearches);
                                    },
                                  ),
                                  onTap: () {
                                    _searchController.text = _recentSearches[index];
                                    _search();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class SearchResultScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> results;

  const SearchResultScreen({required this.results, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        backgroundColor: Color(0xFFEAF6FF),
      ),
      body: Container(
        color: Color(0xFFEAF6FF),
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            final productData = product.data() as Map<String, dynamic>;
            final Map<String, dynamic> regionMap = productData['region'] is Map<String, dynamic> ? productData['region'] as Map<String, dynamic> : {};
            final String title = productData['title'] ?? '';
            final List<String> imageUrls = List<String>.from(productData['imageUrls'] ?? []);
            final String imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
            final String price = productData['price']?.toString() ?? '';
            // region is now a Map<String, dynamic>
            final String saleStatus = productData['saleStatus'] ?? '';
            final int likeCount = (productData['likes'] ?? 0) is int ? productData['likes'] : 0;
            final int chatCount = (productData['chats'] ?? 0) is int ? productData['chats'] : 0;

            return ProductCard(
              title: title,
              imageUrl: imageUrl,
              price: price,
              region: regionMap,
              saleStatus: saleStatus,
              condition: '',
              likeCount: likeCount,
              chatCount: chatCount,
              onTap: () {
                final timestampValue = productData['timestamp'];
                final String timestampString = (timestampValue is Timestamp)
                    ? timestampValue.toDate().toString()
                    : '';

                final String productId = productData['productId'] ?? product.id;
                final String description = productData['description'] ?? '';
                final String sellerEmail = productData['sellerEmail'] ?? '';
                final String condition = productData['condition'] ?? '';
                final String sellerUid = productData['sellerUid'] ?? '';

                print('🟢 Product clicked: $title / $productId / $sellerUid');

                if (productId.isEmpty || title.isEmpty || sellerUid.isEmpty) {
                  print('⚠️ 필수 데이터 누락. 이동 중단.');
                  return;
                }

                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: productId,
                        title: title,
                        price: price,
                        description: description,
                        imageUrl: imageUrl,
                        timestamp: timestampString,
                        sellerEmail: sellerEmail,
                        chatRoomId: '',
                        userName: sellerEmail,
                        sellerUid: sellerUid,
                        productTitle: title,
                        productImageUrl: imageUrl,
                        productPrice: price,
                        region: regionMap,
                        imageUrls: List<String>.from(productData['imageUrls'] ?? []),
                      ),
                    ),
                  );
                } catch (e) {
                  print('❌ Navigator.push failed: $e');
                }
              },
            );
          },
        ),
      ),
    );
  }
}