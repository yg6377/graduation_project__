import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); //22

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Login failed'),
      ));
    }
  }

  /// 자동 로그인 (이전에 로그인한 계정 사용)
  Future<void> autoLogin() async {
    final user = FirebaseAuth.instance.currentUser; //
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자동 로그인 불가능. 먼저 로그인하세요!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('Login btn'),
            ),


            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text('Sign Up'),
            ),

            const SizedBox(height: 10), // 버튼 간격 추가

            ElevatedButton(
              onPressed: autoLogin,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Auto Login(임시)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}