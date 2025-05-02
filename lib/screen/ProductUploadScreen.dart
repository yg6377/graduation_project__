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

  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  String selectedCondition = 'S'; // Default value: Unopened

  bool _isUploading = false;

  /// Image selection function
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && _images.length < 10) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  /// Product upload function (Add productId field to Firestore)
  Future<void> _uploadProduct() async {
    setState(() {
      _isUploading = true;
    });
    try {
      // Handle default values for title, price, description
      final user = FirebaseAuth.instance.currentUser; // Save seller UID
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final String region = (userDoc.data()?['region'] ?? 'Unknown').toString().trim();

      String title = titleController.text.isEmpty ? "No title" : titleController.text;
      String price = priceController.text.isEmpty ? "Price unknown" : "${priceController.text} ";
      String description = descriptionController.text.isEmpty ? "No description" : descriptionController.text;

      // Upload images
      List<String> imageUrls = [];
      for (final image in _images) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Create new document in Firestore
      final docRef = await FirebaseFirestore.instance.collection('products').add({
        'title': title,
        'price': price,
        'description': description,
        'imageUrls': imageUrls,
        'likes': 0, // Initial likes value
        'timestamp': FieldValue.serverTimestamp(),
        'sellerUid': user?.uid,
        'condition': selectedCondition,
        'region': region, // newly added
        'saleStatus': 'selling', // Added: default to "selling"
      });

      // Update document ID as 'productId' field (Store Firestore document ID)
      await docRef.update({
        'productId': docRef.id,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('clickedProducts')
          .doc(docRef.id)
          .set({
        'productId': docRef.id,
        'clickedAt': null,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('likedProducts')
          .doc(docRef.id)
          .set({
        'productId': docRef.id,
        'likedAt': null,
      });

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload successful')));
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Item')),
      body: Container(
        color: Colors.blue[50],
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upload Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('${_images.length}/10', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _images.length) {
                        return GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.add_a_photo, size: 40, color: Colors.black54),
                          ),
                        );
                      } else {
                        return Container(
                          width: 100,
                          margin: EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_images[index], fit: BoxFit.cover),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            hintText: 'Enter title',
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            prefixText: 'NT\$ ',
                            hintText: 'Enter price',
                          ),
                        ),

                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCondition,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            labelText: 'Item Condition',
                          ),
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

                        const SizedBox(height: 24),
                        Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            hintText: 'Detailed Description',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadProduct,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(double.infinity, 52),
                    ),
                    child: _isUploading
                        ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}