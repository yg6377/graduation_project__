import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  // 데이터를 가져오는 Future 함수
  Future<QuerySnapshot> fetchData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return await firestore.collection('users').get();
  }

// (주의) build 메서드는 Widget 안에 들어 있어야 함.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
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
=======
        title: Text('Firestore Test'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: fetchData(), // 위에서 만든 Future 함수를 사용
        builder: (context, snapshot) {
          // 1) 로딩 상태
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2) 에러가 생겼을 때
          if (snapshot.hasError) {
            return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
          }
          // 3) 데이터가 비어있을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          // 4) 정상적으로 데이터를 받았을 때
>>>>>>> d0c51870aed3c3395a8add01c1e4173d6c463ca2
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
<<<<<<< HEAD
              final docData = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(docData['name'] ?? 'No Name'),
=======
              final userData = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(userData['name'] ?? 'No name'),
                subtitle: Text(userData['email'] ?? 'No email'),
>>>>>>> d0c51870aed3c3395a8add01c1e4173d6c463ca2
              );
            },
          );
        },
      ),
    );
  }
}
