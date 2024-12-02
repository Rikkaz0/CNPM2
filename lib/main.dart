import 'package:flutter/material.dart';
import 'package:personal.health.manager/screens/register_screen.dart';
import 'package:personal.health.manager/screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/health_tracker_screen.dart';
import 'screens/statistics_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {runApp(const PersonalHealthManager());
   
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/statistics': (context) => StatisticsScreen(),
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