// lib/screens/penalty_screen.dart

import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/penaltyController.dart';
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/report.dart'; // นำเข้า Report model
import 'package:maebanjumpen/model/penalty.dart'; // นำเข้า Penalty model
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/home_admin.dart'; // <--- สำคัญ: นำเข้าแพ็กเกจ intl

class PenaltyScreen extends StatefulWidget {
  final Report report; // เพิ่มส่วนนี้เพื่อรับ Object รายงาน
  final bool isEnglish; // เพิ่มตัวแปร isEnglish

  const PenaltyScreen({
    super.key,
    required this.report, // ทำให้เป็น Required
    required this.isEnglish, // ทำให้เป็น Required
  });

  @override
  State<PenaltyScreen> createState() => _PenaltyScreenState();
}

class _PenaltyScreenState extends State<PenaltyScreen> {
  String? _selectedPenaltyType;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  DateTime? _selectedPenaltyDate;

  final Penaltycontroller _penaltyController = Penaltycontroller();
  final ReportController _reportController = ReportController();

  @override
  void initState() {
    super.initState();
    // ใช้ isEnglish เพื่อกำหนด Locale สำหรับ DateFormat
    final String localeCode = widget.isEnglish ? 'en_US' : 'th_TH';

    // กรอกวันที่ล่วงหน้าหากมีบทลงโทษอยู่แล้วในรายงาน
    if (widget.report.penalty?.penaltyDate != null) {
      _selectedPenaltyDate = widget.report.penalty!.penaltyDate;
      // ใช้ DateFormat ในการแสดงวันที่ตาม Locale ที่เลือก
      _dateController.text = DateFormat(
        'dd/MM/yyyy',
        localeCode,
      ).format(_selectedPenaltyDate!);
    }
    // กรอกประเภทบทลงโทษและรายละเอียดล่วงหน้าหากมี
    _selectedPenaltyType = widget.report.penalty?.penaltyType;
    _detailsController.text = widget.report.penalty?.penaltyDetail ?? '';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // ใช้ isEnglish เพื่อกำหนด Locale สำหรับ DatePicker
    final Locale currentLocale =
        widget.isEnglish ? const Locale('en', 'US') : const Locale('th', 'TH');

    // ใช้ _selectedPenaltyDate เป็น initialDate
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPenaltyDate ?? DateTime.now(),
      firstDate: DateTime(2000), // กำหนด firstDate ให้เหมาะสม
      lastDate: DateTime(
        2101,
      ), // กำหนด lastDate ให้เหมาะสม (ปี 2101 ก็คือ 2644 พ.ศ.)
      locale: currentLocale, // กำหนด Locale ตาม isEnglish
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // สีหลักของ DatePicker (ส่วนหัว)
              onPrimary: Colors.white, // สีข้อความบนสีหลัก
              onSurface: Colors.black, // สีข้อความบนพื้นผิว (วันที่/เดือน/ปี)
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // สีข้อความปุ่ม (CANCEL, OK)
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedPenaltyDate) {
      setState(() {
        _selectedPenaltyDate = picked;
        // จัดรูปแบบวันที่โดยใช้ Locale ตาม isEnglish
        _dateController.text = DateFormat(
          'dd/MM/yyyy',
          currentLocale.toLanguageTag(), // ใช้ toLanguageTag()
        ).format(picked);
      });
    }
  }

  Future<void> _submitPenalty() async {
    if (_selectedPenaltyType == null ||
        _dateController.text.isEmpty ||
        _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Please fill in all penalty details.'
                : 'กรุณากรอกข้อมูลบทลงโทษให้ครบถ้วน',
          ),
        ),
      );
      return;
    }

    // วันที่ที่ใช้ส่งไป Backend ควรเป็นคริสต์ศักราช
    DateTime? penaltyDateForBackend = _selectedPenaltyDate;

    if (penaltyDateForBackend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'No valid date selected.'
                : 'ไม่ได้เลือกวันที่ที่ถูกต้อง',
          ),
        ),
      );
      return;
    }

    try {
      // 1. สร้าง Object Penalty ใหม่เพื่อส่งไปยัง Backend
      final penaltyToCreate = Penalty(
        penaltyType: _selectedPenaltyType,
        penaltyDetail: _detailsController.text,
        penaltyDate: penaltyDateForBackend, // ใช้ DateTime ที่เป็นคริสต์ศักราช
        penaltyStatus: 'อนุมัติ', // ตั้งสถานะบทลงโทษเป็น อนุมัติ
      );

      print('กำลังพยายามเพิ่มบทลงโทษไปยัง Backend...');
      final createdPenalty = await _penaltyController.addPenalty(
        penaltyToCreate, // ส่ง Penalty object
        widget.report.reportId!.toString(),
        widget.report.hirer?.id?.toString() ??
            '', // ส่ง ID ผู้จ้างเป็น String (แก้ไขให้ไม่เป็น null)
        widget.report.housekeeper?.id?.toString() ??
            '', // ส่ง ID แม่บ้านเป็น String (แก้ไขให้ไม่เป็น null)
      );

      print(
        'สร้างบทลงโทษบน Backend สำเร็จด้วย ID: ${createdPenalty.penaltyId}',
      );

      final updatedReport = Report(
        reportId: widget.report.reportId,
        reportTitle: widget.report.reportTitle,
        reportMessage: widget.report.reportMessage,
        reportDate: widget.report.reportDate,
        reportStatus:
            'resolved', // ตั้งสถานะรายงานเป็น 'resolved' หลังจากใช้บทลงโทษ
        reporter: widget.report.reporter,
        hirer: widget.report.hirer,
        housekeeper: widget.report.housekeeper,
        penalty: createdPenalty, // กำหนดบทลงโทษที่สร้างขึ้นใหม่ (พร้อม ID)
      );

      print(
        'กำลังพยายามอัปเดตสถานะรายงานเป็น resolved และเชื่อมโยง Penalty ID: ${createdPenalty.penaltyId}',
      );
      // 4. อัปเดตรายงานบน Backend
      // ใช้ลายเซ็น updateReport(int id, Report report) ของ ReportController
      final resultReport = await _reportController.updateReport(
        widget.report.reportId!,
        updatedReport,
      );

      // ตรวจสอบว่าการอัปเดตสำเร็จหรือไม่โดยการยืนยัน Object Report ที่คืนมา
      if (resultReport.reportId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Penalty submitted and report updated successfully!'
                  : 'ส่งบทลงโทษและอัปเดตรายงานสำเร็จ!',
            ),
          ),
        );
        // ไปหน้า HomeAdminPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeAdminPage(
                  user: Admin(),
                ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to update report after applying penalty.'
                  : 'ไม่สามารถอัปเดตรายงานหลังจากใช้บทลงโทษได้',
            ),
          ),
        );
      }
    } catch (e) {
      print("Error submitting penalty: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Error submitting penalty: ${e.toString()}'
                : 'เกิดข้อผิดพลาดในการส่งบทลงโทษ: ${e.toString()}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // สีพื้นหลังอ่อนๆ
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // ตัวอย่าง: ปิดหน้าปัจจุบัน
          },
        ),
        title: Text(
          widget.isEnglish ? 'Penalty' : 'บทลงโทษ', // ชื่อ Title
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงชื่อบุคคลที่ถูกรายงานที่ด้านบน
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  widget.isEnglish
                      ? 'Applying penalty to: ${widget.report.hirer?.person?.firstName ?? widget.report.housekeeper?.person?.firstName ?? 'N/A'} ${widget.report.hirer?.person?.lastName ?? widget.report.housekeeper?.person?.lastName ?? ''}'
                      : 'กำลังใช้บทลงโทษกับ: ${widget.report.hirer?.person?.firstName ?? widget.report.housekeeper?.person?.firstName ?? 'ไม่ระบุ'} ${widget.report.hirer?.person?.lastName ?? widget.report.housekeeper?.person?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // ส่วนเลือกประเภทบทลงโทษ
            Text(
              widget.isEnglish
                  ? 'Select Penalty Type'
                  : 'เลือกประเภทบทลงโทษ', // หัวข้อ
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      widget.isEnglish ? 'Ban' : 'แบน',
                    ), // "Ban" in Thai
                    value: 'Ban',
                    groupValue: _selectedPenaltyType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPenaltyType = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      widget.isEnglish ? 'Account Suspension' : 'ระงับบัญชี',
                    ), // "Suspension of account" in Thai
                    value: 'Suspension of account',
                    groupValue: _selectedPenaltyType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPenaltyType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ช่องกรอกวันที่บทลงโทษ
            Text(
              widget.isEnglish ? 'Penalty Date' : 'วันที่ลงโทษ', // หัวข้อ
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            // <--- เปลี่ยนจาก GestureDetector ครอบ TextField เป็น TextField ที่มี onTap โดยตรง
            TextField(
              controller: _dateController,
              readOnly: true, // ทำให้ TextField ไม่สามารถแก้ไขได้โดยตรง
              onTap: () => _selectDate(context), // <--- เพิ่ม onTap ตรงนี้
              decoration: InputDecoration(
                hintText:
                    widget.isEnglish
                        ? 'DD/MM/YYYY (AD)'
                        : 'วว/ดด/ปปปป (พ.ศ.)', // รูปแบบวันที่ DD/MM/YYYY (พ.ศ.)
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // ไม่มีขอบ
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ช่องกรอกรายละเอียดบทลงโทษ
            Text(
              widget.isEnglish
                  ? 'Penalty Details'
                  : 'รายละเอียดบทลงโทษ', // หัวข้อ
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 6, // กำหนดจำนวนบรรทัด
              decoration: InputDecoration(
                hintText:
                    widget.isEnglish
                        ? 'Please provide more details about the incident...'
                        : 'โปรดระบุรายละเอียดเพิ่มเติมเกี่ยวกับเหตุการณ์...', // Placeholder text
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // ไม่มีขอบ
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 40), // เพิ่มระยะห่างก่อนปุ่ม
            // ปุ่มส่งบทลงโทษ
            SizedBox(
              width: double.infinity, // ทำให้ปุ่มกว้างเต็มพื้นที่
              height: 50, // กำหนดความสูงของปุ่ม
              child: ElevatedButton(
                onPressed: _submitPenalty, // เรียกใช้เมธอดส่งข้อมูล
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // สีปุ่ม
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // ขอบมน
                  ),
                ),
                child: Text(
                  widget.isEnglish
                      ? 'Submit Penalty'
                      : 'ส่งบทลงโทษ', // ข้อความบนปุ่ม
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // ระยะห่างด้านล่างสุด
          ],
        ),
      ),
    );
  }
}
