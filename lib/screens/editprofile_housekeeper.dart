import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/controller/housekeeperSkillController.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/controller/skilltypeController.dart';
import 'package:maebanjumpen/controller/personController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/skill_type.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileHousekeeperPage extends StatefulWidget {
  final Housekeeper user;
  final bool isEnglish;

  const EditProfileHousekeeperPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _EditProfileHousekeeperPageState createState() => _EditProfileHousekeeperPageState();
}

class _EditProfileHousekeeperPageState extends State<EditProfileHousekeeperPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dailyRateController = TextEditingController(); // Added for daily rate

  List<SkillType> _availableSkillTypes = [];
  final Map<SkillType, bool> _housekeeperSkillSelection = {};
  List<HousekeeperSkill> _initialHousekeeperSkills = [];

  bool _isLoading = false;
  XFile? _pickedImageFile;
  String? _currentProfilePictureUrl;

  final Skilltypecontroller _skilltypeController = Skilltypecontroller();
  final Housekeeperskillcontroller _housekeeperskillController = Housekeeperskillcontroller();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final PersonController _personController = PersonController();

  final Map<String, String> _skillThaiNames = {
    'General Cleaning': 'ทำความสะอาดทั่วไป',
    'Laundry': 'ซักรีด',
    'Cooking': 'ทำอาหาร',
    'Garden': 'ดูแลสวน',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.person?.firstName ?? '';
    _lastNameController.text = widget.user.person?.lastName ?? '';
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    _addressController.text = widget.user.person?.address ?? '';
    _emailController.text = widget.user.person?.email ?? '';
    _currentProfilePictureUrl = widget.user.person?.pictureUrl;
    _dailyRateController.text = widget.user.dailyRate?.toString() ?? ''; // Initialize daily rate

    _initialHousekeeperSkills = List.from(widget.user.housekeeperSkills ?? []);

    _fetchAndInitializeSkills();
  }

  Future<void> _fetchAndInitializeSkills() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<dynamic> skillTypesJson = await _skilltypeController.getAllSkilltype();

      if (skillTypesJson.isNotEmpty) {
        _availableSkillTypes = skillTypesJson
            .map((json) => SkillType.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _availableSkillTypes = [];
        print('No skill types found or failed to load.');
      }

      for (var skillType in _availableSkillTypes) {
        _housekeeperSkillSelection[skillType] = _initialHousekeeperSkills
                .any((userSkill) => userSkill.skillType?.skillTypeId == skillType.skillTypeId) ??
            false;
      }
    } catch (e) {
      print('Error initializing skills: $e');
      _showErrorSnackBar(widget.isEnglish ? 'Failed to load skills.' : 'ไม่สามารถโหลดทักษะได้');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImageFile = image;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _dailyRateController.dispose(); // Dispose daily rate controller
    super.dispose();
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEnglish ? 'Profile updated successfully!' : 'แก้ไขโปรไฟล์สำเร็จ!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? newProfilePictureUrl = _currentProfilePictureUrl;

      if (_pickedImageFile != null) {
        if (widget.user.person?.personId != null) {
          final uploadedUrl = await _imageUploadService.uploadImage(
            id: widget.user.person!.personId!,
            imageType: 'person',
            imageFile: _pickedImageFile!,
          );
          if (uploadedUrl != null) {
            newProfilePictureUrl = uploadedUrl;
            print('Profile picture uploaded successfully: $newProfilePictureUrl');
          } else {
            throw Exception('Failed to upload profile picture.');
          }
        } else {
          throw Exception('Person ID is null. Cannot upload profile picture.');
        }
      }

      // สร้าง updatedPerson Object
      final updatedPerson = widget.user.person?.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        pictureUrl: newProfilePictureUrl,
      );

      // แปลง dailyRate จาก TextField เป็น double
      final double? newDailyRate = double.tryParse(_dailyRateController.text);

      // สร้าง updatedHousekeeper Object โดยใช้ copyWith
      // จุดสำคัญคือการรวม updatedPerson และ newDailyRate เข้าไปใน Object เดียว
      final updatedHousekeeper = widget.user.copyWith(
        person: updatedPerson,
        dailyRate: newDailyRate,
        // ไม่ต้องส่ง rating มาจาก client เพราะ backend จะคำนวณเอง
      );

      // เรียกเมธอด updateHousekeeper จาก Housekeepercontroller
      // โดยส่ง id และ updatedHousekeeper Object ที่เราสร้างขึ้น
      if (updatedHousekeeper.id != null) {
        await HousekeeperController().updateHousekeeper(
          updatedHousekeeper.id!,
          updatedHousekeeper, // *** ส่ง Housekeeper Object เต็มๆ ***
        );
        print('Housekeeper information updated successfully on backend side!');
      } else {
        print('Warning: Cannot update housekeeper information because housekeeper ID is null.');
      }

      // ส่วนการจัดการทักษะแม่บ้าน (Housekeeper Skills) เหมือนเดิม
      final List<HousekeeperSkill> newSelectedSkills = _housekeeperSkillSelection.entries
          .where((entry) => entry.value)
          .map((entry) => HousekeeperSkill(
                skillType: entry.key,
              ))
          .toList();

      for (var newSkill in newSelectedSkills) {
        if (!_initialHousekeeperSkills.any((initialSkill) =>
                initialSkill.skillType?.skillTypeId == newSkill.skillType?.skillTypeId)) {
          if (widget.user.id != null && newSkill.skillType?.skillTypeId != null) {
            var addResponse = await _housekeeperskillController.addHousekeeperskill(
              widget.user.id!,
              newSkill.skillType!.skillTypeId!,
            );
            if (addResponse['status'] != 'success') {
              throw Exception('Failed to add skill: ${addResponse['message']}');
            }
          }
        }
      }

      for (var initialSkill in _initialHousekeeperSkills) {
        if (!newSelectedSkills.any((newSkill) =>
                newSkill.skillType?.skillTypeId == initialSkill.skillType?.skillTypeId)) {
          if (initialSkill.skillId != null) {
            var deleteResponse = await _housekeeperskillController.deleteHousekeeperskill(
              initialSkill.skillId!,
            );
            if (deleteResponse['status'] != 'success') {
              throw Exception('Failed to delete skill: ${deleteResponse['message']}');
            }
          } else {
            print(
                'Warning: Attempted to delete a skill with null skillId: ${initialSkill.skillType?.skillTypeName}');
          }
        }
      }

      // สร้าง finalUpdatedUser สำหรับส่งกลับไปยังหน้าก่อนหน้า
      final finalUpdatedUser = updatedHousekeeper.copyWith(
        housekeeperSkills: newSelectedSkills,
      );

      _showSuccessSnackBar();
      Navigator.pop(context, finalUpdatedUser);
    } catch (e) {
      print('Save profile error: $e');
      _showErrorSnackBar(
          widget.isEnglish ? 'Failed to update profile: $e' : 'ไม่สามารถอัปเดตโปรไฟล์ได้: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              widget.isEnglish ? 'Save' : 'บันทึก',
              style: TextStyle(color: _isLoading ? Colors.grey : Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading && _availableSkillTypes.isEmpty && _pickedImageFile == null
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24.0,
                    ),
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
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 60.0,
                                  backgroundImage: _pickedImageFile != null
                                      ? FileImage(File(_pickedImageFile!.path)) as ImageProvider
                                      : (_currentProfilePictureUrl != null &&
                                              _currentProfilePictureUrl!.isNotEmpty
                                          ? NetworkImage(_currentProfilePictureUrl!)
                                          : const AssetImage('assets/default_profile.png'))
                                        as ImageProvider,
                                  onBackgroundImageError: (exception, stackTrace) {
                                    print('Error loading image: $exception');
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16.0,
                    ),
                    child: _buildTextField(
                      controller: _firstNameController,
                      labelText: widget.isEnglish ? 'Firstname' : 'ชื่อจริง',
                      hintText: widget.isEnglish ? 'Please enter your Firstname' : 'โปรดป้อนชื่อจริงของคุณ',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTextField(
                      controller: _lastNameController,
                      labelText: widget.isEnglish ? 'Lastname' : 'นามสกุล',
                      hintText: widget.isEnglish ? 'Please enter your Lastname' : 'โปรดป้อนนามสกุลของคุณ',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTextField(
                      controller: _phoneController,
                      labelText: widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                      hintText: widget.isEnglish ? 'Please enter your Phone' : 'โปรดป้อนเบอร์โทรศัพท์ของคุณ',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTextField(
                      controller: _addressController,
                      labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
                      hintText: widget.isEnglish ? 'Please enter your Address' : 'โปรดป้อนที่อยู่ของคุณ',
                      maxLines: 3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24.0,
                    ),
                    child: _buildTextField(
                      controller: _emailController,
                      labelText: widget.isEnglish ? 'Email' : 'อีเมล',
                      hintText: widget.isEnglish ? 'Please enter your Email' : 'โปรดป้อนอีเมลของคุณ',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24.0,
                    ),
                    child: _buildTextField(
                      controller: _dailyRateController,
                      labelText: widget.isEnglish ? 'Daily Rate' : 'ค่าจ้างรายวัน',
                      hintText: widget.isEnglish ? 'Please enter your daily rate' : 'โปรดป้อนค่าจ้างรายวันของคุณ',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          widget.isEnglish ? 'Housekeeper Skills' : 'ทักษะแม่บ้าน',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_availableSkillTypes.isNotEmpty)
                        ..._availableSkillTypes.map((skillType) {
                          final String displayName = widget.isEnglish
                              ? (skillType.skillTypeName ?? '')
                              : (_skillThaiNames[skillType.skillTypeName ?? ''] ??
                                  skillType.skillTypeName ??
                                  '');

                          return CheckboxListTile(
                            title: Text(displayName),
                            value: _housekeeperSkillSelection[skillType],
                            onChanged: _isLoading
                                ? null
                                : (bool? newValue) {
                                    setState(() {
                                      _housekeeperSkillSelection[skillType] = newValue!;
                                    });
                                  },
                            activeColor: Colors.red,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        })
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            widget.isEnglish ? 'No skills available.' : 'ไม่มีทักษะให้เลือก',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
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
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card_outlined),
            label: widget.isEnglish ? 'Cards' : 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: widget.isEnglish ? 'Hire' : 'การจ้าง',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: widget.isEnglish ? 'Profile' : 'โปรไฟล์'),
        ],
        currentIndex: 3,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          // Handle bottom navigation item taps
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