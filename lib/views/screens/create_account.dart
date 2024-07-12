import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:restoran/views/screens/home_screen.dart';
import 'package:restoran/views/screens/login_screen.dart';
import 'package:restoran/views/widgets/submit_button.dart';
import 'package:restoran/views/widgets/text_feild.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordCheckController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
        String message = e.message ?? "An error occurred";
        if (e.code == 'email-already-in-use') {
          message = "Email already exists";
        }
        _showErrorDialog(message);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff041955),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xff041955),
                Color(0xff969EF3),
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: SizedBox(
              height: 80,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xff041955),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 80),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(30),
                        const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Color(0xff041955),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(30),
                        TextFieldWidget(
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.name,
                          controller: _nameController,
                          image: "person",
                          hintText: "Full Name",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const Gap(30),
                        TextFieldWidget(
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          image: "email",
                          hintText: "Email",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const Gap(30),
                        TextFieldWidget(
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
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            return null;
                          },
                        ),
                        const Gap(30),
                        TextFieldWidget(
                          obscureText: _obscureText,
                          controller: _passwordCheckController,
                          suffixIcon: GestureDetector(
                            onTap: _togglePasswordVisibility,
                            child: Icon(
                              _obscureText
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              color: const Color(0xff041955),
                            ),
                          ),
                          image: "password",
                          hintText: "Confirm Password",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const Gap(30),
                        Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : SubmitButton(
                                  text: "Sign Up",
                                  onTap: _submit,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset("assets/icons/arrow.png",
                              width: 25, height: 25),
                          const Text(
                            "Back",
                            style: TextStyle(
                                color: Color(0xff471AA0), fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            "assets/images/sign_up.png",
            color: const Color(0xff041955),
            width: 200,
            height: 153,
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}
