/*
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class PostScreen extends StatefulWidget {
  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); // 가격 입력 필드
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = []; // 선택된 이미지 리스트
  final ImagePicker _picker = ImagePicker();

  // 이미지 선택 함수 (최대 5장 제한)
  Future<void> pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 5장까지 업로드 가능합니다.')),
      );
      return;
    }

    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        int remaining = 5 - _selectedImages.length;
        _selectedImages.addAll(
          images.take(remaining).map((img) => File(img.path)).toList(),
        );
      });
    }
  }

  // 게시글 및 이미지 업로드 함수
  Future<void> uploadPost() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목, 가격, 내용을 모두 입력해주세요.')),
      );
      return;
    }

    try {
      List<String> imageUrls = [];

      // 이미지 Firebase Storage에 업로드
      for (File image in _selectedImages) {
        String fileName =
            'posts/${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
        UploadTask uploadTask =
        FirebaseStorage.instance.ref().child(fileName).putFile(image);

        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Firestore에 게시글 데이터 저장
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text,
        'price': _priceController.text, // 가격 저장
        'content': _contentController.text,
        'images': imageUrls,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('게시글이 성공적으로 업로드되었습니다!'),
      ));

      // 업로드 후 초기화
      _titleController.clear();
      _priceController.clear();
      _contentController.clear();
      setState(() {
        _selectedImages.clear();
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('업로드 중 오류가 발생했습니다.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("게시글 작성")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '제목'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: '가격'),
                keyboardType: TextInputType.number, // 숫자 키패드 설정
              ),
              SizedBox(height: 10),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: '내용'),
                maxLines: 4,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickImages,
                child: Text("이미지 선택 (최대 5장)"),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages
                    .map((image) => Image.file(image, width: 100, height: 100))
                    .toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadPost,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("게시하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

 */