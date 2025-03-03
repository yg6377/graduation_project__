import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void fetchData() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var snapshot = await firestore.collection('users').get();
  for (var doc in snapshot.docs) {
    print(doc.data());
  }
}

// (주의) build 메서드는 Widget 안에 들어 있어야 함.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, snapshot) {
          // 로딩 상태 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          // 데이터가 있을 때
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docData = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(docData['name'] ?? 'No Name'),
              );
            },
          );
        },
      ),
    );
  }
}