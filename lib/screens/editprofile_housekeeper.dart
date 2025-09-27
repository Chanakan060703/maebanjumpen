import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/controller/housekeeperSkillController.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/controller/personController.dart';
import 'package:maebanjumpen/controller/skill_level_tierController.dart';
import 'package:maebanjumpen/controller/skilltypeController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/skill_level_tier.dart';
import 'package:maebanjumpen/model/skill_type.dart';

class EditProfileHousekeeperPage extends StatefulWidget {
  final Housekeeper user;
  final bool isEnglish;

  const EditProfileHousekeeperPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _EditProfileHousekeeperPageState createState() =>
      _EditProfileHousekeeperPageState();
}

class _EditProfileHousekeeperPageState
    extends State<EditProfileHousekeeperPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dailyRateController = TextEditingController();

  List<SkillType> _availableSkillTypes = [];
  List<SkillLevelTier> _availableSkillLevelTiers = [];

  final Map<SkillType, int?> _selectedSkillLevelTierId = {};
  final Map<SkillType, TextEditingController> _customDailyRateControllers = {};

  List<HousekeeperSkill> _initialHousekeeperSkills = [];
  bool _isLoading = false;
  XFile? _pickedImageFile;
  String? _currentProfilePictureUrl;

  final Skilltypecontroller _skilltypeController = Skilltypecontroller();
  final Housekeeperskillcontroller _housekeeperskillController =
      Housekeeperskillcontroller();
  final SkillLevelTierController _skillleveltierController =
      SkillLevelTierController();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final PersonController _personController = PersonController();

  final Map<String, String> _skillThaiNames = {
    'General Cleaning': 'ทำความสะอาดทั่วไป',
    'Laundry': 'ซักรีด',
    'Cooking': 'ทำอาหาร',
    'Garden': 'ดูแลสวน',
    'Pet Care': 'ดูแลสัตว์เลี้ยง',
    'Window Cleaning': 'ทำความสะอาดหน้าต่าง',
    'Organization': 'จัดระเบียบ',
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchAndInitializeSkills();
  }

  void _initializeControllers() {
    _firstNameController.text = widget.user.person?.firstName ?? '';
    _lastNameController.text = widget.user.person?.lastName ?? '';
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    _addressController.text = widget.user.person?.address ?? '';
    _emailController.text = widget.user.person?.email ?? '';
    _dailyRateController.text = widget.user.dailyRate?.toString() ?? '';
    _currentProfilePictureUrl = widget.user.person?.pictureUrl;
    _initialHousekeeperSkills = List.from(widget.user.housekeeperSkills ?? []);
  }

  Future<void> _fetchAndInitializeSkills() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final skillTypeResult = await _skilltypeController.getAllSkilltype();
_availableSkillTypes = skillTypeResult; 

      final List<SkillLevelTier>? skillLevelTiers =
          await _skillleveltierController.getAllSkillLevelTiers();
      _availableSkillLevelTiers = skillLevelTiers ?? [];

      _availableSkillLevelTiers.sort(
        (a, b) => (a.minHiresForLevel ?? 0).compareTo(b.minHiresForLevel ?? 0),
      );

      for (var skillType in _availableSkillTypes) {
        final existingUserSkill = _initialHousekeeperSkills.firstWhere(
          (userSkill) =>
              userSkill.skillType?.skillTypeId == skillType.skillTypeId,
          orElse: () => HousekeeperSkill(),
        );

        _customDailyRateControllers[skillType] = TextEditingController(
          text: (existingUserSkill.pricePerDay ?? 0.0).toStringAsFixed(2),
        );

        final int totalHiresCompleted =
            existingUserSkill.totalHiresCompleted ?? 0;
        if (existingUserSkill.skillId != null) {
          SkillLevelTier currentTier = _getSkillLevelTier(totalHiresCompleted);
          _selectedSkillLevelTierId[skillType] = currentTier.id;
        }
      }
    } catch (e) {
      print('Error initializing skills: $e');
      _showErrorSnackBar(
        widget.isEnglish ? 'Failed to load skills.' : 'ไม่สามารถโหลดทักษะได้',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  SkillLevelTier _getSkillLevelTier(int totalHiresCompleted) {
    for (var tier in _availableSkillLevelTiers.reversed) {
      if (totalHiresCompleted >= (tier.minHiresForLevel ?? 0)) {
        return tier;
      }
    }
    return _availableSkillLevelTiers.first;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImageFile = image);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? newProfileUrl = _currentProfilePictureUrl;

      if (_pickedImageFile != null && widget.user.person?.personId != null) {
        final uploadedUrl = await _imageUploadService.uploadImage(
          id: widget.user.person!.personId!,
          imageType: 'person',
          imageFile: _pickedImageFile!,
        );
        if (uploadedUrl == null) {
          throw Exception('Failed to upload profile picture.');
        }
        newProfileUrl = uploadedUrl;
      }

      final updatedPerson = widget.user.person?.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        pictureUrl: newProfileUrl,
      );

      final updatedHousekeeper = widget.user.copyWith(
        person: updatedPerson,
        dailyRate: double.tryParse(_dailyRateController.text),
      );

      final List<HousekeeperSkill> newSelectedSkills = [];
      _selectedSkillLevelTierId.forEach((skillType, tierId) {
        if (tierId != null) {
          final tier = _availableSkillLevelTiers.firstWhere(
            (t) => t.id == tierId,
            orElse: () => SkillLevelTier(),
          );

          final customPriceController = _customDailyRateControllers[skillType];
          final customPrice = double.tryParse(
            customPriceController?.text ?? '',
          );
          final double? maxDailyLimit =
              (tier.maxPricePerHourLimit != null)
                  ? tier.maxPricePerHourLimit! * 8
                  : null;

          if (customPrice != null &&
              maxDailyLimit != null &&
              customPrice > maxDailyLimit) {
            throw Exception(
              'Price for ${widget.isEnglish ? skillType.skillTypeName : _skillThaiNames[skillType.skillTypeName ?? '']} exceeds the maximum limit of ${maxDailyLimit.toStringAsFixed(2)} THB.',
            );
          }

          final existingUserSkill = _initialHousekeeperSkills.firstWhere(
            (userSkill) =>
                userSkill.skillType?.skillTypeId == skillType.skillTypeId,
            orElse: () => HousekeeperSkill(),
          );

          newSelectedSkills.add(
            HousekeeperSkill(
              skillId: existingUserSkill.skillId,
              housekeeper: existingUserSkill.housekeeper,
              skillType: skillType,
              skillLevelTier: tier,
              totalHiresCompleted: existingUserSkill.totalHiresCompleted,
              pricePerDay: customPrice,
            ),
          );
        }
      });

      if (updatedHousekeeper.id != null) {
        await HousekeeperController().updateHousekeeper(
          updatedHousekeeper.id!,
          updatedHousekeeper,
        );
      }

      for (var skill in newSelectedSkills) {
        final skillTypeId = skill.skillType?.skillTypeId;
        final tierId = skill.skillLevelTier?.id;

        if (skillTypeId != null && tierId != null) {
          if (skill.skillId == null && widget.user.id != null) {
            await _housekeeperskillController.addHousekeeperskill(
              widget.user.id!,
              skillTypeId,
              tierId,
              customDailyRate: skill.pricePerDay ?? 0.0,
            );
          } else if (skill.skillId != null) {
            final existing = _initialHousekeeperSkills.firstWhere(
              (s) => s.skillId == skill.skillId,
              orElse: () => HousekeeperSkill(),
            );

            if (existing.skillLevelTier?.id != skill.skillLevelTier?.id ||
                existing.pricePerDay != skill.pricePerDay) {
              await _housekeeperskillController.updateHousekeeperskill(
                skill.skillId!,
                tierId,
                customDailyRate: skill.pricePerDay ?? 0.0,
              );
            }
          }
        }
      }

      for (var initialSkill in _initialHousekeeperSkills) {
        if (!newSelectedSkills.any(
          (s) =>
              s.skillType?.skillTypeId == initialSkill.skillType?.skillTypeId,
        )) {
          if (initialSkill.skillId != null) {
            await _housekeeperskillController.deleteHousekeeperskill(
              initialSkill.skillId!,
            );
          }
        }
      }

      final finalUpdatedUser = updatedHousekeeper.copyWith(
        housekeeperSkills: newSelectedSkills,
      );

      _showSuccessSnackBar(
        widget.isEnglish
            ? 'Profile updated successfully!'
            : 'แก้ไขโปรไฟล์สำเร็จ!',
      );
      if (mounted) {
        Navigator.pop(context, finalUpdatedUser);
      }
    } catch (e) {
      print('Save profile error: $e');
      _showErrorSnackBar(
        widget.isEnglish
            ? 'Failed to update profile: ${e.toString().split(':').last.trim()}'
            : 'ไม่สามารถอัปเดตโปรไฟล์ได้: ${e.toString().split(':').last.trim()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Profile updated successfully!'
              : 'แก้ไขโปรไฟล์สำเร็จ!',
        ),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _dailyRateController.dispose();
    _customDailyRateControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.isEnglish ? 'Cancel' : 'ยกเลิก',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
        title: Text(
          widget.isEnglish ? 'Edit Profile' : 'แก้ไขโปรไฟล์',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              widget.isEnglish ? 'Save' : 'บันทึก',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading && _availableSkillTypes.isEmpty
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfilePhoto(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _firstNameController,
                      labelText: widget.isEnglish ? 'Firstname' : 'ชื่อจริง',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      labelText: widget.isEnglish ? 'Lastname' : 'นามสกุล',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      labelText: widget.isEnglish ? 'Address' : 'ที่อยู่',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      labelText: widget.isEnglish ? 'Email' : 'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dailyRateController,
                      labelText:
                          widget.isEnglish
                              ? 'Daily Rate'
                              : 'อัตราค่าบริการรายวัน (ฐาน)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    _buildSkillSection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundImage:
                  _pickedImageFile != null
                      ? FileImage(File(_pickedImageFile!.path))
                      : (_currentProfilePictureUrl != null &&
                                  _currentProfilePictureUrl!.isNotEmpty
                              ? NetworkImage(_currentProfilePictureUrl!)
                              : const AssetImage('assets/default_profile.png'))
                          as ImageProvider,
              onBackgroundImageError:
                  (exception, stackTrace) =>
                      print('Error loading image: $exception'),
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSkillPrice(SkillType skillType) async {
    setState(() => _isLoading = true);
    try {
      final customPriceController = _customDailyRateControllers[skillType];
      final customPrice = double.tryParse(customPriceController?.text ?? '');

      if (customPrice == null) {
        throw Exception(
          widget.isEnglish ? 'Invalid price format.' : 'รูปแบบราคาไม่ถูกต้อง',
        );
      }

      final existingUserSkill = _initialHousekeeperSkills.firstWhere(
        (userSkill) =>
            userSkill.skillType?.skillTypeId == skillType.skillTypeId,
        orElse: () => HousekeeperSkill(),
      );

      final tierId = _selectedSkillLevelTierId[skillType];
      if (tierId == null) {
        throw Exception(
          widget.isEnglish
              ? 'Skill level tier not selected.'
              : 'ไม่ได้เลือกระดับทักษะ',
        );
      }
      final tier = _availableSkillLevelTiers.firstWhere(
        (t) => t.id == tierId,
        orElse: () => SkillLevelTier(),
      );

      final double? maxDailyLimit =
          (tier.maxPricePerHourLimit != null)
              ? tier.maxPricePerHourLimit! * 8
              : null;

      if (maxDailyLimit != null && customPrice > maxDailyLimit) {
        throw Exception(
          'Price for ${widget.isEnglish ? skillType.skillTypeName : _skillThaiNames[skillType.skillTypeName ?? '']} exceeds the maximum limit of ${maxDailyLimit.toStringAsFixed(2)} THB.',
        );
      }

      final int? currentHousekeeperId = widget.user.id;
      final int? currentSkillTypeId = skillType.skillTypeId;
      final int? currentTierId = tier.id;

      if (currentHousekeeperId == null ||
          currentSkillTypeId == null ||
          currentTierId == null) {
        throw Exception(
          widget.isEnglish
              ? 'Missing required ID for saving skill price.'
              : 'ขาดรหัสที่จำเป็นสำหรับการบันทึกราคาทักษะ',
        );
      }

      if (existingUserSkill.skillId == null) {
        await _housekeeperskillController.addHousekeeperskill(
          currentHousekeeperId,
          currentSkillTypeId,
          currentTierId,
          customDailyRate: customPrice,
        );
      } else {
        await _housekeeperskillController.updateHousekeeperskill(
          existingUserSkill.skillId!,
          currentTierId,
          customDailyRate: customPrice,
        );
      }

      _showSuccessSnackBar(
        widget.isEnglish ? 'Price saved successfully!' : 'บันทึกราคาสำเร็จ!',
      );
    } catch (e) {
      print('Save skill price error: $e');
      _showErrorSnackBar(
        widget.isEnglish
            ? 'Failed to save price: ${e.toString().split(':').last.trim()}'
            : 'ไม่สามารถบันทึกราคาได้: ${e.toString().split(':').last.trim()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSkillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEnglish ? 'Housekeeper Skills' : 'ทักษะแม่บ้าน',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._availableSkillTypes.map((skillType) {
          final displayName =
              widget.isEnglish
                  ? skillType.skillTypeName ?? ''
                  : (_skillThaiNames[skillType.skillTypeName ?? ''] ??
                      skillType.skillTypeName ??
                      '');
          final isSelected =
              _selectedSkillLevelTierId.containsKey(skillType) &&
              _selectedSkillLevelTierId[skillType] != null;
          final customRateController = _customDailyRateControllers[skillType];

          final existingUserSkill = _initialHousekeeperSkills.firstWhere(
            (userSkill) =>
                userSkill.skillType?.skillTypeId == skillType.skillTypeId,
            orElse: () => HousekeeperSkill(),
          );

          final int totalHiresCompleted =
              existingUserSkill.totalHiresCompleted ?? 0;
          final currentTier = _getSkillLevelTier(totalHiresCompleted);

          // หา Tier ถัดไปสำหรับ Progress Bar
          final nextTier = _availableSkillLevelTiers.firstWhere(
            (tier) =>
                (tier.minHiresForLevel ?? 0) >
                (currentTier.minHiresForLevel ?? 0),
            orElse: () => SkillLevelTier(),
          );

          final int minHiresForNextLevel = nextTier.minHiresForLevel ?? 0;
          final int remainingHires =
              (minHiresForNextLevel > totalHiresCompleted)
                  ? minHiresForNextLevel - totalHiresCompleted
                  : 0;

          // คำนวณค่าสำหรับ Progress Bar
          final double progressValue =
              (minHiresForNextLevel > 0)
                  ? totalHiresCompleted / minHiresForNextLevel
                  : 0.0;

          final double? maxDailyLimit =
              (currentTier.maxPricePerHourLimit != null)
                  ? currentTier.maxPricePerHourLimit! * 8
                  : null;
          final double? customPrice = double.tryParse(
            customRateController?.text ?? '',
          );
          final bool isPriceExceedsLimit =
              maxDailyLimit != null &&
              customPrice != null &&
              customPrice > maxDailyLimit;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(displayName),
                value: isSelected,
                onChanged: (bool? newValue) {
                  setState(() {
                    if (newValue == true) {
                      final tier = _getSkillLevelTier(totalHiresCompleted);
                      _selectedSkillLevelTierId[skillType] = tier.id;
                      _customDailyRateControllers[skillType] ??=
                          TextEditingController();
                      final existingPrice =
                          _initialHousekeeperSkills
                              .firstWhere(
                                (userSkill) =>
                                    userSkill.skillType?.skillTypeId ==
                                    skillType.skillTypeId,
                                orElse: () => HousekeeperSkill(),
                              )
                              .pricePerDay;
                      _customDailyRateControllers[skillType]!
                          .text = (existingPrice ?? 0.0).toStringAsFixed(2);
                    } else {
                      _selectedSkillLevelTierId.remove(skillType);
                    }
                  });
                },
                activeColor: Colors.red,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (isSelected && customRateController != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.isEnglish ? 'Skill Level:' : 'ระดับทักษะ:'} ${currentTier.skillLevelName ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ส่วนที่ปรับปรุง: แสดง Progress Bar และข้อความที่เกี่ยวข้อง
                      if (minHiresForNextLevel > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${widget.isEnglish ? 'Hires:' : 'จำนวนงาน:'} $totalHiresCompleted / $minHiresForNextLevel',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${(progressValue * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey[300],
                              color: Colors.red,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            if (remainingHires > 0)
                              Text(
                                widget.isEnglish
                                    ? 'Complete $remainingHires more hires to become ${nextTier.skillLevelName}!'
                                    : 'ต้องทำงานอีก $remainingHires ครั้งเพื่อเลื่อนระดับเป็น ${nextTier.skillLevelName}!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        )
                      else
                        Text(
                          '${widget.isEnglish ? 'Hires:' : 'จำนวนงาน:'} $totalHiresCompleted',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: customRateController,
                              labelText:
                                  widget.isEnglish
                                      ? 'Price per day'
                                      : 'ราคาต่อวัน',
                              keyboardType: TextInputType.number,
                              enabled: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _saveSkillPrice(skillType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Text(
                              widget.isEnglish ? 'Save' : 'บันทึก',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (isPriceExceedsLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            widget.isEnglish
                                ? 'Price exceeds the maximum limit of ${maxDailyLimit!.toStringAsFixed(2)} THB.'
                                : 'ราคาเกินกว่าระดับที่กำหนด ${maxDailyLimit!.toStringAsFixed(2)} บาท',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
