import 'package:flutter/material.dart';

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

  void _search() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _addRecentSearch(query);
      print("Search executed: $query"); // 🔍 Implement actual search logic here (e.g., Firestore)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjust search bar height
        child: AppBar(
          automaticallyImplyLeading: false, // Remove default back button
          leading: IconButton( // 🔹 Add back button on the left
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