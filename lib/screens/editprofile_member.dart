import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/controller/personController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileMemberPage extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const EditProfileMemberPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _EditProfileMemberPageState createState() => _EditProfileMemberPageState();
}

class _EditProfileMemberPageState extends State<EditProfileMemberPage> {
  // Global key for the Form to validate data
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;

  File? _imageFile; // Stores the newly selected image
  String? _displayImageUrl; // Stores the URL of the image to display

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

  // --- Image Handling Functions ---
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

  // --- Validation Functions ---
  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter your Firstname' : 'กรุณากรอกชื่อ';
    }
    // Updated to allow spaces and a wider range of characters
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2 || trimmedValue.length > 40) {
      return widget.isEnglish ? 'Firstname must be between 2-40 characters' : 'ชื่อต้องมีความยาวระหว่าง 2-40 ตัวอักษร';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter your Lastname' : 'กรุณากรอกนามสกุล';
    }
    // Updated to allow spaces and a wider range of characters
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2 || trimmedValue.length > 40) {
      return widget.isEnglish ? 'Lastname must be between 2-40 characters' : 'นามสกุลต้องมีความยาวระหว่าง 2-40 ตัวอักษร';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter your Phone number' : 'กรุณากรอกเบอร์โทรศัพท์';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains(' ')) {
      return widget.isEnglish ? 'Phone number must not contain spaces' : 'เบอร์โทรศัพท์ต้องไม่มีช่องว่าง';
    }
    if (trimmedValue.length != 10) {
      return widget.isEnglish ? 'Phone number must be 10 digits' : 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
      return widget.isEnglish ? 'Phone number must contain digits only' : 'เบอร์โทรศัพท์ต้องประกอบด้วยตัวเลขเท่านั้น';
    }
    if (!trimmedValue.startsWith('06') && !trimmedValue.startsWith('08') && !trimmedValue.startsWith('09')) {
      return widget.isEnglish ? 'Phone number must start with 06, 08, or 09' : 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 06, 08, หรือ 09';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.isEnglish ? 'Please enter your Address' : 'กรุณากรอกที่อยู่';
    }
    // Removed strict regex validation to allow more characters as requested
    return null;
  }

  // --- Save Profile Logic ---
  Future<void> _saveProfile() async {
    // Validate all fields first
    // ** Calling _formKey.currentState!.validate() calls the validator of every TextFormField in the Form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEnglish
                ? 'Please correct the errors in the form.'
                : 'กรุณาแก้ไขข้อมูลที่ผิดพลาดในฟอร์ม')),
      );
      return;
    }

    String? newPictureUrl = _displayImageUrl;

    // Check if a new image was selected and upload it
    if (_imageFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEnglish
                ? 'Uploading profile picture...'
                : 'กำลังอัปโหลดรูปโปรไฟล์...')),
      );

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
        id: widget.user.person!.personId!,
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

    // Create the updated Person object with new data
    final Person updatedPerson = Person(
      personId: widget.user.person?.personId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      email: _emailController.text, // Email is read-only but included here
      pictureUrl: newPictureUrl,
      idCardNumber: widget.user.person?.idCardNumber, // Keep original ID Card
      accountStatus: widget.user.person?.accountStatus, // Keep original status
    );

    // Call the updatePerson method from PersonController
    try {
      if (updatedPerson.personId != null) {
        final Person? savedPerson = await _personController.updatePerson(
          updatedPerson.personId!,
          updatedPerson,
        );

        if (savedPerson != null) {
          final Hirer updatedHirer = Hirer(
            id: widget.user.id,
            person: savedPerson,
            balance: widget.user.balance ?? 0.0,
            type: widget.user.type,
          );

          Navigator.pop(context, updatedHirer);
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

  // --- Build UI Widget ---
  @override
  Widget build(BuildContext context) {
    ImageProvider profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_displayImageUrl != null && _displayImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(_displayImageUrl!);
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
      // ** Fixed: Added Form widget and linked it to _formKey
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Section
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
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
                      widget.isEnglish ? 'Change Profile Photo' : 'เปลี่ยนรูปโปรไฟล์',
                      style: const TextStyle(color: Colors.red, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Firstname Field
              _buildTextFormField(
                controller: _firstNameController,
                labelText: widget.isEnglish ? 'Firstname' : 'ชื่อ',
                hintText: widget.isEnglish ? 'Please enter your Firstname' : 'กรุณากรอกชื่อของคุณ',
                validator: _validateFirstName,
              ),
              const SizedBox(height: 16.0),
              
              // Lastname Field
              _buildTextFormField(
                controller: _lastNameController,
                labelText: widget.isEnglish ? 'Lastname' : 'นามสกุล',
                hintText: widget.isEnglish ? 'Please enter your Lastname' : 'กรุณากรอกนามสกุลของคุณ',
                validator: _validateLastName,
              ),
              const SizedBox(height: 16.0),
              
              // Phone Number Field
              _buildTextFormField(
                controller: _phoneController,
                labelText: widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                hintText: widget.isEnglish ? 'Please enter your Phone' : 'กรุณากรอกเบอร์โทรศัพท์ของคุณ',
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
              ),
              const SizedBox(height: 16.0),
              
              // Address Field
              _buildTextFormField(
                controller: _addressController,
                labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
                hintText: widget.isEnglish ? 'Please enter your Address' : 'กรุณากรอกที่อยู่ของคุณ',
                maxLines: 3,
                validator: _validateAddress,
              ),
              const SizedBox(height: 16.0),
              
              // Email Field (Read-only)
              _buildTextFormField(
                controller: _emailController,
                labelText: widget.isEnglish ? 'Email' : 'อีเมล',
                hintText: widget.isEnglish ? 'Please enter your Email' : 'กรุณากรอกอีเมลของคุณ',
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              const SizedBox(height: 24.0),
              
              // Confirm Button
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card_outlined),
            label: widget.isEnglish ? 'Cards' : 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: widget.isEnglish ? 'Booking' : 'การจอง',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        currentIndex: 3,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          final user = widget.user;
          final bool isEnglish = widget.isEnglish;

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(user: user, isEnglish: isEnglish)),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => CardpageMember(user: user, isEnglish: isEnglish)),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HireListPage(user: user, isEnglish: isEnglish)),
            );
          } else if (index == 3) {
            Navigator.pop(context, widget.user);
          }
        },
      ),
    );
  }

  // Helper widget for form fields (changed from TextField to TextFormField)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
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
          // ** Pass the received validator to TextFormField
          validator: validator,
        ),
      ],
    );
  }
}
