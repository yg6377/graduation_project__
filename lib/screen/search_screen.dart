import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ProductDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = []; // 🔹 Initially empty list

  void _addRecentSearch(String query) {
    setState(() {
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
      }
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
      body: Padding(
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
                      onPressed: () {
                        setState(() {
                          _recentSearches.removeAt(index);
                        });
                      },
                    ),
                    onTap: () {
                      _searchController.text = _recentSearches[index];
                      _search(); // Execute search with selected keyword
                    },
                  );
                },
              ),
            ),
          ],
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
      appBar: AppBar(title: Text('Results')),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final product = results[index];
          final productData = product.data() as Map<String, dynamic>;

          final timestampValue = productData['timestamp'];
          final String timestampString = (timestampValue is Timestamp)
              ? timestampValue.toDate().toString()
              : '';

          final String productId = productData['productId'] ?? product.id;
          final String title = productData['title'] ?? '';
          final String price = productData['price']?.toString() ?? '';
          final String imageUrl = productData['imageUrl'] ?? '';
          final String description = productData['description'] ?? '';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: ListTile(
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Image.asset('assets/images/no_image_pig.png', fit: BoxFit.cover),
                  ),
                ),
                title: Text(title, style: TextStyle(fontSize: 18)),
                subtitle: Text(price, style: TextStyle(fontSize: 16)),
                onTap: () {
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
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}