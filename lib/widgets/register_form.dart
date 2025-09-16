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
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (widget.onPasswordChanged != null) {
        widget.onPasswordChanged!(_passwordController.text);
      }
      _confirmPasswordController.text = _confirmPasswordController.text;
    });
    _confirmPasswordController.addListener(() {
      if (widget.onConfirmPasswordChanged != null) {
        widget.onConfirmPasswordChanged!(_confirmPasswordController.text);
      }
    });
  }

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

  // Email validation based on new rules
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter email' : 'กรุณากรอกอีเมล';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'Email cannot contain spaces' : 'อีเมลต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length < 5 || trimmedValue.length > 60) {
      return widget.isEnglish
          ? 'Email must be between 5 and 60 characters'
          : 'อีเมลต้องมีความยาวระหว่าง 5-60 ตัวอักษร';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedValue)) {
      return widget.isEnglish ? 'Invalid email format' : 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  // Username validation based on new rules
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter username' : 'กรุณากรอกชื่อผู้ใช้';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'Username cannot contain spaces' : 'ชื่อผู้ใช้ต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length < 4 || trimmedValue.length > 8) {
      return widget.isEnglish
          ? 'Username must be between 4 and 8 characters'
          : 'ชื่อผู้ใช้ต้องมีความยาวระหว่าง 4-8 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmedValue)) {
      return widget.isEnglish
          ? 'Username must contain only English letters and numbers'
          : 'ชื่อผู้ใช้ต้องประกอบด้วยตัวอักษรภาษาอังกฤษหรือตัวเลขเท่านั้น';
    }
    return null;
  }

  // Password validation based on new rules
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter password' : 'กรุณากรอกรหัสผ่าน';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'Password cannot contain spaces' : 'รหัสผ่านต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length < 8 || trimmedValue.length > 16) {
      return widget.isEnglish
          ? 'Password must be between 8 and 16 characters'
          : 'รหัสผ่านต้องมีความยาวระหว่าง 8-16 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(trimmedValue)) {
      return widget.isEnglish
          ? 'Password must contain English letters, numbers, or special characters (!#_.)'
          : 'รหัสผ่านต้องประกอบด้วยตัวอักษรภาษาอังกฤษ ตัวเลข หรืออักขระพิเศษ (!#_.)';
    }
    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please confirm your password' : 'กรุณายืนยันรหัสผ่าน';
    }
    if (value != _passwordController.text) {
      return widget.isEnglish
          ? 'Passwords do not match'
          : 'รหัสผ่านไม่ตรงกัน';
    }
    return null;
  }
  
  // First Name validation based on new rules
  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter first name' : 'กรุณากรอกชื่อ';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2 || trimmedValue.length > 40) {
      return widget.isEnglish
          ? 'First name must be between 2 and 40 characters'
          : 'ชื่อต้องมีความยาวระหว่าง 2-40 ตัวอักษร';
    }
    
if (!RegExp(r'^[a-zA-Zก-๙\s]+$').hasMatch(trimmedValue)) {
  return widget.isEnglish
      ? 'First name must contain only Thai or English letters'
      : 'ชื่อต้องประกอบด้วยตัวอักษรภาษาไทยหรืออังกฤษเท่านั้น';
}

    return null;
  }

  // Last Name validation based on new rules
  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter last name' : 'กรุณากรอกนามสกุล';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2 || trimmedValue.length > 40) {
      return widget.isEnglish
          ? 'Last name must be between 2 and 40 characters'
          : 'นามสกุลต้องมีความยาวระหว่าง 2-40 ตัวอักษร';
    }
if (!RegExp(r'^[a-zA-Zก-๙\s]+$').hasMatch(trimmedValue)) {
  return widget.isEnglish
      ? 'Last name must contain only Thai or English letters'
      : 'นามสกุลต้องประกอบด้วยตัวอักษรภาษาไทยหรืออังกฤษเท่านั้น';
}
    return null;
  }

  // ID Card Number validation based on new rules
  String? _validateIdCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish
          ? 'Please enter ID card number'
          : 'กรุณากรอกเลขบัตรประชาชน';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'ID card number cannot contain spaces' : 'เลขบัตรประชาชนต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length != 13) {
      return widget.isEnglish
          ? 'ID card must be 13 digits'
          : 'เลขบัตรประชาชนต้องเป็นตัวเลข 13 หลัก';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
      return widget.isEnglish
          ? 'ID card number must contain only digits'
          : 'เลขบัตรประชาชนต้องประกอบด้วยตัวเลขเท่านั้น';
    }
    return null;
  }

  // Phone Number validation based on new rules
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish
          ? 'Please enter phone number'
          : 'กรุณากรอกเบอร์โทรศัพท์';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'Phone number cannot contain spaces' : 'เบอร์โทรศัพท์ต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length != 10) {
      return widget.isEnglish
          ? 'Phone number must be 10 digits'
          : 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
      return widget.isEnglish
          ? 'Phone number must contain only digits'
          : 'เบอร์โทรศัพท์ต้องประกอบด้วยตัวเลขเท่านั้น';
    }
    if (!trimmedValue.startsWith('06') && !trimmedValue.startsWith('08') && !trimmedValue.startsWith('09')) {
      return widget.isEnglish
          ? 'Phone number must start with 06, 08, or 09'
          : 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 06, 08, หรือ 09';
    }
    return null;
  }

  // Address validation based on new rules
  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter address' : 'กรุณากรอกที่อยู่';
    }
    final trimmedValue = value.trim();
    if (!RegExp(r'^[a-zA-Zก-๙\s/.,()-]+$').hasMatch(trimmedValue) && !trimmedValue.contains('หมู่')) {
      return widget.isEnglish
          ? 'Address must contain only Thai letters, numbers, and spaces'
          : 'ที่อยู่ต้องประกอบด้วยตัวอักษรภาษาไทย ตัวเลข หรือช่องว่างเท่านั้น';
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
            prefixIcon: const Icon(Icons.email),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          onChanged: widget.onEmailChanged,
        ),
        const SizedBox(height: 16),

        // ชื่อผู้ใช้
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Username' : 'ชื่อผู้ใช้',
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
          ),
          validator: _validateUsername,
          onChanged: widget.onUsernameChanged,
        ),
        const SizedBox(height: 16),
        
        // รหัสผ่าน
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Password' : 'รหัสผ่าน',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: const OutlineInputBorder(),
          ),
          obscureText: _obscurePassword,
          validator: _validatePassword,
          onChanged: widget.onPasswordChanged,
        ),
        const SizedBox(height: 16),

        // ยืนยันรหัสผ่าน
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText:
                widget.isEnglish ? 'Confirm Password' : 'ยืนยันรหัสผ่าน',
            prefixIcon: const Icon(Icons.lock),
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
            border: const OutlineInputBorder(),
          ),
          obscureText: _obscureConfirmPassword,
          validator: _validateConfirmPassword,
          onChanged: widget.onConfirmPasswordChanged,
        ),
        const SizedBox(height: 16),

        // ชื่อ
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'First Name' : 'ชื่อ',
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
          ),
          validator: _validateFirstName,
          onChanged: widget.onFirstNameChanged,
        ),
        const SizedBox(height: 16),

        // นามสกุล
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Last Name' : 'นามสกุล',
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
          ),
          validator: _validateLastName,
          onChanged: widget.onLastNameChanged,
        ),
        const SizedBox(height: 16),

        // เลขบัตรประชาชน
        TextFormField(
          controller: _idCardController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'ID Card Number' : 'เลขบัตรประชาชน',
            prefixIcon: const Icon(Icons.credit_card),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: _validateIdCardNumber,
          onChanged: widget.onIdCardChanged,
        ),
        const SizedBox(height: 16),

        // เบอร์โทรศัพท์
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Phone Number' : 'เบอร์โทรศัพท์',
            prefixIcon: const Icon(Icons.phone),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: _validatePhoneNumber,
          onChanged: widget.onPhoneChanged,
        ),
        const SizedBox(height: 16),

        // ที่อยู่
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
            prefixIcon: const Icon(Icons.home),
            border: const OutlineInputBorder(),
            hintText: widget.isEnglish 
                ? 'e.g. House No. 123 Village No. 6 Sub-district District Province'
                : 'เช่น 212 หมู่บ้าน ตำบล อำเภอ จังหวัด',
          ),
          maxLines: 2,
          validator: _validateAddress,
          onChanged: widget.onAddressChanged,
        ),
      ],
    );
  }
}