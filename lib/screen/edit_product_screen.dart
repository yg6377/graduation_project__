import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String productId;
  final String price;

  EditScreen({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.productId,
    required this.price,
  });

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _editedTitle;
  String? _editedDescription;
  String? _editedPrice;

  @override
  void initState() {
    super.initState();
    _editedTitle = widget.title;
    _editedDescription = widget.description;
    _editedPrice = widget.price;
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'title': _editedTitle,
        'description': _editedDescription,
        'price': _editedPrice,
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
