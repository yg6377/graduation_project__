import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrlFromDB;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _nicknameController.text = _currentUser!.displayName ?? '';
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    if (_currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          if (data['profileImageUrl'] != null) {
            _profileImageUrlFromDB = data['profileImageUrl'];
          }
          if (data['region'] != null) {
            _selectedRegion = data['region'];
          }
          setState(() {});
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final newNickname = _nicknameController.text.trim();
    String? imageUrl;
    if (_currentUser != null && newNickname.isNotEmpty) {
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${_currentUser!.uid}.jpg');
        await ref.putFile(_profileImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'nickname': newNickname,
        if (imageUrl != null) 'profileImageUrl': imageUrl,
        if (_selectedRegion != null) 'region': _selectedRegion,
      });

      // Update all products by this user
      final userProducts = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerUid', isEqualTo: _currentUser!.uid)
          .get();

      for (final doc in userProducts.docs) {
        await doc.reference.update({'region': _selectedRegion});
      }

      // Update FirebaseAuth user data
      await _currentUser!.updateDisplayName(newNickname);
      if (imageUrl != null) {
        await _currentUser!.updatePhotoURL(imageUrl);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile has been saved.')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_profileImageUrlFromDB != null
                        ? NetworkImage(_profileImageUrlFromDB!)
                        : (_currentUser?.photoURL != null
                            ? NetworkImage(_currentUser!.photoURL!)
                            : AssetImage('assets/default_avatar.png') as ImageProvider)),
              ),
            ),
            SizedBox(height: 16),
            Text('Nickname', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter new nickname',
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              items: [
                'Taipei', 'New Taipei', 'Danshui', 'Keelung', 'Taoyuan',
                'Hsinchu', 'Taichung', 'Kaohsiung', 'Tainan', 'Hualien'
              ].map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
