import 'package:flutter/material.dart';

class RegisterForm extends StatefulWidget {
  final bool isEnglish;
  final Function(String)? onEmailChanged;
  final Function(String)? onUsernameChanged;
  final Function(String)? onPasswordChanged;
  final Function(String)? onConfirmPasswordChanged;
  final Function(String)? onFirstNameChanged;
  final Function(String)? onLastNameChanged;
  final Function(String)? onIdCardChanged;
  final Function(String)? onPhoneChanged;
  final Function(String)? onAddressChanged;

  const RegisterForm({
    super.key,
    required this.isEnglish,
    this.onEmailChanged,
    this.onUsernameChanged,
    this.onPasswordChanged,
    this.onConfirmPasswordChanged,
    this.onFirstNameChanged,
    this.onLastNameChanged,
    this.onIdCardChanged,
    this.onPhoneChanged,
    this.onAddressChanged,
  });

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return widget.isEnglish ? 'Please enter email' : 'กรุณากรอกอีเมล';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return widget.isEnglish ? 'Invalid email format' : 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return widget.isEnglish ? 'Please enter username' : 'กรุณากรอกชื่อผู้ใช้';
    }
    if (value.length < 6) {
      return widget.isEnglish
          ? 'Username must be at least 6 characters'
          : 'ชื่อผู้ใช้ต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return widget.isEnglish ? 'Please enter password' : 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6){
      return widget.isEnglish
          ? 'Password must be at least 6 characters'
          : 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return widget.isEnglish
          ? 'Passwords do not match'
          : 'รหัสผ่านไม่ตรงกัน';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return widget.isEnglish
          ? 'Please enter $fieldName'
          : 'กรุณากรอก$fieldName';
    }
    return null;
  }

  String? _validateIdCardNumber(String? value) {
  if (value == null || value.isEmpty) {
    return widget.isEnglish 
        ? 'Please enter ID card number' 
        : 'กรุณากรอกเลขบัตรประชาชน';
  }
  if (value.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
    return widget.isEnglish
        ? 'ID card must be 13 digits'
        : 'เลขบัตรประชาชนต้องเป็นตัวเลข 13 หลัก';
  }
  return null;
}


String? _validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return widget.isEnglish 
        ? 'Please enter phone number' 
        : 'กรุณากรอกเบอร์โทรศัพท์';
  }
  if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
    return widget.isEnglish
        ? 'Phone number must be 10 digits'
        : 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก';
  }
  return null;
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // อีเมล
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Email' : 'อีเมล',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          onChanged: widget.onEmailChanged,
        ),
        SizedBox(height: 16),

        // ชื่อผู้ใช้
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Username' : 'ชื่อผู้ใช้',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: _validateUsername,
          onChanged: widget.onUsernameChanged,
        ),
        SizedBox(height: 16),
        // รหัสผ่าน
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Password' : 'รหัสผ่าน',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(),
          ),
          obscureText: _obscurePassword,
          validator: _validatePassword,
          onChanged: widget.onPasswordChanged,
        ),
        SizedBox(height: 16),

        // ยืนยันรหัสผ่าน
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText:
                widget.isEnglish ? 'Confirm Password' : 'ยืนยันรหัสผ่าน',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(),
          ),
          obscureText: _obscureConfirmPassword,
          validator: _validateConfirmPassword,
          onChanged: widget.onConfirmPasswordChanged,
        ),
        SizedBox(height: 16),

        // ชื่อ
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'First Name' : 'ชื่อ',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) => _validateRequired(
              value, widget.isEnglish ? 'first name' : 'ชื่อ'),
          onChanged: widget.onFirstNameChanged,
        ),
        SizedBox(height: 16),

        // นามสกุล
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Last Name' : 'นามสกุล',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) => _validateRequired(
              value, widget.isEnglish ? 'last name' : 'นามสกุล'),
          onChanged: widget.onLastNameChanged,
        ),
        SizedBox(height: 16),

        // เลขบัตรประชาชน
        TextFormField(
          controller: _idCardController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'ID Card Number' : 'เลขบัตรประชาชน',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return widget.isEnglish
                  ? 'Please enter ID card number'
                  : 'กรุณากรอกเลขบัตรประชาชน';
            }
            if (value.length != 13) {
              return widget.isEnglish
                  ? 'ID card number must be 13 digits'
                  : 'เลขบัตรประชาชนต้องมี 13 หลัก';
            }
            return null;
          },
          onChanged: widget.onIdCardChanged,
        ),
        SizedBox(height: 16),

        // เบอร์โทรศัพท์
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Phone Number' : 'เบอร์โทรศัพท์',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return widget.isEnglish
                  ? 'Please enter phone number'
                  : 'กรุณากรอกเบอร์โทรศัพท์';
            }
            if (value.length != 10) {
              return widget.isEnglish
                  ? 'Phone number must be 10 digits'
                  : 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
            }
            return null;
          },
          onChanged: widget.onPhoneChanged,
        ),
        SizedBox(height: 16),

        // ที่อยู่
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) => _validateRequired(
              value, widget.isEnglish ? 'address' : 'ที่อยู่'),
          onChanged: widget.onAddressChanged,
        ),
      ],
    );
  }
}