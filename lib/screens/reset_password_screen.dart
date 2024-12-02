import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal.health.manager/reusable_widgets/reusable_widget.dart';
import 'package:personal.health.manager/screens/home_screen.dart';
import 'package:personal.health.manager/utils/color_utils.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPasswordScreen> {
  TextEditingController _emailTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 99, 187, 152),
        elevation: 0,
        title: const Text(
          "Reset Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            hexStringToColor("CB2B93"),
            hexStringToColor("9546C4"),
            hexStringToColor("5E61F4")
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SingleChildScrollView(
              child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Email", Icons.person_outline, false,
                    _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                firebaseUIButton(context, "Reset Password", () {
                  FirebaseAuth.instance
                  .sendPasswordResetEmail(email: _emailTextController.text)
                  .then((value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã gửi email đặt lại mật khẩu")),
                );
                Navigator.of(context).pop();
                  })
                  .catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gửi email thất bại: $error")),
                    );
                  });
                })
              ],
            ),
          ))),
    );
  }
}