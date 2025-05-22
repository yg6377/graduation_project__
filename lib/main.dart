import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project_1/screen/ChangeRegionScreen.dart';
import 'package:graduation_project_1/screen/chatlist_Screen.dart';
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
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graduation Project',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final user = snapshot.data;
          if (user != null) {
            // 로그인된 경우 fcmToken 저장
            FirebaseMessaging.instance.getToken().then((token) {
              if (token != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'fcmToken': token});
                FirebaseMessaging.instance.subscribeToTopic('all');
              }
            });

            // 포그라운드 메시지 수신
            FirebaseMessaging.onMessage.listen((RemoteMessage message) {
              _showLocalNotification(message);
            });

            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => const HomeScreen(),
        '/search': (_) => const SearchScreen(),
        '/notification': (_) => const NotificationCenterScreen(),
        '/changeRegion': (_) => const ChangeRegionScreen(),
        '/chatlist': (_) => const ChatListScreen(),
        '/chatRoom': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatRoomScreen(
            chatRoomId: args['chatRoomId'],
            userName: args['userName'],
            saleStatus: args['saleStatus'],
          );
        },
      },
    );
  }
}