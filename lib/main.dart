import 'package:firebase_core/firebase_core.dart';
import 'package:graduation_project_1/screen/home_screen.dart';
import 'package:graduation_project_1/screen/login_screen.dart';
import 'package:graduation_project_1/screen/notification_center.dart';
import 'package:graduation_project_1/screen/signup_screen.dart';
import 'package:graduation_project_1/screen/search_screen.dart';
import 'dev/dev_utils.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // NTD 안뜨면 주석해제하고 한번 디버깅하면됨.
  //await updateAllPrices();
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
        '/search': (context) => SearchScreen(),
        '/notification': (context) => NotificationCenterScreen(),
      },
    );
  }
}