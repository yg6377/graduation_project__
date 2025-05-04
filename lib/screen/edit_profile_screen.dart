import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:graduation_project_1/screen/ChangeRegionScreen.dart';

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
  String? _savedRegion;

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
            if (data['region'] is Map && data['region']['city'] != null && data['region']['district'] != null) {
              _savedRegion = '${data['region']['city']}, ${data['region']['district']}';
            }
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
        if (imageUrl != null) {
          await _currentUser!.updatePhotoURL(imageUrl);
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'nickname': newNickname,
        if (imageUrl != null) 'profileImageUrl': imageUrl,
        // no update to 'region' as it's managed separately
      });

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      final regionData = userDoc.data()?['region'];
      if (regionData is Map<String, dynamic>) {
        final userProducts = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerUid', isEqualTo: _currentUser!.uid)
            .get();

        for (final doc in userProducts.docs) {
          await doc.reference.update({'region': regionData});
        }
      }

      // Update FirebaseAuth user data
      await _currentUser!.updateDisplayName(newNickname);
      if (imageUrl != null) {
        await _currentUser!.updatePhotoURL(imageUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile has been saved.')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              : AssetImage('assets/images/default_profile.png') as ImageProvider)),
                ),
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Nickname', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: 'Enter new nickname',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Region',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _savedRegion ?? 'None',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangeRegionScreen()),
                  );
                },
                child: Text('Change Location'),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveProfile,
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
