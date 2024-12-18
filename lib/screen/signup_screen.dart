import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // 회원가입 기능
  Future<void> signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Sign up failed'),
      ));
    }
  }

  //test data button
  Future<void> generateTestUser() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Firestore에서 testuser들의 번호를 가져오기
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: 'testuser')
          .where('email', isLessThan: 'testuser\uF8FF') // testuser로 시작하는 이메일만 필터링
          .get();

      int maxNumber = 0;

      // 현재 존재하는 testuser들의 번호 중 가장 큰 번호 찾기
      for (var doc in snapshot.docs) {
        String email = doc['email'];
        RegExp regex = RegExp(r'testuser(\d+)'); // 숫자 추출
        Match? match = regex.firstMatch(email);
        if (match != null) {
          int number = int.parse(match.group(1)!);
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      // 다음 번호부터 시작
      int startNumber = maxNumber + 1;

      // 10개의 테스트 계정 생성
      for (int i = startNumber; i < startNumber + 10; i++) {
        String email = 'testuser$i@example.com';
        String password = 'password${1000 + Random().nextInt(9000)}';
        String nickname = 'TestUser$i';

        try {
          // Firebase Authentication에 사용자 생성
          UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          User? user = userCredential.user;

          if (user != null) {
            // Firestore에 사용자 추가
            await _firestore.collection('users').doc(user.uid).set({
              'email': email,
              'nickname': nickname,
              'region': ['서울', '부산', '대구'][i % 3], // 무작위 지역
              'createdAt': FieldValue.serverTimestamp(),
            });

            print("Success generate TestUser: $email");
          }
        } catch (e) {
          print("Failed generate TestUser: $e");
        }
      }

      print("10 TestUser generated");
    } catch (e) {
      print("테스트 데이터 생성 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUp,
              child: Text('Sign Up'),
            ),
            SizedBox(height: 10),
            // 테스트 데이터 생성 버튼
            ElevatedButton(
              onPressed: generateTestUser,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Generate Test Data'),
            ),
          ],
        ),
      ),
    );
  }
}