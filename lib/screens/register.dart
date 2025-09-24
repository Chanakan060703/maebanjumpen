import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/login.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:maebanjumpen/widgets/register_form.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isLoading = false;
  String selectedAccountType = 'Member';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isEnglish = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String email = '';
  String username = '';
  String password = '';
  String firstName = '';
  String lastName = '';
  String idCardNumber = '';
  String phoneNumber = '';
  String address = '';
  String accountStatus = 'active';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
  }
  
  void _showErrorDialog({String? title, String? desc}) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      customHeader: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        radius: 40,
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 40),
      ),
      title: title ?? (isEnglish ? 'Oops!' : 'เกิดข้อผิดพลาด'),
      desc: desc ??
          (isEnglish ? 'An unexpected error occurred.' : 'เกิดข้อผิดพลาดที่ไม่คาดคิด'),
      btnOkText: isEnglish ? 'OK' : 'ตกลง',
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      descTextStyle: const TextStyle(fontSize: 16),
      buttonsTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ).show();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
    });

    try {
      // 1. สร้างข้อมูล Login
      final loginResponse = await http.post(
        Uri.parse('$baseURL/maeban/login'),
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      // 2. สร้าง Object Person
      final personResponse = await http.post(
        Uri.parse('$baseURL/maeban/persons'),
        headers: headers,
        body: json.encode({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'idCardNumber': idCardNumber,
          'phoneNumber': phoneNumber,
          'address': address,
          'pictureUrl': null,
          'accountStatus': accountStatus,
          'login': {
            'username': username,
            'password': password,
          },
        }),
      );

      if (personResponse.statusCode != 200) {
        throw Exception('Failed to create person: ${personResponse.body}');
      }

      final person = Person.fromJson(json.decode(personResponse.body));

      // 3. สร้าง Party Role (Hirer หรือ Housekeeper)
      final partyRoleResponse = await http.post(
        Uri.parse('$baseURL/maeban/party-roles'),
        headers: headers,
        body: json.encode({
          'person_id': person.personId,
          'type': selectedAccountType == 'Member' ? 'hirer' : 'housekeeper',
        }),
      );

      if (partyRoleResponse.statusCode != 200) {
        throw Exception(
          'Failed to create party role: ${partyRoleResponse.body}',
        );
      }

      final partyRoleData = json.decode(partyRoleResponse.body);
      final int partyRoleId = partyRoleData['id'];

      String? finalPhotoVerifyUrl;

      // 4. อัปโหลดรูปภาพ (เฉพาะ Housekeeper และถ้ามีการเลือกรูปภาพ)
      if (selectedAccountType == 'Housekeeper') {
        if (_selectedImage != null) {
          final imageUploadService = ImageUploadService();
          String? uploadedImageUrl = await imageUploadService.uploadImage(
            id: partyRoleId,
            imageType: 'housekeeper',
            imageFile: XFile(_selectedImage!.path),
          );

          if (uploadedImageUrl != null) {
            finalPhotoVerifyUrl = uploadedImageUrl;
            print('Uploaded Housekeeper photo URL: $finalPhotoVerifyUrl');
          } else {
            print('Warning: Failed to upload housekeeper verification image.');
          }
        } else {
          _showErrorDialog(
            title: isEnglish ? 'Image Required' : 'ต้องมีการอัปโหลดรูปภาพ',
            desc: isEnglish ? 'Housekeeper registration requires a verification photo.' : 'การสมัครแม่บ้านต้องอัปโหลดรูปยืนยันตัวตน',
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // 5. เปลี่ยนเส้นทางตามประเภทบัญชี
      if (selectedAccountType == 'Member') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Your housekeeper application is being processed and awaits admin approval. Please log in after approval.'
                  : 'การสมัครแม่บ้านของคุณอยู่ระหว่างรอการอนุมัติจากผู้ดูแลระบบ โปรดเข้าสู่ระบบหลังจากได้รับการอนุมัติ',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('/maeban/persons')) {
          _showErrorDialog(
          title: isEnglish ? 'Registration Failed' : 'การสมัครสมาชิกล้มเหลว',
          desc: isEnglish ? 'Username already exists. Please choose another one.' : 'ข้อมูลชื่อผู้ใช้ซ้ำ กรุณากรอกใหม่อีกครั้ง',
        );
      } else {
        _showErrorDialog(
          title: isEnglish ? 'Registration Failed' : 'การสมัครสมาชิกล้มเหลว',
          desc: isEnglish
              ? 'An unexpected error occurred. Please try again later.'
              : 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้งในภายหลัง',
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _accountTypeButton(String type) {
    final isSelected = selectedAccountType == type;

    IconData iconData;
    String labelText;
    String subLabelText;

    if (type == 'Member') {
      iconData = Icons.account_circle;
      labelText = isEnglish ? 'Member' : 'ผู้ว่าจ้าง';
      subLabelText = isEnglish ? 'For Member' : 'สำหรับผู้ว่าจ้าง';
    } else {
      iconData = Icons.work;
      labelText = isEnglish ? 'Housekeeper' : 'แม่บ้าน';
      subLabelText = isEnglish ? 'For Housekeeper' : 'สำหรับแม่บ้าน';
    }

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedAccountType = type;
            if (type == 'Member') {
              _selectedImage = null;
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          side: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 40,
              color: isSelected ? Colors.white : Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              labelText,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabelText,
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: isSelected ? Colors.white : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: _goBackToLogin,
        ),
        actions: [
          ToggleButtons(
            isSelected: [isEnglish, !isEnglish],
            onPressed: (index) {
              setState(() {
                isEnglish = index == 0;
              });
            },
            borderRadius: BorderRadius.circular(20),
            selectedColor: Colors.white,
            fillColor: Colors.red,
            color: Colors.black,
            borderColor: Colors.transparent,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("ENG"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("ไทย"),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 20),
                  const SizedBox(height: 12),
                  Text(
                    isEnglish ? 'Maebaan Jampen' : 'แม่บ้านจำเป็น',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isEnglish ? 'Create your Account' : 'สร้างบัญชีของคุณ',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _accountTypeButton('Member'),
                      const SizedBox(width: 12),
                      _accountTypeButton('Housekeeper'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: RegisterForm(
                      isEnglish: isEnglish,
                      onEmailChanged: (value) => email = value,
                      onUsernameChanged: (value) => username = value,
                      onPasswordChanged: (value) => password = value,
                      onConfirmPasswordChanged: (
                        value,
                      ) {},
                      onFirstNameChanged: (value) => firstName = value,
                      onLastNameChanged: (value) => lastName = value,
                      onIdCardChanged: (value) => idCardNumber = value,
                      onPhoneChanged: (value) => phoneNumber = value,
                      onAddressChanged: (value) => address = value,
                    ),
                  ),
                  if (selectedAccountType == 'Housekeeper') ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isEnglish
                            ? 'Upload Your Verification Photo: ID Card'
                            : 'อัปโหลดรูปยืนยันตัวตนของคุณ: บัตรประจำตัวประชาชน',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey.shade100,
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEnglish
                                        ? 'Tap to upload image (required for Housekeeper)'
                                        : 'แตะเพื่อเลือกรูปภาพ (จำเป็นสำหรับแม่บ้าน)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.red)
                      : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                          ),
                          child: Text(isEnglish ? 'Submit' : 'ส่งข้อมูล'),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}