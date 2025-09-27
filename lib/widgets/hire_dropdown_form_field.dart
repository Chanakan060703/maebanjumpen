// lib/widgets/hire_dropdown_form_field.dart
import 'package:flutter/material.dart';
import 'package:maebanjumpen/styles/hire_form_styles.dart';

class HireDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const HireDropdownFormField({
    super.key,
    required this.value,
    required this.labelText,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Label ตัวที่ 1: Text Widget ที่คุณสร้างเอง
        Text(labelText, style: HireFormStyles.labelTextStyle(context)),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<T>(
          value: value,
          decoration: HireFormStyles.inputDecoration(
            // ❌ ลบ hintText ออกจาก Decoration
            // คุณอาจจะส่ง hintText เข้าไปตรงๆ ใน inputDecoration หากต้องการ placeholder
            // แต่ถ้าต้องการให้มันดูสะอาดตาและมี Label อยู่ด้านบนอยู่แล้ว ให้เว้นไว้
          ),
          hint: Text(hintText), // ✅ ใช้ hint แทน hintText ใน decoration
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
