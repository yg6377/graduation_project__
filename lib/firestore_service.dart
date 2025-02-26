import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
