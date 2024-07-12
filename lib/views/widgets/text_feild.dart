import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final Widget? suffixIcon;
  final String image;
  final String hintText;
  final String? Function(String?) validator;
  bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  TextFieldWidget({
    super.key,
    required this.controller,
    this.suffixIcon,
    required this.image,
    required this.hintText,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textCapitalization: textCapitalization!,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      obscureText: obscureText,
      validator: validator,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(.3),
        suffixIcon: suffixIcon,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            "assets/icons/$image.png",
            width: 30,
            height: 30,
          ),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color.fromARGB(130, 27, 56, 135)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
