import 'package:flutter/material.dart';

class LoginFormFields extends StatelessWidget {
  final bool isEnglish;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const LoginFormFields({
    super.key,
    required this.isEnglish,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    const redColor = Color(0xFFEB2525);

    return Column(
      children: [
        // Email
        TextField(
          controller: usernameController,
          cursorColor: redColor,
          decoration: InputDecoration(
            labelText: isEnglish ? "Username" : "ชื่อผู้ใช้",
            labelStyle: const TextStyle(color: redColor),
            floatingLabelStyle: const TextStyle(color: redColor),
            prefixIcon: Icon(Icons.email, color: redColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: redColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Password
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          cursorColor: redColor,
          decoration: InputDecoration(
            labelText: isEnglish ? "Password" : "รหัสผ่าน",
            labelStyle: const TextStyle(color: redColor),
            floatingLabelStyle: const TextStyle(color: redColor),
            prefixIcon: Icon(Icons.lock, color: redColor),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: redColor,
              ),
              onPressed: onTogglePassword,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: redColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
