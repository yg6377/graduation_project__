import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String productId;
  final String price;
  final String? condition;
  final String? saleStatus;
  final List<String>? imageUrls;

  EditScreen({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.productId,
    required this.price,
    this.condition,
    this.saleStatus,
    this.imageUrls,
  });

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _editedTitle;
  String? _editedDescription;
  String? _editedPrice;
  String _selectedCondition = 'S';
  String _selectedSaleStatus = 'available';
  List<String> _imageUrls = [];
  final ImagePicker _picker = ImagePicker();
  Set<String> _uploadingImages = {};

  @override
  void initState() {
    super.initState();
    _editedTitle = widget.title;
    _editedDescription = widget.description;
    _editedPrice = widget.price;
    _selectedCondition = widget.condition ?? 'S';
    _selectedSaleStatus = widget.saleStatus ?? 'available';
    _imageUrls = widget.imageUrls ?? [widget.imageUrl];
  }

  Widget _buildSafeFileImage(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, width: 100, height: 100, fit: BoxFit.cover);
    } else {
      return Image.asset('assets/images/huanhuan_no_image.png', width: 100, height: 100, fit: BoxFit.cover);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _uploadingImages.add(tempId);
        _imageUrls.add(tempId);
      });

      final file = File(pickedFile.path);
      final fileName = 'product_images/$tempId';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      try {
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          final index = _imageUrls.indexOf(tempId);
          if (index != -1) {
            _imageUrls[index] = downloadUrl;
          }
          _uploadingImages.remove(tempId);
        });
      } catch (e) {
        setState(() {
          _imageUrls.remove(tempId);
          _uploadingImages.remove(tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _editedTitle = _editedTitle?.replaceAll(RegExp(r'^\[[A-E]\]\s*'), '');
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'title': _editedTitle,
        'description': _editedDescription,
        'price': _editedPrice,
        'condition': _selectedCondition,
        'saleStatus': _selectedSaleStatus,
        'imageUrl': _imageUrls.isNotEmpty ? _imageUrls.first : '',
        'imageUrls': _imageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product information successfully edited!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateProduct,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Images:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              child: _uploadingImages.contains(_imageUrls[index])
                                  ? Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : _imageUrls[index].startsWith('http')
                                      ? Image.network(_imageUrls[index], width: 100, height: 100, fit: BoxFit.cover)
                                      : _buildSafeFileImage(_imageUrls[index]),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageUrls.removeAt(index);
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Add Image'),
                    ),
                  ),
                ],
              ),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(labelText: 'Condition'),
                items: ['S', 'A', 'B', 'C', 'D'].map((condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text('Condition $condition'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                value: _selectedSaleStatus,
                decoration: InputDecoration(labelText: 'Sale Status'),
                items: ['available', 'reserved', 'sold'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status[0].toUpperCase() + status.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSaleStatus = value!;
                  });
                },
              ),

              TextFormField(
                initialValue: _editedTitle,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _editedTitle = value;
                },
              ),

              TextFormField(
                initialValue: _editedPrice,
                decoration: InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an image URL.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _editedPrice = value;
                },
              ),

              TextFormField(
                initialValue: _editedDescription,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _editedDescription = value;
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
