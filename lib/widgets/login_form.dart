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

  // Username validation based on new rules
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter username' : 'กรุณากรอกชื่อผู้ใช้';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return isEnglish ? 'Username cannot contain spaces' : 'ชื่อผู้ใช้ต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length < 4 || trimmedValue.length > 8) {
      return isEnglish
          ? 'Username must be between 4 and 8 characters'
          : 'ชื่อผู้ใช้ต้องมีความยาวระหว่าง 4-8 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmedValue)) {
      return isEnglish
          ? 'Username must contain only English letters and numbers'
          : 'ชื่อผู้ใช้ต้องประกอบด้วยตัวอักษรภาษาอังกฤษหรือตัวเลขเท่านั้น';
    }
    return null;
  }

  // Password validation based on new rules
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter password' : 'กรุณากรอกรหัสผ่าน';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return isEnglish ? 'Password cannot contain spaces' : 'รหัสผ่านต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length < 8 || trimmedValue.length > 16) {
      return isEnglish
          ? 'Password must be between 8 and 16 characters'
          : 'รหัสผ่านต้องมีความยาวระหว่าง 8-16 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(trimmedValue)) {
      return isEnglish
          ? 'Password must contain English letters, numbers, or special characters (!#_.)'
          : 'รหัสผ่านต้องประกอบด้วยตัวอักษรภาษาอังกฤษ ตัวเลข หรืออักขระพิเศษ (!#_.)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const redColor = Color(0xFFEB2525);

    return Column(
      children: [
        // Username Field
        TextFormField(
          controller: usernameController,
          cursorColor: redColor,
          decoration: InputDecoration(
            labelText: isEnglish ? "Username" : "ชื่อผู้ใช้",
            labelStyle: const TextStyle(color: redColor),
            floatingLabelStyle: const TextStyle(color: redColor),
            prefixIcon: const Icon(Icons.person, color: redColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: redColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: _validateUsername,
        ),
        const SizedBox(height: 15),

        // Password Field
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          cursorColor: redColor,
          decoration: InputDecoration(
            labelText: isEnglish ? "Password" : "รหัสผ่าน",
            labelStyle: const TextStyle(color: redColor),
            floatingLabelStyle: const TextStyle(color: redColor),
            prefixIcon: const Icon(Icons.lock, color: redColor),
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
              borderSide: const BorderSide(color: redColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: _validatePassword,
        ),
      ],
    );
  }
}
