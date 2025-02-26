import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductUploadScreen extends StatefulWidget {
  @override
  _ProductUploadScreenState createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // 갤러리에서 이미지 선택
  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Firebase Storage에 이미지 업로드 후 URL 가져오기
  Future<String?> uploadImageToStorage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
      FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // 업로드된 이미지 URL 반환
    } catch (e) {
      print("이미지 업로드 실패: $e");
      return null;
    }
  }

  // Firestore에 상품 데이터 추가
  Future<void> uploadProduct() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 필드를 입력하고 이미지를 선택해주세요!")),
      );
      return;
    }

    String? imageUrl = await uploadImageToStorage(_image!);
    if (imageUrl == null) return; // 이미지 업로드 실패 시 종료

    await FirebaseFirestore.instance.collection('product').add({
      'title': _titleController.text,
      'price': _priceController.text,
      'image': imageUrl, // Firestore에 이미지 URL 저장
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("상품이 업로드되었습니다!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("상품 등록")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 이미지 선택 버튼
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _image == null
                    ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 16),
            // 제목 입력
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "상품명"),
            ),
            SizedBox(height: 8),
            // 가격 입력
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: "가격"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            // Firestore 업로드 버튼
            ElevatedButton(
              onPressed: uploadProduct,
              child: Text("상품 등록"),
            ),
          ],
        ),
      ),
    );
  }
}
