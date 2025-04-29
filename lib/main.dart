import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';             // ← 추가
import 'package:graduation_project_1/screen/home_screen.dart';
import 'package:graduation_project_1/screen/login_screen.dart';
import 'package:graduation_project_1/screen/notification_center.dart';
import 'package:graduation_project_1/screen/signup_screen.dart';
import 'package:graduation_project_1/screen/search_screen.dart';
import 'firebase_options.dart';

// 글로벌 navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[bg] messageId=${msg.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Android 13+ 권한 요청
  await FirebaseMessaging.instance.requestPermission();

  // 디버깅용 토큰 출력, 앱 실행 시 뜨는 토큰을 파이어베이스 클라우드 메시징-테스트메시지 복사하면됨
  _printToken();

  // 포그라운드 메시지 수신 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    final n = msg.notification;
    if (n != null && navigatorKey.currentContext != null) {
      // Flushbar 로 상단 배너 알림
      Flushbar(
        title: n.title,
        message: n.body,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(navigatorKey.currentContext!);
    }
  });

  runApp(const MyApp());
}

Future<void> _printToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print('📱 FCM Token: $token');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,   // 최상단 context 확보용!!
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login':       (_) => const LoginScreen(),
        '/signup':      (_) => const SignUpScreen(),
        '/home':        (_) => const HomeScreen(),
        '/search':      (_) => const SearchScreen(),
        '/notification':(_) => const NotificationCenterScreen(),
      },
    );
  }
}

