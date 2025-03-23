import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // 숫자 입력 제한

class ProductUploadScreen extends StatefulWidget {
  @override
  _ProductUploadScreenState createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCondition = 'New';
  File? _image;
  final ImagePicker _picker = ImagePicker();

  /// 이미지 선택 함수
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// 상품 업로드 함수 (좋아요 필드 포함)
  Future<void> _uploadProduct() async {
    try {
      String title = titleController.text.isEmpty ? "No title" : titleController.text;
      String price = priceController.text.isEmpty ? "Price unknown" : "${priceController.text} NTD";
      String description = descriptionController.text.isEmpty ? "No description" : descriptionController.text;
      String imageUrl = "";

      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('products').add({
        'title': title,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'likes': 0, // 🔹 좋아요 초기값 추가
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error uploading product: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Upload')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _image == null
                    ? Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, size: 40, color: Colors.black54),
                )
                    : Image.file(_image!, width: 100, height: 100),
              ),
              SizedBox(height: 10),
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Product Name')),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price (Numbers only)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _uploadProduct, child: Text('Upload')),
            ],
          ),
        ),
      ),
    );
  }
}