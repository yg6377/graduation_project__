import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  final List<String> _regions = [
    'Danshui', 'Taipei', 'New Taipei', 'Kaohsiung', 'Taichung',
    'Tainan', 'Hualien', 'Keelung', 'Taoyuan', 'Hsinchu',
  ];
  String? _selectedRegion;

  // 회원가입 기능
  Future<void> signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Error'),
          content: Text('Passwords do not match'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
      return;
    }
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': _emailController.text,
        'nickname': 'User${Random().nextInt(100000)}',
        'region': _regionController.text,
        'userId': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
    } on FirebaseAuthException catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Sign Up Failed'),
          content: Text(e.message ?? 'Sign up failed'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFFEAF6FF),
      navigationBar: CupertinoNavigationBar(
        middle: Text('Sign Up'),
        backgroundColor: Color(0xFFEAF6FF),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                placeholderStyle: TextStyle(color: CupertinoColors.activeBlue),
                keyboardType: TextInputType.emailAddress,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                placeholderStyle: TextStyle(color: CupertinoColors.activeBlue),
                obscureText: true,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: _confirmPasswordController,
                placeholder: 'Confirm Password',
                placeholderStyle: TextStyle(color: CupertinoColors.activeBlue),
                obscureText: true,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showRegionPicker(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedRegion ?? 'Select Region',
                    style: TextStyle(
                      color: _selectedRegion == null
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: signUp,
                borderRadius: BorderRadius.circular(8),
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showRegionPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Select Region'),
        actions: _regions.map((region) {
          return CupertinoActionSheetAction(
            child: Text(region),
            onPressed: () {
              setState(() {
                _selectedRegion = region;
                _regionController.text = region;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ),
    );
  }
}