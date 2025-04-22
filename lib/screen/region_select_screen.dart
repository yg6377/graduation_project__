import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegionSelectScreen extends StatefulWidget {
  @override
  _RegionSelectScreenState createState() => _RegionSelectScreenState();
}

class _RegionSelectScreenState extends State<RegionSelectScreen> {
  final List<String> _regions = [
    '타이페이', '신베이', '단수이', '지룽', '타오위안',
    '신주', '타이중', '가오슝', '타이난', '화롄'
  ];
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadCurrentRegion();
  }

  Future<void> _loadCurrentRegion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _selectedRegion = doc.data()?['region'];
    });
  }

  Future<void> _saveRegion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedRegion == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'region': _selectedRegion,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('지역이 설정되었습니다: $_selectedRegion')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('지역 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              items: _regions.map((region) {
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
              decoration: InputDecoration(
                labelText: '지역 선택',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRegion,
              child: Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}