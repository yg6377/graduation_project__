import 'dart:io';
import 'package:flutter/cupertino.dart';
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

  final List<String> _regions = [
    'Taipei', 'New Taipei', 'Danshui', 'Keelung', 'Taoyuan',
    'Hsinchu', 'Taichung', 'Kaohsiung', 'Tainan', 'Hualien'
  ];

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

      if (_selectedRegion != null) {
        final userProducts = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerUid', isEqualTo: _currentUser!.uid)
            .get();

        for (final doc in userProducts.docs) {
          await doc.reference.update({'region': _selectedRegion});
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

  void _showRegionPicker() {
    final initialIndex = _selectedRegion != null ? _regions.indexOf(_selectedRegion!) : 0;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                scrollController: FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedRegion = _regions[index];
                  });
                },
                children: _regions.map((region) => Center(child: Text(region))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Edit Profile'),
      ),
      child: SafeArea(
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
                              : AssetImage('assets/default_avatar.png') as ImageProvider)),
                ),
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Nickname', style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 16)),
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                controller: _nicknameController,
                placeholder: 'Enter new nickname',
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Region', style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 16)),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _showRegionPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedRegion ?? 'Select a region',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedRegion == null
                              ? CupertinoColors.placeholderText
                              : CupertinoColors.label,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              CupertinoButton(
                color: Color(0xFF3B82F6),
                onPressed: _saveProfile,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
