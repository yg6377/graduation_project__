import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerUid;

  const SellerProfileScreen({required this.sellerUid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF),
      appBar: AppBar(title: Text('Seller Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(sellerUid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nickname = userData['nickname'] ?? '닉네임 없음';
          final profileImageUrl = userData['profileImageUrl'] ?? '';
          final region = userData['region'] ?? '지역 미설정';

          return Column(
            children: [
              SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : AssetImage('assets/images/default_profile.png') as ImageProvider,
              ),
              SizedBox(height: 12),
              Text(nickname, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(region, style: TextStyle(color: Colors.grey)),
                ],
              ),
              SizedBox(height: 20),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('He/She selling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('sellerUid', isEqualTo: sellerUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final products = snapshot.data!.docs;
                    if (products.isEmpty) return Center(child: Text('판매 중인 상품이 없습니다.'));

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index].data() as Map<String, dynamic>;
                        final title = product['title'] ?? '';
                        final imageUrl = product['imageUrl'] ?? '';
                        final price = product['price']?.toString() ?? '';

                        return ListTile(
                          leading: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                              : Container(width: 50, height: 50, color: Colors.grey),
                          title: Text(title),
                          subtitle: Text('$price NTD'),
                        );
                      },
                    );
                  },
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('받은 후기 (미구현)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}