import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:graduation_project_1/screen/ChangeRegionScreen.dart';
import 'package:graduation_project_1/screen/chatroom_screen.dart';
import 'firebase_options.dart';
import 'screen/login_screen.dart';
import 'screen/signup_screen.dart';
import 'screen/home_screen.dart';
import 'screen/search_screen.dart';
import 'screen/notification_center.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

/// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _showLocalNotification(message);
}

/// 로컬 알림 표시
void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  final android = message.notification?.android;

  if (notification != null && android != null) {
    localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_channel',
          'Chat Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

/// 디바이스 토큰 저장
Future<void> _saveDeviceToken() async {
  final user = FirebaseAuth.instance.currentUser;
  final token = await FirebaseMessaging.instance.getToken();
  if (user != null && token != null) {
    await FirebaseFirestore.instance
        .collection('deviceTokens')
        .doc(user.uid)
        .set({'fcmToken': token});
  }
}

Future<void> main() async {
  debugPrint('🔥 main started');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 로컬 알림 초기화
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveNotificationResponse: (response) {
      // 알림 클릭 처리
      debugPrint('🔔 Notification clicked: ${response.payload}');
      navigatorKey.currentState?.pushNamed('/notification');
    },
  );

  // Android Notification Channel 생성
  if (Platform.isAndroid) {
    final channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.high,
      description: '채팅 알림 채널',
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Firebase Messaging 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 권한 요청
  final settings = await FirebaseMessaging.instance.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('✅ Notification permission granted');
  } else {
    debugPrint('⚠️ Notification permission declined');
  }

  // 로그인 상태 감지 후 토큰 저장
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      _saveDeviceToken();
    }
  });

  // 포그라운드 메시지 수신
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔥 Foreground message received');
    _showLocalNotification(message);

    final notification = message.notification;
    if (notification != null && navigatorKey.currentContext != null) {
      Flushbar(
        title: notification.title,
        message: notification.body,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(navigatorKey.currentContext!);
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graduation Project',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => const HomeScreen(),
        '/search': (_) => const SearchScreen(),
        '/notification': (_) => const NotificationCenterScreen(),
        '/changeRegion': (_) => const ChangeRegionScreen(),
        '/chatRoom': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatRoomScreen(
            chatRoomId: args['chatRoomId'],
            userName: args['userName'],
            saleStatus: args['saleStatus'],
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
