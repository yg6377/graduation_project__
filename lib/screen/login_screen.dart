import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 추가된 import
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); //2
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
    final user = FirebaseAuth.instance.currentUser; // 자동 로그인 시 컬렉션에 UID 추가
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('unable to auto login, login first!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Login'),
        backgroundColor: Color(0xFFEAF6FF),
        border: null,
      ),
      child: Container(

        color: const Color(0xFFEAF6FF),
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: BouncingScrollPhysics(),
              child: Center(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            'assets/images/huanhuan_welcome.png',
                            height: 300,
                          ),
                          CupertinoTextField(
                            controller: _emailController,
                            placeholder: 'Email',
                            placeholderStyle: TextStyle(color: CupertinoColors.activeBlue),
                            keyboardType: TextInputType.emailAddress,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          const SizedBox(height: 18),
                          CupertinoTextField(
                            controller: _passwordController,
                            placeholder: 'Password',
                            placeholderStyle: TextStyle(color: CupertinoColors.activeBlue),
                            obscureText: true,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          const SizedBox(height: 28),
                          CupertinoTheme(
                            data: CupertinoTheme.of(context).copyWith(
                              primaryColor: const Color(0xFF0078B8), // Blue Bottle blue
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CupertinoButton.filled(
                                  onPressed: login,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: const Text('Login'),
                                ),
                                const SizedBox(height: 14),
                                CupertinoButton.filled(
                                  onPressed: autoLogin,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: const Text('Auto Login'),
                                ),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text(
                            'Is this your first time using the app?',
                            style: TextStyle(
                              color: Color(0xFF0078B8),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}