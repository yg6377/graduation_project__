import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Number input restriction

class ProductUploadScreen extends StatefulWidget {
  @override
  _ProductUploadScreenState createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  String selectedCondition = 'S'; // Default value: Unopened

  /// Image selection function
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Product upload function (Add productId field to Firestore)
  Future<void> _uploadProduct() async {
    try {
      // Handle default values for title, price, description
      final user = FirebaseAuth.instance.currentUser; // Save seller UID
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final String region = userDoc.data()?['region'] ?? 'Unknown';

      String title = titleController.text.isEmpty ? "No title" : titleController.text;
      String price = priceController.text.isEmpty ? "Price unknown" : "${priceController.text} ";
      String description = descriptionController.text.isEmpty ? "No description" : descriptionController.text;

      // Upload image
      String imageUrl = "";
      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Create new document in Firestore
      final docRef = await FirebaseFirestore.instance.collection('products').add({
        'title': title,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'likes': 0, // Initial likes value
        'timestamp': FieldValue.serverTimestamp(),

        'sellerUid': user?.uid,
        //'sellerEmail': uploaderEmail, // Save seller UID
        'condition': selectedCondition,
        'region': region, // newly added
        'saleStatus': 'selling', // Added: default to "selling"
      });

      // Update document ID as 'productId' field (Store Firestore document ID)
      await docRef.update({
        'productId': docRef.id,
      });

      // Navigate back after upload
      Navigator.pop(context);

    } catch (e) {
      print("Error uploading product: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Product')),
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
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price (Numbers Only)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: InputDecoration(labelText: 'Condition'),
                items: [
                  DropdownMenuItem(value: 'S', child: Text('S (Unopened)')),
                  DropdownMenuItem(value: 'A', child: Text('A (Almost New)')),
                  DropdownMenuItem(value: 'B', child: Text('B (Slightly Used)')),
                  DropdownMenuItem(value: 'C', child: Text('C (Heavily Used)')),
                  DropdownMenuItem(value: 'D', child: Text('D (Broken or Defective)')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCondition = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadProduct,
                child: Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}