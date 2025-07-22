import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/controller/personController.dart';
import 'package:maebanjumpen/model/account_manager.dart'; // เปลี่ยนจาก Hirer เป็น AccountManager
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/screens/list_withdraw_accountmanager.dart'; // หน้าอนุมัติการถอนเงิน
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileAccountManagerPage extends StatefulWidget { // เปลี่ยนชื่อคลาส
  final AccountManager user; // เปลี่ยนประเภท user
  final bool isEnglish;

  const EditProfileAccountManagerPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _EditProfileAccountManagerPageState createState() => _EditProfileAccountManagerPageState(); // เปลี่ยนชื่อ State
}

class _EditProfileAccountManagerPageState extends State<EditProfileAccountManagerPage> { // เปลี่ยนชื่อ State
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;

  File? _imageFile; // เก็บรูปภาพที่เลือกใหม่
  String? _displayImageUrl; // เก็บ URL รูปภาพที่จะแสดงผลใน CircleAvatar (อาจเป็นรูปเดิม หรือรูปใหม่ที่อัปโหลดแล้ว)

  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final PersonController _personController = PersonController();

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.user.person?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.user.person?.lastName ?? '');
    _phoneController =
        TextEditingController(text: widget.user.person?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: widget.user.person?.address ?? '');
    _emailController =
        TextEditingController(text: widget.user.person?.email ?? '');

    // กำหนด URL รูปภาพเริ่มต้นที่จะแสดงผล
    _displayImageUrl = widget.user.person?.pictureUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // เมื่อเลือกรูปใหม่ ให้แสดงรูปที่เลือกทันที
      });
      print('Selected image path: ${pickedFile.path}');
    } else {
      print('No image selected.');
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(widget.isEnglish ? 'Camera' : 'กล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(widget.isEnglish ? 'Gallery' : 'แกลเลอรี'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    String? newPictureUrl = _displayImageUrl;

    // แสดง SnackBar เพื่อแจ้งว่ากำลังอัปโหลดรูป
    if (_imageFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEnglish
                ? 'Uploading profile picture...'
                : 'กำลังอัปโหลดรูปโปรไฟล์...')),
      );

      // *** แก้ไขตรงนี้: ใช้ personId แทน id ของ AccountManager ***
      if (widget.user.person?.personId == null) {
        print('Error: Person ID is null. Cannot upload profile picture.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Failed to update profile: Person ID is missing.'
                  : 'อัปเดตโปรไฟล์ไม่สำเร็จ: ไม่มีรหัสบุคคล.')),
        );
        return;
      }

      String? uploadedUrl = await _imageUploadService.uploadImage(
        id: widget.user.person!.personId!, // <<< แก้ไขตรงนี้
        imageType: 'person', // หรือประเภทอื่น ๆ ที่เหมาะสม
        imageFile: XFile(_imageFile!.path),
      );

      if (uploadedUrl != null) {
        newPictureUrl = uploadedUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Profile picture uploaded successfully!'
                  : 'อัปโหลดรูปโปรไฟล์สำเร็จ!')),
        );
        setState(() {
          _displayImageUrl = newPictureUrl;
          _imageFile = null; // เคลียร์ _imageFile หลังจากอัปโหลดสำเร็จ
        });
      } else {
        print('Error: Failed to upload profile picture.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Failed to upload profile picture.'
                  : 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ')),
        );
        // หากอัปโหลดรูปไม่สำเร็จ ไม่ต้องดำเนินการต่อ
        return; 
      }
    }

    // สร้างออบเจกต์ Person ที่อัปเดตแล้ว
    final Person updatedPerson = Person(
      personId: widget.user.person?.personId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      email: _emailController.text,
      pictureUrl: newPictureUrl, // ใช้ newPictureUrl ที่อาจถูกอัปเดตจากการอัปโหลดรูป
      idCardNumber: widget.user.person?.idCardNumber,
      accountStatus: widget.user.person?.accountStatus,
      // ไม่ต้องใส่ login object ที่นี่ เพราะ PersonController.updatePerson ไม่ได้ใช้
    );

    // เรียกใช้เมธอด updatePerson จาก PersonController
    try {
      // ตรวจสอบให้แน่ใจว่า personId ไม่เป็น null ก่อนเรียก updatePerson
      if (updatedPerson.personId != null) {
        // *** แก้ไขตรงนี้: ส่ง Person object โดยตรง ***
        final Person? savedPerson = await _personController.updatePerson(
          updatedPerson.personId!,
          updatedPerson, // <<< แก้ไขตรงนี้
        );

        if (savedPerson != null) {
          // สร้างออบเจกต์ AccountManager ที่อัปเดตแล้ว หลังจากการอัปเดต Person สำเร็จ
          final AccountManager updatedAccountManager = AccountManager(
            id: widget.user.id,
            person: savedPerson, // ใช้ savedPerson ที่ได้จากการอัปเดต
            // ถ้ามีฟิลด์เฉพาะของ AccountManager เช่น `managerSpecificField` ให้เพิ่มที่นี่
            // managerSpecificField: widget.user.managerSpecificField,
          );

          // กลับไปหน้า Profile พร้อมส่งข้อมูล AccountManager ที่อัปเดตแล้วกลับไปด้วย
          Navigator.pop(context, updatedAccountManager);
          print('Profile Saved and returned: ${updatedAccountManager.person?.firstName}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    widget.isEnglish ? 'Profile saved!' : 'บันทึกโปรไฟล์สำเร็จ!')),
          );
        } else {
          // กรณีที่ updatePerson คืนค่า null (อาจจะหา Person ไม่เจอ)
          print('Error: Person update returned null.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isEnglish
                    ? 'Failed to save profile: Person update failed.'
                    : 'บันทึกโปรไฟล์ไม่สำเร็จ: การอัปเดตบุคคลล้มเหลว.')),
          );
        }
      } else {
        print('Error: Person ID is null. Cannot update profile in database.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Failed to save profile: Person ID is missing.'
                  : 'บันทึกโปรไฟล์ไม่สำเร็จ: ไม่มีรหัสบุคคล.')),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEnglish
                ? 'Failed to save profile. Please try again. Error: ${e.toString().split(':').last.trim()}'
                : 'บันทึกโปรไฟล์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง. ข้อผิดพลาด: ${e.toString().split(':').last.trim()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด ImageProvider ตามลำดับความสำคัญ:
    // 1. รูปภาพที่เลือกใหม่ (จาก _imageFile)
    // 2. รูปภาพจาก Network (จาก _displayImageUrl)
    // 3. รูปภาพ Default (จาก assets)
    ImageProvider profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_displayImageUrl != null && _displayImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(_displayImageUrl!);
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png'); // ตรวจสอบพาธให้ถูกต้อง
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: SizedBox(
          width: 70.0,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context); // กลับโดยไม่มีการส่งข้อมูล
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              widget.isEnglish ? 'Cancel' : 'ยกเลิก',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
        title: Center(
          child: Text(
            widget.isEnglish ? 'Edit Profile' : 'แก้ไขโปรไฟล์',
            style: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              widget.isEnglish ? 'Save' : 'บันทึก',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60.0,
                            backgroundImage: profileImage, // <--- ใช้ profileImage ที่กำหนดไว้
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        widget.isEnglish
                            ? 'Change Profile Photo'
                            : 'เปลี่ยนรูปโปรไฟล์',
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTextField(
                controller: _firstNameController,
                labelText: widget.isEnglish ? 'Firstname' : 'ชื่อ',
                hintText:
                    widget.isEnglish ? 'Please enter your Firstname' : 'กรุณากรอกชื่อของคุณ',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTextField(
                controller: _lastNameController,
                labelText: widget.isEnglish ? 'Lastname' : 'นามสกุล',
                hintText:
                    widget.isEnglish ? 'Please enter your Lastname' : 'กรุณากรอกนามสกุลของคุณ',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTextField(
                controller: _phoneController,
                labelText: widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                hintText:
                    widget.isEnglish ? 'Please enter your Phone' : 'กรุณากรอกเบอร์โทรศัพท์ของคุณ',
                keyboardType: TextInputType.phone,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTextField(
                controller: _addressController,
                labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
                hintText:
                    widget.isEnglish ? 'Please enter your Address' : 'กรุณากรอกที่อยู่ของคุณ',
                maxLines: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildTextField(
                controller: _emailController,
                labelText: widget.isEnglish ? 'Email' : 'อีเมล',
                hintText:
                    widget.isEnglish ? 'Please enter your Email' : 'กรุณากรอกอีเมลของคุณ',
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // อีเมลมักจะแก้ไขไม่ได้
              ),
            ),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                widget.isEnglish ? 'Confirm' : 'ยืนยัน',
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: widget.isEnglish ? 'Home' : 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work), // เปลี่ยนไอคอนให้เข้ากับ 'History'
            label: widget.isEnglish ? 'History' : 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet), // ไอคอนสำหรับ 'Withdrawal'
            label: widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        currentIndex: 3, // ตั้งค่าให้แท็บโปรไฟล์เป็นค่าเริ่มต้น
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          final user = widget.user; // ยังคงเป็น AccountManager
          final bool isEnglish = widget.isEnglish;

          if (index == 0) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //   builder: (context) => HomePageAccountManager(user: user, isEnglish: isEnglish)), // ไปหน้าหลักของ AccountManager
            // );
            Navigator.pop(context); // อาจจะกลับไปหน้าหลักของ AccountManager โดยส่งข้อมูลกลับไป
          } else if (index == 1) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //   builder: (context) =>
            //   HistoryPageAccountManager(user: user, isEnglish: isEnglish)), // ไปหน้าประวัติของ AccountManager
            // );
            Navigator.pop(context); // อาจจะกลับไปหน้าหลักของ AccountManager โดยส่งข้อมูลกลับไป
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ListWithdrawalRequestsScreen(user: user, isEnglish: isEnglish)), // ไปหน้าอนุมัติการถอนเงิน
            );
          } else if (index == 3) {
            // อยู่ในหน้า EditProfileAccountManagerPage
            // การแตะ Profile อีกครั้งควรจะกลับไปหน้า ProfileAccountManagerPage (ถ้ามี)
            Navigator.pop(context, widget.user); // ส่งข้อมูลเดิมกลับไป หากไม่มีการ Save
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
