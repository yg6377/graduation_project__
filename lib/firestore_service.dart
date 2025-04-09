import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore에서 저장된 상품 목록을 가져오는 함수
  Stream<List<Map<String, dynamic>>> getProducts() {
    return _db.collection('products').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Firestore 문서 ID 추가
        return data;
      }).toList();
    });
  }

  // 데이터 추가 (Create)
  Future<void> addUser(String name, int age, String city) async {
    await _db.collection('users').add({
      'name': name,
      'age': age,
      'city': city,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 데이터 읽기 (Read)
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // 데이터 업데이트 (Update)
  Future<void> updateUser(String docId, int newAge) async {
    await _db.collection('users').doc(docId).update({'age': newAge});
  }

  // 데이터 삭제 (Delete)
  Future<void> deleteUser(String docId) async {
    await _db.collection('users').doc(docId).delete();
  }
}
