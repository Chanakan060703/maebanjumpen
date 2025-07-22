// Ensure Report model is imported

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart';

class ReportHousekeeperPage extends StatefulWidget {
  final Hire hire;
  final bool isEnglish;
  final Hirer? hirerUser; // Pass hirerUser for reporting context
  final Person? userPerson; // Pass userPerson for reporting context (if needed for reporter Person details)

  const ReportHousekeeperPage({
    super.key,
    required this.hire,
    required this.isEnglish,
    this.hirerUser,
    this.userPerson,
  });

  @override
  _ReportHousekeeperPageState createState() => _ReportHousekeeperPageState();
}

class _ReportHousekeeperPageState extends State<ReportHousekeeperPage> {
  String? _selectedIssue;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final ReportController _reportController = ReportController(); // สร้าง instance ของ controller

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  void _handleIssueSelected(String value) {
    setState(() {
      _selectedIssue = value;
    });
    debugPrint('Selected Issue: $_selectedIssue');
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime currentDate = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: currentDate,
    );
    if (picked != null) {
      setState(() {
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_selectedIssue == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Please select an issue and date.'
                : 'โปรดเลือกประเภทปัญหาและวันที่',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    
  DateTime? parsedDate;
  try {
    parsedDate = DateFormat('MM/dd/yyyy').parseStrict(_dateController.text);
  } catch (e) {
    debugPrint('Error parsing date: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Invalid date format. Please select from calendar.'
              : 'รูปแบบวันที่ไม่ถูกต้อง โปรดเลือกจากปฏิทิน',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Hirer? reporterHirer;
  if (widget.hirerUser != null) {
    reporterHirer = Hirer(
      id: widget.hirerUser!.id,
      type: "hirer", // ระบุ type ตรงกับ @JsonTypeInfo DiscriminatorValue
      person: widget.hirerUser!.person, // ส่ง Person object ด้วย
      balance: widget.hirerUser!.balance,
      username: widget.hirerUser!.username,
    );
  }

  Hirer? reportHirer;
  if (widget.hirerUser != null) {
    reportHirer = Hirer(
      id: widget.hirerUser!.id,
      type: "hirer",
      person: widget.hirerUser!.person,
      balance: widget.hirerUser!.balance,
      username: widget.hirerUser!.username,
    );
  }

  Housekeeper? reportHousekeeper;
  if (widget.hire.housekeeper != null) {
    reportHousekeeper = Housekeeper(
      id: widget.hire.housekeeper!.id,
      type: "housekeeper", 
      person: widget.hire.housekeeper!.person,
      username: widget.hire.housekeeper!.username,
      photoVerifyUrl: widget.hire.housekeeper!.photoVerifyUrl,
      statusVerify: widget.hire.housekeeper!.statusVerify,
      rating: widget.hire.housekeeper!.rating,
    );
  }

  final newReport = Report(
    reportTitle: _selectedIssue,
    reportMessage: _detailsController.text,
    reportDate: parsedDate,
    reportStatus: 'pending', // กำหนดสถานะ
    reporter: reporterHirer,
    hirer: reportHirer,
    housekeeper: reportHousekeeper,
    penalty: null, // หรือกำหนดค่าตามความเหมาะสม
  );

  debugPrint('Report object created: ${newReport.toJson()}');

  try {
    // เรียกใช้เมธอด addReport ที่รับ Report object
    final savedReport = await _reportController.addReport(newReport);
    debugPrint('Report submitted successfully: ${savedReport.toJson()}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEnglish
            ? 'Report submitted successfully.'
            : 'ส่งรายงานสำเร็จแล้ว'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, savedReport);
  } catch (e) {
    debugPrint('Error submitting report: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Failed to submit report: ${e.toString().split(':').last.trim()}'
              : 'ส่งรายงานไม่สำเร็จ: ${e.toString().split(':').last.trim()}',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Report Housekeeper' : 'รายงานแม่บ้าน',
          style: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEnglish ? 'Select Issue Type' : 'เลือกประเภทปัญหา',
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Unauthorized access to private areas'
                    : 'เข้าถึงพื้นที่ส่วนตัวโดยไม่ได้รับอนุญาต',
                value: 'unauthorized_access',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Mishandling of personal belongings'
                    : 'จัดการทรัพย์สินส่วนตัวไม่เหมาะสม',
                value: 'mishandling_belongings',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Inappropriate behavior with family members'
                    : 'พฤติกรรมไม่เหมาะสมกับสมาชิกในครอบครัว',
                value: 'inappropriate_behavior',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title:
                    widget.isEnglish ? 'Poor work performance' : 'ประสิทธิภาพการทำงานไม่ดี',
                value: 'poor_performance',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Violation of agreed working hours'
                    : 'ละเมิดชั่วโมงการทำงานที่ตกลงกัน',
                value: 'violation_hours',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Misuse of household equipment'
                    : 'ใช้อุปกรณ์ในบ้านในทางที่ผิด',
                value: 'misuse_equipment',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish
                    ? 'Communication problems'
                    : 'ปัญหาในการสื่อสาร',
                value: 'communication_problems',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            _CircularRadioListTile(
                title: widget.isEnglish ? 'Other concerns' : 'ข้อกังวลอื่นๆ',
                value: 'other_concerns',
                groupValue: _selectedIssue,
                onChanged: _handleIssueSelected),
            const SizedBox(height: 16.0),
            Text(
              widget.isEnglish
                  ? 'Date and Time of Incident'
                  : 'วันที่และเวลาเกิดเหตุ',
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'mm/dd/yyyy' : 'วว/ดด/ปปปป',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              onTap: () => _selectDate(context),
              readOnly: true,
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.isEnglish ? 'Additional Details' : 'รายละเอียดเพิ่มเติม',
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: widget.isEnglish
                    ? 'Please provide any additional details about the incident...'
                    : 'โปรดระบุรายละเอียดเพิ่มเติมเกี่ยวกับเหตุการณ์...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReport, // Call the new submit function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  widget.isEnglish ? 'Submit Report' : 'ส่งรายงาน',
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: Text(
                widget.isEnglish
                    ? 'Your report will be processed within 24-48 hours'
                    : 'รายงานของคุณจะได้รับการดำเนินการภายใน 24-48 ชั่วโมง',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        currentIndex: 2, // Highlight 'Hire' tab
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          // Handle bottom navigation item taps
          // You can add navigation logic here to navigate to respective pages
          debugPrint('Bottom navigation tapped: $index');
        },
      ),
    );
  }
}

// Custom Widget สำหรับ Radio Button วงกลม (เปลี่ยนชื่อจาก Checkbox เพื่อความชัดเจน)
class _CircularRadioListTile extends StatelessWidget {
  final String title;
  final String value;
  final String? groupValue; // Nullable to allow no selection
  final ValueChanged<String> onChanged;

  const _CircularRadioListTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = groupValue == value;
    return InkWell(
      onTap: () {
        onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.red : Colors.grey,
              size: 24.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}