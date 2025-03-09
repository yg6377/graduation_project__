import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProductUploadScreen extends StatefulWidget {
  @override
  _ProductUploadScreenState createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCondition = '새 제품';
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (_image == null || titleController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하고 이미지를 선택하세요!')),
      );
      return;
    }

    try {
      // Firebase Storage에 이미지 업로드
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Firestore에 데이터 저장
      await FirebaseFirestore.instance.collection('products').add({
        'title': titleController.text,
        'price': priceController.text,
        'description': descriptionController.text,
        'condition': selectedCondition,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 업로드 완료 후 홈 화면으로 이동
      Navigator.pop(context);
    } catch (e) {
      print("Error uploading product: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('상품 등록')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 40),
              )
                  : Image.file(_image!, width: 100, height: 100),
            ),
            TextField(controller: titleController, decoration: InputDecoration(labelText: '상품명')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: '가격'), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: '설명')),
            DropdownButton<String>(
              value: selectedCondition,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCondition = newValue!;
                });
              },
              items: ['새 제품', '중고 - 상', '중고 - 중', '중고 - 하'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadProduct,
              child: Text('업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
