import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProductDetailScreen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productData = product.data() as Map<String, dynamic>;


              final timestampValue = productData['timestamp'];
              final String timestampString = (timestampValue is Timestamp)
                  ? timestampValue.toDate().toString()
                  : '';

              final String productId = productData['productId'] ?? product.id;
              final String title = productData['title'] ?? '';
              final String price = productData['price'] ?? '';
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
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        )
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
          );
        },
      ),
    );
  }
}