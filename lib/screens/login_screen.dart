import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:personal.health.manager/reusable_widgets/reusable_widget.dart';
import 'package:personal.health.manager/utils/color_utils.dart';
import 'package:personal.health.manager/screens/register_screen.dart';
import 'package:personal.health.manager/screens/reset_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();

  // Hàm đăng nhập bằng email và mật khẩu
  Future<void> _signIn() async {
    try {
      if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email và mật khẩu không được để trống!")),
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      String errorMessage = 'Đăng nhập thất bại!';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = "Tài khoản không tồn tại!";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Mật khẩu không đúng!";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Hàm đăng nhập bằng Google
  Future<void> _signInWithGoogle() async {
  try {
     final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
      ? '792888586324-on246kh0pdelgvs6ctelvdghqn3hf0kd.apps.googleusercontent.com' // Thay bằng Web Client ID từ Google Cloud Console
      : null, // Android và iOS không cần clientId
      );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return; // Người dùng hủy đăng nhập
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    print("Đăng nhập thành công! Người dùng: ${userCredential.user?.displayName}");

    // Chuyển đến HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } catch (e) {
    print("Đăng nhập Google thất bại: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng nhập Google thất bại: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            hexStringToColor("CB2B93"),
            hexStringToColor("9546C4"),
            hexStringToColor("5E61F4")
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget("assets/welcome.png"),
                const SizedBox(height: 30),
                reusableTextField("Enter Email", Icons.person_outline, false, _emailTextController),
                const SizedBox(height: 20),
                reusableTextField("Enter Password", Icons.lock_outline, true, _passwordTextController),
                const SizedBox(height: 5),
                forgetPassword(context),
                firebaseUIButton(context, "Sign In", _signIn), // Sử dụng hàm _signIn
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Or Sign in with Google",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _signInWithGoogle, // Kích hoạt hàm đăng nhập Google
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 25,
                    child: Image.asset(
                      "assets/google_icon.png", // Đảm bảo bạn có biểu tượng Google trong thư mục `images`
                      height: 30,
                      width: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                signUpOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have account?", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()));
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen())),
      ),
    );
  }
}
