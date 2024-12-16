import 'package:firebase_core/firebase_core.dart';
import 'package:graduation_project_1/screen/home_screen.dart';
import 'package:graduation_project_1/screen/login_screen.dart';
import 'package:graduation_project_1/screen/chatlist_screen.dart'
import 'package:graduation_project_1/screen/chatroom_screen.dart'
import 'package:graduation_project_1/screen/mypage_screen.dart';
import 'package:graduation_project_1/screen/signup_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/chat': (context) => ChatScreen(),         // 채팅 화면
        '/mypage': (context) => MyPageScreen(),     // 마이페이지 화면
      },
    );
  }
}