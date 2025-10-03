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
import 'package:maebanjumpen/styles/finishJobStyles.dart';

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
  final TextEditingController _baseDailyRateDisplayController =
      TextEditingController();
  List<SkillType> _availableSkillTypes = [];
  List<SkillLevelTier> _availableSkillLevelTiers = [];
  final Map<SkillType, int?> _selectedSkillLevelTierId = {};
  final Map<SkillType, TextEditingController> _customDailyRateControllers = {};
  List<HousekeeperSkill> _initialHousekeeperSkills = [];
  bool _isLoading = false;
  XFile? _pickedImageFile;
  String? _currentProfilePictureUrl;

  // Assumed Controllers/Services Instantiation
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _baseDailyRateDisplayController.dispose();
    _customDailyRateControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // 🚩 แก้ไข: Logic ต้องถูกกำหนดใน _initializeControllers() เพื่อให้แสดงผลในตอนโหลด
  void _initializeControllers() {
    _firstNameController.text = widget.user.person?.firstName ?? '';
    _lastNameController.text = widget.user.person?.lastName ?? '';
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    _addressController.text = widget.user.person?.address ?? '';
    _emailController.text = widget.user.person?.email ?? '';

    // 🟢 Fix: ตั้งค่าให้แสดงผล Base Daily Rate ที่โหลดมา (คาดว่าเป็น String Range)
    _baseDailyRateDisplayController.text =
        widget.user.dailyRate?.isNotEmpty == true
            ? widget.user.dailyRate!
            : '0.00 - 0.00'; // ให้แสดงเป็น range ตั้งแต่ต้น

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
      // 🟢 Fix: Add mounted check
      if (!mounted) return;
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
    // Return the lowest tier (Beginner) if no hires completed
    return _availableSkillLevelTiers.firstWhere(
      (tier) => tier.minHiresForLevel == 0,
      orElse: () => SkillLevelTier(),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // 🟢 Fix: Add mounted check
      if (!mounted) return;
      setState(() => _pickedImageFile = image);
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // --- Upload Image & Update Person ---
      String? newProfileUrl = _currentProfilePictureUrl;
      if (_pickedImageFile != null && widget.user.person?.personId != null) {
        // 🟢 โค้ดที่เพิ่ม: เรียก service อัปโหลด
        final uploadedUrl = await _imageUploadService.uploadImage(
          id: widget.user.person!.personId!,
          imageType: 'person', // 'person' จะใช้ endpoint สำหรับรูปโปรไฟล์
          imageFile: _pickedImageFile!,
        );
        if (uploadedUrl != null) {
          newProfileUrl = uploadedUrl;
        } else {
          throw Exception(
            widget.isEnglish
                ? 'Failed to upload profile image.'
                : 'ไม่สามารถอัปโหลดรูปโปรไฟล์ได้',
          );
        }
      }

      final updatedPerson = widget.user.person?.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        pictureUrl: newProfileUrl,
      );

      // --- Prepare Skills ---
      final List<HousekeeperSkill> newSelectedSkills = [];
      String? priceErrorSkill;

      for (var entry in _selectedSkillLevelTierId.entries) {
        final skillType = entry.key;
        final tierId = entry.value;
        if (tierId != null) {
          final customPriceController = _customDailyRateControllers[skillType];
          final customPrice = double.tryParse(
            customPriceController?.text ?? '',
          );

          if (customPrice == null) {
            priceErrorSkill =
                widget.isEnglish
                    ? skillType.skillTypeName
                    : _skillThaiNames[skillType.skillTypeName ?? ''];
            throw Exception('Invalid price format for $priceErrorSkill.');
          }

          final existingUserSkill = _initialHousekeeperSkills.firstWhere(
            (userSkill) =>
                userSkill.skillType?.skillTypeId == skillType.skillTypeId,
            orElse: () => HousekeeperSkill(),
          );

          final tier = _availableSkillLevelTiers.firstWhere(
            (t) => t.id == tierId,
            orElse: () => SkillLevelTier(),
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
      }

      // --- Compute dailyRate Min/Max from selected skills ---
      double? minRate;
      double? maxRate;

      for (var skill in newSelectedSkills) {
        if (skill.pricePerDay != null) {
          minRate =
              (minRate == null || skill.pricePerDay! < minRate)
                  ? skill.pricePerDay
                  : minRate;
          maxRate =
              (maxRate == null || skill.pricePerDay! > maxRate)
                  ? skill.pricePerDay
                  : maxRate;
        }
      }

      final String finalDailyRate =
          '${(minRate ?? 0.00).toStringAsFixed(2)} - ${(maxRate ?? 0.00).toStringAsFixed(2)}';

      // --- Update Housekeeper ---
      final updatedHousekeeper = widget.user.copyWith(
        person: updatedPerson,
        dailyRate: finalDailyRate,
        housekeeperSkills: newSelectedSkills,
      );

      if (updatedHousekeeper.id != null) {
        await HousekeeperController().updateHousekeeper(
          updatedHousekeeper.id!,
          updatedHousekeeper,
        );
      }

      if (!mounted) return;
      _showSuccessSnackBar(
        widget.isEnglish
            ? 'Profile updated successfully!'
            : 'แก้ไขโปรไฟล์สำเร็จ!',
      );
      Navigator.pop(context, updatedHousekeeper);
    } catch (e) {
      print('Save profile error: $e');
      final errorMessage = e.toString().split(':').last.trim();

      if (!mounted) return;
      _showErrorSnackBar(
        widget.isEnglish
            ? 'Failed to update profile: $errorMessage'
            : 'ไม่สามารถอัปเดตโปรไฟล์ได้: $errorMessage',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSkillPrice(SkillType skillType) async {
    // 🟢 Fix: Add mounted check before calling setState()
    if (!mounted) return;
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
      final tier = _getSkillLevelTier(
        existingUserSkill.totalHiresCompleted ?? 0,
      );
      final tierId = tier.id;

      if (tierId == null) {
        throw Exception(
          widget.isEnglish ? 'Skill level tier not found.' : 'ไม่พบระดับทักษะ',
        );
      }
      // --- Min/Max Rate Validation ---
      final double? minDailyLimit =
          (tier.minPricePerHourLimit != null)
              ? tier.minPricePerHourLimit! * 8
              : null;
      final double? maxDailyLimit =
          (tier.maxPricePerHourLimit != null)
              ? tier.maxPricePerHourLimit! * 8
              : null;
      if (maxDailyLimit != null && customPrice > maxDailyLimit) {
        throw Exception(
          'Price for ${widget.isEnglish ? skillType.skillTypeName : _skillThaiNames[skillType.skillTypeName ?? '']} exceeds the maximum limit of ${maxDailyLimit.toStringAsFixed(2)} THB.',
        );
      }
      if (minDailyLimit != null && customPrice < minDailyLimit) {
        throw Exception(
          'Price for ${widget.isEnglish ? skillType.skillTypeName : _skillThaiNames[skillType.skillTypeName ?? '']} is lower than the minimum limit of ${minDailyLimit.toStringAsFixed(2)} THB.',
        );
      }
      // ---------------------------------

      // Update the text field to reflect the saved format
      customPriceController?.text = customPrice.toStringAsFixed(2);
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

      // 🟢 Fix: Add mounted check before showing SnackBar
      if (!mounted) return;
      _showSuccessSnackBar(
        widget.isEnglish ? 'Price saved successfully!' : 'บันทึกราคาสำเร็จ!',
      );

      // Re-fetch/update local skills list to reflect changes if necessary
      await _fetchAndInitializeSkills();
    } catch (e) {
      print('Save skill price error: $e');
      final errorMessage = e.toString().split(':').last.trim();

      // 🟢 Fix: Add mounted check before showing SnackBar
      if (!mounted) return;
      _showErrorSnackBar(
        widget.isEnglish
            ? 'Failed to save price: $errorMessage'
            : 'ไม่สามารถบันทึกราคาได้: $errorMessage',
      );
    } finally {
      // 🟢 Fix: Add mounted check before calling setState()
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        // ⭐️ เพิ่ม leadingWidth เพื่อขยายพื้นที่สำหรับปุ่ม Cancel
        leadingWidth: 80.0,
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
              : RefreshIndicator( // 🟢 1. เพิ่ม RefreshIndicator
                  onRefresh: _fetchAndInitializeSkills, // 🟢 2. กำหนดให้เรียกฟังก์ชันโหลดข้อมูล
                  color: Colors.red, // สีของวงกลมโหลด
                  child: SingleChildScrollView(
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
                    // ช่อง Daily Rate ฐาน (Read-Only)
                    _buildTextField(
                      controller: _baseDailyRateDisplayController,
                      labelText:
                          widget.isEnglish
                              ? 'Base Daily Rate (Read-Only)'
                              : 'อัตราค่าบริการรายวัน (ฐาน - อ่านอย่างเดียว)',
                      keyboardType: TextInputType.none,
                      enabled:
                          false, // ปิดการแก้ไข แต่ค่าใน Controller ถูกใช้ในการบันทึก
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
                  ? (skillType.skillTypeName ?? '')
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

          final nextTier = _availableSkillLevelTiers.firstWhere(
            (tier) =>
                (tier.minHiresForLevel ?? 0) >
                (currentTier.minHiresForLevel ?? 0),
            orElse: () => SkillLevelTier(minHiresForLevel: null),
          );

          // 🚩 รองรับ null limit
          final double? minDailyLimit =
              currentTier.minPricePerHourLimit != null
                  ? currentTier.minPricePerHourLimit! * 8
                  : null;
          final double? maxDailyLimit =
              currentTier.maxPricePerHourLimit != null
                  ? currentTier.maxPricePerHourLimit! * 8
                  : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(displayName, style: const TextStyle(fontSize: 16)),
                // 🟢 เพิ่ม/แก้ไข 2 บรรทัดนี้
                activeColor:
                    AppColors
                        .primaryRed, // สีเมื่อ Checkbox ถูกเลือก (ตัวกล่อง)
                checkColor: Colors.white, // สีของเครื่องหมายถูก
                value: isSelected,
                onChanged: (bool? newValue) {
                  if (!mounted) return;
                  setState(() {
                    if (newValue == true) {
                      _selectedSkillLevelTierId[skillType] = currentTier.id;
                      // ตั้งค่า default เป็น minLimit ถ้ามี ไม่งั้น 0.00
                      customRateController?.text = (minDailyLimit ?? 0.0)
                          .toStringAsFixed(2);
                    } else {
                      _selectedSkillLevelTierId.remove(skillType);
                    }
                  });
                },
              ),

              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skill Level
                      Text(
                        'Skill Level: ${currentTier.skillLevelName ?? (widget.isEnglish ? "Unknown" : "ไม่ทราบ")}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Progress
                      Text(
                        'Hires: $totalHiresCompleted / ${nextTier.minHiresForLevel ?? (widget.isEnglish ? "Max" : "สูงสุด")}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (nextTier.minHiresForLevel != null)
                        LinearProgressIndicator(
                          value:
                              totalHiresCompleted /
                              (nextTier.minHiresForLevel!),
                          color: Colors.red,
                          backgroundColor: Colors.red.shade100,
                        ),
                      if (nextTier.minHiresForLevel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            widget.isEnglish
                                ? 'Complete ${nextTier.minHiresForLevel! - totalHiresCompleted} more hires to become ${nextTier.skillLevelName}!'
                                : 'ทำงานเพิ่มอีก ${nextTier.minHiresForLevel! - totalHiresCompleted} ครั้งเพื่อเลื่อนไป ${nextTier.skillLevelName}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Limit Display
                      Text(
                        widget.isEnglish
                            ? 'Min/Max Daily Rate: '
                                '${minDailyLimit?.toStringAsFixed(2) ?? "No Min"}'
                                ' - '
                                '${maxDailyLimit?.toStringAsFixed(2) ?? "No Max"} THB'
                            : 'อัตราค่าบริการรายวันขั้นต่ำ/สูงสุด: '
                                '${minDailyLimit?.toStringAsFixed(2) ?? "ไม่จำกัด"}'
                                ' - '
                                '${maxDailyLimit?.toStringAsFixed(2) ?? "ไม่จำกัด"} บาท',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Input for Price
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customRateController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    widget.isEnglish
                                        ? 'Custom Daily Rate (THB)'
                                        : 'กำหนดราคา (บาท)',
                                border: const OutlineInputBorder(),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _saveSkillPrice(skillType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text(
                              widget.isEnglish ? 'Save' : 'บันทึก',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
