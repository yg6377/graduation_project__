import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 숫자 입력만 가능하게 하기 위해 추가
import 'package:flutter/services.dart';

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

  /// 이미지를 갤러리에서 선택하는 함수
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// 상품 업로드 함수
  Future<void> _uploadProduct() async {
    try {
      // 입력값이 없으면 기본값으로 설정
      String title = titleController.text.isEmpty ? "제목 없음" : titleController.text;
      // 가격이 입력되지 않았다면 "가격 미정", 입력되었다면 "123 NTD" 형태로 저장
      String price = priceController.text.isEmpty
          ? "가격 미정"
          : "${priceController.text} NTD";
      String description = descriptionController.text.isEmpty ? "설명 없음" : descriptionController.text;

      String imageUrl = ""; // 기본값 (이미지 없을 시 빈 문자열)

      // 이미지를 선택했다면 Firebase Storage에 업로드
      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Firestore에 문서 추가 (이미지가 없으면 imageUrl은 빈 문자열)
      await FirebaseFirestore.instance.collection('products').add({
        'title': title,
        'price': price,
        'description': description,
        'condition': selectedCondition,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 업로드 완료 후 이전 화면(홈 화면 등)으로 복귀
      Navigator.pop(context);
    } catch (e) {
      print("Error uploading product: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('상품 등록'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 사진 업로드 버튼
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

              // 상품명 입력
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: '상품명'),
              ),

              // 가격 입력 (숫자 전용, 화폐 단위 NTD 자동으로 붙음)
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: '가격 (숫자만 입력)'),
                keyboardType: TextInputType.number,
                // 숫자만 입력 가능하도록 제한
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              // 상품 설명 입력
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: '설명'),
              ),

              // 상품 상태 선택 (드롭다운)
              DropdownButton<String>(
                value: selectedCondition,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCondition = newValue!;
                  });
                },
                items: ['새 제품', '중고 - 상', '중고 - 중', '중고 - 하']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // 업로드 버튼
              ElevatedButton(
                onPressed: _uploadProduct,
                child: Text('업로드'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
