// lib/styles/hire_form_styles.dart
import 'package:flutter/material.dart';

class SkillTranslator {
  // Map ชื่อทักษะ (จาก backend ที่เป็นภาษาอังกฤษ) ไปยังไอคอนและชื่อภาษาไทย
  static final Map<String, Map<String, dynamic>> _skillDetails = {
    'General Cleaning': {'icon': Icons.cleaning_services, 'thaiName': 'ทำความสะอาดทั่วไป'},
    'Laundry': {'icon': Icons.local_laundry_service, 'thaiName': 'ซักรีด'},
    'Cooking': {'icon': Icons.restaurant, 'thaiName': 'ทำอาหาร'},
    'Garden': {'icon': Icons.local_florist, 'thaiName': 'ดูแลสวน'},
    'Pet Care': {'icon': Icons.pets, 'thaiName': 'ดูแลสัตว์เลี้ยง'},
    'Window Cleaning': {'icon': Icons.window, 'thaiName': 'ทำความสะอาดหน้าต่าง'},
    'Organization': {'icon': Icons.category, 'thaiName': 'จัดระเบียบ'},
    // เพิ่มทักษะอื่นๆ ที่มีในระบบของคุณที่นี่
  };

  // ดึงชื่อทักษะที่แปลแล้ว
  static String getLocalizedSkillName(String? skillTypeName, bool isEnglish) {
    if (skillTypeName == null || skillTypeName.isEmpty) {
      return isEnglish ? 'Unknown Skill' : 'ทักษะไม่ระบุ';
    }
    final detail = _skillDetails[skillTypeName];
    if (detail != null) {
      return isEnglish ? skillTypeName : detail['thaiName']!;
    } else {
      // ถ้าไม่พบใน map ให้คืนค่าเดิมกลับไป
      return skillTypeName;
    }
  }

  // ดึงไอคอนสำหรับทักษะ
  static IconData getSkillIcon(String? skillTypeName) {
    if (skillTypeName == null || skillTypeName.isEmpty) {
      return Icons.help_outline; // ไอคอนเริ่มต้นถ้าไม่พบ
    }
    final detail = _skillDetails[skillTypeName];
    return detail?['icon'] ?? Icons.help_outline;
  }

  // ดึงรายการทักษะทั้งหมด (ชื่อภาษาอังกฤษ)
  static List<String> getAllSkillNames() {
    return _skillDetails.keys.toList();
  }
}

class HireFormStyles {
  // สไตล์สำหรับหัวข้อฟอร์ม
  static TextStyle labelTextStyle(BuildContext context) {
    return TextStyle(fontSize: 16.0, color: Colors.grey[600]);
  }

  // Input Decoration สำหรับ TextFormField และ DropdownButtonFormField
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    bool isFocused = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red), // สีแดงเมื่อ focus
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
    );
  }

  // สไตล์สำหรับข้อความแสดงยอดรวมการชำระเงิน
  static TextStyle totalPaymentAmountStyle = const TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );

  // สไตล์สำหรับข้อความรายละเอียดราคา (เช่น base rate, additional service)
  static TextStyle priceDetailTextStyle = TextStyle(
    fontSize: 12.0,
    color: Colors.grey[600],
  );

  // สไตล์สำหรับข้อความในปุ่มยืนยัน
  static TextStyle confirmButtonTextStyle = const TextStyle(
    fontSize: 18.0,
    color: Colors.white,
  );

  // สไตล์สำหรับปุ่มยืนยัน
  static ButtonStyle confirmButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // สไตล์สำหรับปุ่มยกเลิกใน Dialog
  static ButtonStyle cancelButtonDialogStyle = OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.grey),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 12.0,
    ),
  );

  // สไตล์ข้อความสำหรับปุ่มยกเลิกใน Dialog
  static TextStyle cancelButtonDialogTextStyle = const TextStyle(color: Colors.grey);

  // สไตล์สำหรับปุ่มยืนยันใน Dialog
  static ButtonStyle confirmButtonDialogStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 12.0,
    ),
  );

  // สไตล์ข้อความสำหรับปุ่มยืนยันใน Dialog
  static TextStyle confirmButtonDialogTextStyle = const TextStyle(color: Colors.white);
}

class HireCheckboxListTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color activeColor;

  const HireCheckboxListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class HireTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String hintText;
  final bool enabled;
  final TextInputType keyboardType;
  final int maxLines;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;

  const HireTextFormField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.hintText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onTap,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: HireFormStyles.labelTextStyle(context),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onTap: onTap,
          readOnly: readOnly,
          decoration: HireFormStyles.inputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            isFocused: focusNode?.hasFocus ?? false,
          ),
          validator: validator,
        ),
      ],
    );
  }
}




