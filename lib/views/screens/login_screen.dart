import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:restoran/views/screens/create_account.dart';
import 'package:restoran/views/screens/home_screen.dart';
import 'package:restoran/views/widgets/submit_button.dart';
import 'package:restoran/views/widgets/text_feild.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', _emailController.text.trim());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message = e.message!;
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
        _showErrorDialog(message);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog(
          'Iltimos, parolingizni tiklash uchun elektron pochtangizni kiriting.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showInfoDialog(
          'Parolni tiklash elektron pochtasi yuborildi. Pochtangizni tekshiring.');
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message!);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff041955),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: const Text(
          "Error",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(
                Colors.white.withOpacity(0.1),
              ),
            ),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff041955),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: const Text(
          "Info",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(
                Colors.white.withOpacity(0.1),
              ),
            ),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xff969EF3),
            Color(0xff041955),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(150),
                const Text(
                  "Sign in",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(20),
                TextFieldWidget(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  image: "person",
                  hintText: "Email or User Name",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const Gap(20),
                TextFieldWidget(
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscureText,
                  controller: _passwordController,
                  suffixIcon: GestureDetector(
                    onTap: _togglePasswordVisibility,
                    child: Icon(
                      _obscureText
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: const Color(0xff041955),
                    ),
                  ),
                  image: 'password',
                  hintText: 'Password',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter something';
                    }
                    if (value.length < 8) {
                      return "Password must be at least 8 characters long";
                    }
                    return null;
                  },
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _sendPasswordResetEmail,
                      child: const Text(
                        "Forget Password?",
                        style: TextStyle(
                          color: Color(0xff041955),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SubmitButton(
                        text: 'Sign in',
                        onTap: _submit,
                      ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: 80,
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CreateAccount()),
              );
            },
            child: Center(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Don’t have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextSpan(
                      text: "Sign Up",
                      style: TextStyle(
                          color: Color(0xff041955),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
