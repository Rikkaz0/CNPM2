import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:personal.health.manager/screens/chat_screen.dart';
import 'package:personal.health.manager/screens/register_screen.dart';
import 'package:personal.health.manager/screens/reset_password_screen.dart';
import 'package:personal.health.manager/consts.dart';
import 'screens/home_screen.dart';
import 'screens/health_tracker_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  // Đảm bảo rằng Flutter đã khởi tạo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Gemini
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );
  
  // Chạy ứng dụng
  runApp(MyApp());
}


class PersonalHealthManager extends StatelessWidget {
  const PersonalHealthManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      routes: {
        '/login':(context) => LoginScreen(),
        '/register':(context) => RegisterScreen(),
        '/rspassword':(context) => ResetPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/health-tracker': (context) =>  HealthTrackerScreen(),
        '/statistics': (context) => ChatScreen(),
      },
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Health Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}