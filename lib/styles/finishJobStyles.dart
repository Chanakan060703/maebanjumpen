// lib/styles/finishJobStyles.dart
import 'package:flutter/material.dart';
// สำหรับ DateFormat ใน AppLocalizations

/// คลาสสำหรับกำหนดสีต่างๆ ที่ใช้ในแอปพลิเคชัน
class AppColors {
  static const Color primaryRed = Colors.red;
  static const Color primaryGreen = Colors.green;
  static const Color greyText = Colors.grey;
  static const Color lightGreyBorder = Color(0xFFE0E0E0);
  static const Color lightRedBackground = Color(0xFFFFEBEE);
  static const Color blackText = Colors.black;
  static const Color lightBlackText = Colors.black87;
  static const Color white = Colors.white;
  static const Color lightGreyBackground = Color(0xFFF5F5F5); // Added for image placeholder
}

/// คลาสสำหรับกำหนดระยะห่างและขนาดต่างๆ ที่ใช้ในแอปพลิเคชัน
class AppSpacings {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double avatarRadius = 30.0;
  static const double dialogBorderRadius = 15.0;
  static const double buttonBorderRadius = 8.0;
  static const double borderRadius = 8.0; // Added for image corners
}

/// คลาสสำหรับกำหนดสไตล์ข้อความต่างๆ ที่ใช้ในแอปพลิเคชัน
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.blackText,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle housekeeperName = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle jobDetails = TextStyle(
    fontSize: 14.0,
    color: AppColors.greyText,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle price = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle serviceItem = TextStyle(color: AppColors.lightBlackText);
  static const TextStyle buttonTextWhite = TextStyle(color: AppColors.white, fontSize: 16.0);
  static const TextStyle dialogTitle = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
  static const TextStyle dialogMessage = TextStyle(fontSize: 14.0, color: AppColors.greyText);
  static const TextStyle dialogButtonTextBlack = TextStyle(color: AppColors.lightBlackText);
}

/// คลาสสำหรับจัดการข้อความที่ใช้ในการแปลภาษา (localization)
/// ขึ้นอยู่กับค่า isEnglish ว่าจะเป็นภาษาอังกฤษหรือภาษาไทย
class AppLocalizations {
  final bool isEnglish;

  AppLocalizations(this.isEnglish);

  String getAppBarTitle() => isEnglish ? 'Job Verification' : 'ตรวจสอบงาน';
  String getServiceDetailsTitle() => isEnglish ? 'Service Details' : 'รายละเอียดบริการ';
  String getHoursText(double hours) => isEnglish ? '${hours.toStringAsFixed(0)} hours' : '${hours.toStringAsFixed(0)} ชั่วโมง';
  String getServiceIncludesTitle() => isEnglish ? 'Service Includes' : 'บริการที่รวม';
  String getConfirmFinishJobButton() => isEnglish ? 'Confirm Finish Job' : 'ยืนยันการจบงาน';
  String getConfirmFinishJobDialogTitle() => isEnglish ? 'Confirm Finish Job' : 'ยืนยันการจบงาน';
  String getConfirmFinishJobDialogMessage() => isEnglish ? 'Are you sure you want to\nConfirm Finish Job Housekeeper ?' : 'คุณแน่ใจหรือไม่ว่าต้องการ\nยืนยันการจบงานแม่บ้าน?';
  String getCancelButton() => isEnglish ? 'Cancel' : 'ยกเลิก';
  String getConfirmButton() => isEnglish ? 'Confirm' : 'ยืนยัน';
  String getUnknownHousekeeper() => isEnglish ? 'Unknown Housekeeper' : 'แม่บ้านไม่ระบุชื่อ';
  String getJobStatusUpdatedSuccess() => isEnglish ? 'Job status updated to Completed!' : 'สถานะงานถูกอัปเดตเป็นเสร็จสิ้นแล้ว!';
  String getJobStatusUpdateFailed() => isEnglish ? 'Failed to update job status.' : 'ไม่สามารถอัปเดตสถานะงานได้';
  String getTryAgainLater() => isEnglish ? 'Please try again later.' : 'กรุณาลองอีกครั้งในภายหลัง';
  String getPleaseLoginMessage() => isEnglish ? 'Please login to access this feature.' : 'กรุณาเข้าสู่ระบบเพื่อเข้าใช้งานฟังก์ชันนี้';

  // --- NEW LOCALIZATION STRINGS ---
  String getWorkProgressPhotosTitle() => isEnglish ? 'Work Progress Photos' : 'รูปภาพความคืบหน้าของงาน';
  String getJobCompletedButton() => isEnglish ? 'Job Completed' : 'งานเสร็จสมบูรณ์แล้ว';

  String getMonthName(int month) {
    if (isEnglish) {
      const monthNamesEn = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return monthNamesEn[month - 1];
    } else {
      const monthNamesTh = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return monthNamesTh[month - 1];
    }
  }

  String getHomeLabel() => isEnglish ? 'Home' : 'หน้าหลัก';
  String getCardsLabel() => isEnglish ? 'Cards' : 'บัตร';
  String getBookingsLabel() => isEnglish ? 'Bookings' : 'การจ้าง';
  String getProfileLabel() => isEnglish ? 'Profile' : 'โปรไฟล์';
}