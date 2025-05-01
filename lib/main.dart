import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graduation_project_1/screen/home_screen.dart';
import 'package:graduation_project_1/screen/login_screen.dart';
import 'package:graduation_project_1/screen/notification_center.dart';
import 'package:graduation_project_1/screen/signup_screen.dart';
import 'package:graduation_project_1/screen/search_screen.dart';
import 'firebase_options.dart';

// 글로벌 navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 로컬 알림 플러그인 인스턴스
final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[bg] onBackgroundMessage: data=${msg.data}');
  _showLocalNotification(msg);
}

// 로컬 알림 표시 함수
void _showLocalNotification(RemoteMessage msg) {
  // data-only 메시지라 notification이 null일 수 있으니
  final title = msg.data['senderName'] ?? '새 메시지';
  final body  = msg.data['message']    ?? '';

  fln.show(
    msg.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_channel',         // channelId
        'Chat Notifications',   // channel name
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}


// FCM 토큰을 Firestore에 저장
Future<void> _saveDeviceToken() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;
  await FirebaseFirestore.instance
      .collection('deviceTokens')
      .doc(uid)
      .set({'fcmToken': token});
  debugPrint('✅ FCM token saved for $uid: $token');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 로컬 알림 초기화
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await fln.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // 로컬 알림 탭 시 처리 (예: Navigator.pushNamed)
    },
  );

  // Notification Channel 생성
  if (Platform.isAndroid) {
    final channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: '채팅 메시지 알림 채널',
      importance: Importance.high,
    );
    await fln
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('✅ Notification channel created: ${channel.id}');

    // ── 강제 알림 테스트 ──
    /*fln.show(
      0,
      '테스트 알림',
      '로컬 알림 테스트입니다.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );*/
  }

  // 백그라운드 메시지 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Android 13+ 권한 요청
  final settings = await FirebaseMessaging.instance.requestPermission();
  debugPrint('🔔 Permission: ${settings.authorizationStatus}');

  // 로그인 상태 변화 감지해 토큰 저장
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      _saveDeviceToken();
    }
  });

  // 포그라운드 메시지 수신 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    debugPrint('🔥 onMessage payload: notification=${msg.notification}, data=${msg.data}');
    // 1) 시스템 푸시
    _showLocalNotification(msg);
    // 2) 인앱 배너
    final n = msg.notification;
    if (n != null && navigatorKey.currentContext != null) {
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

  // 백그라운드/종료 상태에서 알림 탭 처리
  FirebaseMessaging.onMessage.listen((msg) {
    debugPrint('🥳 onMessage: data=${msg.data}');
    _showLocalNotification(msg);

    // 2) 인앱 배너만
    final n = msg.notification;
    if (n != null && navigatorKey.currentContext != null) {
    }
  });



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.blue),
          titleTextStyle: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
        ),
      ),
      navigatorKey: navigatorKey,
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

