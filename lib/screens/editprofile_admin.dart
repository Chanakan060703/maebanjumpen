import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/controller/personController.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileAdminPage extends StatefulWidget {
  final Admin user;
  final bool isEnglish;

  const EditProfileAdminPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _EditProfileAdminPageState createState() => _EditProfileAdminPageState();
}

class _EditProfileAdminPageState extends State<EditProfileAdminPage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  // ไม่จำเป็นต้องมี TextEditingController สำหรับ email, idCardNumber, username
  late TextEditingController _adminStatusController;

  File? _imageFile;
  String? _displayImageUrl;

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
    _adminStatusController =
        TextEditingController(text: widget.user.adminStatus ?? '');

    _displayImageUrl = widget.user.person?.pictureUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _adminStatusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
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

    if (_imageFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEnglish
                ? 'Uploading profile picture...'
                : 'กำลังอัปโหลดรูปโปรไฟล์...')),
      );

      // *** แก้ไข: ใช้ personId แทน id ของ Admin สำหรับการอัปโหลดรูปภาพ ***
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
        imageType: 'person',
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
          _imageFile = null;
        });
      } else {
        print('Error: Failed to upload profile picture.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Failed to upload profile picture.'
                  : 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ')),
        );
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
      // ใช้ค่าเดิมจาก widget.user.person สำหรับ email, idCardNumber (เนื่องจากไม่ได้แก้ไขในหน้านี้)
      email: widget.user.person?.email,
      idCardNumber: widget.user.person?.idCardNumber,
      pictureUrl: newPictureUrl,
      accountStatus: widget.user.person?.accountStatus,
    );

    try {
      if (updatedPerson.personId != null) {
        // *** แก้ไข: ส่ง Person object โดยตรงไปยัง updatePerson ***
        final Person? savedPerson = await _personController.updatePerson(
          updatedPerson.personId!,
          updatedPerson, // <<< แก้ไขตรงนี้
        );

        if (savedPerson != null) {
          final Admin updatedAdmin = Admin(
            id: widget.user.id,
            adminStatus: _adminStatusController.text,
            person: savedPerson, // ใช้ savedPerson ที่ได้จากการอัปเดต
          );

          Navigator.pop(context, updatedAdmin);
          print('Admin Profile Saved and returned: ${updatedAdmin.person?.firstName}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    widget.isEnglish ? 'Profile saved!' : 'บันทึกโปรไฟล์สำเร็จ!')),
          );
        } else {
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
    ImageProvider profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_displayImageUrl != null && _displayImageUrl!.isNotEmpty) {
      try {
        profileImage = NetworkImage(_displayImageUrl!);
      } catch (e) {
        print('Error loading network image: $_displayImageUrl, $e');
        profileImage = const AssetImage('assets/images/default_profile.png');
      }
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: SizedBox(
          width: 70.0,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
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
            widget.isEnglish ? 'Edit Admin Profile' : 'แก้ไขโปรไฟล์ผู้ดูแล',
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
                            backgroundImage: profileImage,
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
            // ลบ TextField ของ Email, ID Card Number ออกจาก UI
            // ถ้าคุณต้องการแสดงข้อมูลเหล่านี้แบบอ่านอย่างเดียวเฉยๆ โดยไม่ให้แก้ไข
            // คุณสามารถเพิ่ม Text widget หรือ Listtile เพื่อแสดงข้อมูลได้
            // ตัวอย่าง:
            // Text(
            //   widget.isEnglish ? 'Email: ${widget.user.person?.email ?? 'N/A'}' : 'อีเมล: ${widget.user.person?.email ?? 'N/A'}',
            //   style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            // ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildTextField(
                controller: _adminStatusController,
                labelText: widget.isEnglish ? 'Admin Status' : 'สถานะผู้ดูแล',
                hintText: widget.isEnglish
                    ? 'Please enter admin status (e.g., active, inactive)'
                    : 'กรุณากรอกสถานะผู้ดูแล (เช่น ใช้งาน, ไม่ใช้งาน)',
                readOnly: false, // สถานะผู้ดูแลยังคงแก้ไขได้
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
            // ยกเลิกคอมเมนต์และใช้หน้าหลักของผู้ดูแลระบบจริงหากมี
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //   builder: (context) => HomePageAdmin(user: user, isEnglish: isEnglish)),
            // );
            Navigator.pop(context); // กลับไปหน้าก่อนหน้าหากไม่มีหน้าหลักของผู้ดูแลระบบที่กำหนด
          } else if (index == 1) {
            // ยกเลิกคอมเมนต์และใช้หน้าประวัติของผู้ดูแลระบบจริงหากมี
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //   builder: (context) =>
            //   HistoryPageAdmin(user: user, isEnglish: isEnglish)),
            // );
            Navigator.pop(context); // กลับไปหน้าก่อนหน้า
          } else if (index == 2) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //       builder: (context) =>
            //           ListWithdrawalRequestsScreen(user: user, isEnglish: isEnglish)), // นำทางไปยังหน้าอนุมัติการถอนเงิน
            // );
            Navigator.pop(context); // กลับไปหน้าก่อนหน้า (ถ้ายังไม่มีหน้าสำหรับ AccountManager)
          } else if (index == 3) {
            // ขณะนี้อยู่ในหน้า EditProfileAdminPage
            // การแตะโปรไฟล์อีกครั้งควรจะนำทางกลับไปยัง ProfileAdminPage (ถ้ามี)
            Navigator.pop(context, widget.user); // ส่งผู้ใช้เดิมกลับไปหากไม่มีการบันทึก
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
