import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal.health.manager/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:personal.health.manager/screens/health_tracker_screen.dart';
import 'package:personal.health.manager/screens/statistics_screen.dart';
import 'package:personal.health.manager/utils/color_utils.dart';
import 'package:personal.health.manager/reusable_widgets/reusable_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
   _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Health Manager'),
      ),
      body:
        Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          hexStringToColor("CB2B93"),
          hexStringToColor("9546C4"),
          hexStringToColor("5E61F4")
        ],begin: Alignment.topCenter, end: Alignment.bottomCenter)),
  
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            logoWidget("images/health.png"),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HealthTrackerScreen()));
              },
              child: const Text('Health Tracker'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StatisticsScreen()));
              },
              child: const Text('Statistics'),
            ),
            ElevatedButton(
              onPressed: () {
              FirebaseAuth.instance.signOut().then((value) {
             print("Signed Out");
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            });
          },
              child: const Text("Logout"),
        ),
          ],
        ),
      ),
    ); 
  }
}        