// lib/constants/report_titles.dart

class ReportTitles {
  // Map สำหรับเก็บชื่อรายงานในภาษาอังกฤษ
  static const Map<String, String> englishTitles = {
    'unauthorized_access': 'Unauthorized access to private areas',
    'mishandling_belongings': 'Mishandling of personal belongings',
    'inappropriate_behavior': 'Inappropriate behavior with family members',
    'poor_performance': 'Poor work performance',
    'violation_hours': 'Violation of agreed working hours',
    'misuse_equipment': 'Misuse of household equipment',
    'communication_problems': 'Communication problems',
    'other_concerns': 'Other concerns',

    'non_payment_delayed_payment': 'Non-payment or delayed payment',
    'harassment_inappropriate_behavior': 'Harassment or inappropriate behavior',
    'unsafe_working_conditions': 'Unsafe working conditions',
    'job_scope_mismatch': 'Job scope mismatch',
    'false_accusation': 'False accusation',
    'violation_of_terms': 'Violation of terms',
    'other_issues': 'Other issues',
  };

  // Map สำหรับเก็บชื่อรายงานในภาษาไทย
  static const Map<String, String> thaiTitles = {
    'unauthorized_access': 'เข้าถึงพื้นที่ส่วนตัวโดยไม่ได้รับอนุญาต',
    'mishandling_belongings': 'จัดการทรัพย์สินส่วนตัวไม่เหมาะสม',
    'inappropriate_behavior': 'พฤติกรรมไม่เหมาะสมกับสมาชิกในครอบครัว',
    'poor_performance': 'ประสิทธิภาพการทำงานไม่ดี',
    'violation_hours': 'ละเมิดชั่วโมงการทำงานที่ตกลงกัน',
    'misuse_equipment': 'ใช้อุปกรณ์ในบ้านในทางที่ผิด',
    'communication_problems': 'ปัญหาในการสื่อสาร',
    'other_concerns': 'ข้อกังวลอื่นๆ',

    'non_payment_delayed_payment': 'ไม่ชำระเงินหรือชำระเงินล่าช้า',
    'harassment_inappropriate_behavior': 'การล่วงละเมิดหรือพฤติกรรมไม่เหมาะสม',
    'unsafe_working_conditions': 'สภาพการทำงานไม่ปลอดภัย',
    'job_scope_mismatch': 'ขอบเขตงานไม่ตรงกับที่ตกลง',
    'false_accusation': 'การกล่าวหาเท็จ',
    'violation_of_terms': 'การละเมิดเงื่อนไข',
    'other_issues': 'ปัญหาอื่นๆ',
  };

  // เมธอดสำหรับดึงชื่อรายงานตามภาษา
  static String getTitle(String value, bool isEnglish) {
    if (isEnglish) {
      return englishTitles[value] ?? value; // ถ้าไม่พบใน map ให้คืนค่า value เดิม
    } else {
      return thaiTitles[value] ?? value; // ถ้าไม่พบใน map ให้คืนค่า value เดิม
    }
  }
}