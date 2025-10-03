import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/hireController.dart'; 
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart';

class ReportMemberPage extends StatefulWidget {
  final Hire hire;
  final bool isEnglish;
  final Housekeeper? housekeeper; // Housekeeper is the reporter
  final Person? userPerson; 

  const ReportMemberPage({
    super.key,
    required this.hire,
    required this.isEnglish,
    this.housekeeper,
    this.userPerson,
  });

  @override
  _ReportMemberPageState createState() => _ReportMemberPageState();
}

class _ReportMemberPageState extends State<ReportMemberPage> {
  String? _selectedIssue;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final ReportController _reportController = ReportController();
  final Hirecontroller _hireController = Hirecontroller(); 

  @override
  void initState() {
    super.initState();

    _dateController.text = widget.isEnglish
        ? DateFormat('MM/dd/yyyy').format(DateTime.now())
        : DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return widget.isEnglish
        ? DateFormat('MM/dd/yyyy').format(date)
        : DateFormat('dd/MM/yyyy').format(date);
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
  
  // ✅ แก้ไข: ปรับการเรียก Controller ให้ส่ง ID และ Object (แก้ Type Error)
  Future<void> _updateHireStatusOnReport() async {
    const String newStatus = 'Reported'; 
    
    // ตรวจสอบว่า hireId มีค่าก่อน
    if (widget.hire.hireId == null) {
        debugPrint('Cannot update hire status: hireId is null.');
        return;
    }

    final Hire updatedHire = widget.hire.copyWith(
      jobStatus: newStatus,
    );
    
    try {
      // 🎯 แก้ไข: ส่ง hireId (int) และ updatedHire (Hire)
      await _hireController.updateHire(widget.hire.hireId!, updatedHire); 
      debugPrint('Hire status updated successfully to $newStatus.');
    } catch (e) {
      debugPrint('Error updating hire status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Warning: Failed to update job status after report.'
                : 'คำเตือน: ไม่สามารถอัปเดตสถานะงานจ้างหลังรายงานได้',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  Future<void> _submitReport() async {
    // 1. ตรวจสอบข้อมูลที่จำเป็น
    if (_selectedIssue == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Please select an issue type and date.'
                : 'โปรดเลือกประเภทปัญหาและวันที่',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. แปลงวันที่จาก String เป็น DateTime
    DateTime? parsedDate;
    try {
      parsedDate = widget.isEnglish
          ? DateFormat('MM/dd/yyyy').parseStrict(_dateController.text)
          : DateFormat('dd/MM/yyyy').parseStrict(_dateController.text);
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

    // 3. เตรียม Reporter Object (Housekeeper)
    final Housekeeper? reporterHousekeeper = widget.housekeeper;
    if (reporterHousekeeper == null || reporterHousekeeper.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Reporter (Housekeeper) information is missing or invalid. Cannot submit report.'
                : 'ไม่พบข้อมูลผู้รายงาน (แม่บ้าน) หรือข้อมูลไม่ถูกต้อง ไม่สามารถส่งรายงานได้',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 4. เตรียม Hirer Object (ผู้ถูกรายงาน)
    final Hirer? reportedHirer = widget.hire.hirer as Hirer?;
    if (reportedHirer == null || reportedHirer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Reported Hirer information is missing or invalid. Cannot submit report.'
                : 'ไม่พบข้อมูลผู้ถูกรายงาน (ผู้ว่าจ้าง) หรือข้อมูลไม่ถูกต้อง ไม่สามารถส่งรายงานได้',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5. สร้าง Report Object
    final newReport = Report(
      reportTitle: _selectedIssue,
      reportMessage: _detailsController.text,
      reportDate: parsedDate,
      reportStatus: 'pending', 
      hireId: widget.hire.hireId, 
      reporter: reporterHousekeeper, 
      housekeeper: reporterHousekeeper, 
      hirer: reportedHirer, 
      penalty: null, 
    );

    // 6. ส่ง Report ไปยัง Backend
    try {
      final savedReport = await _reportController.addReport(newReport);

      debugPrint('Report submitted successfully: ${savedReport.toJson()}');
      
      // 7. อัปเดตสถานะงานจ้างหลังจากส่งรายงานสำเร็จ
      await _updateHireStatusOnReport(); 

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Report submitted successfully. Job status updated.'
                : 'ส่งรายงานสำเร็จแล้ว และอัปเดตสถานะงานจ้างแล้ว',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // 8. กลับไปยังหน้าจอก่อนหน้า พร้อมส่ง 'true' กลับไปเพื่อบอกให้หน้า Job History รีเฟรช
      Navigator.pop(context, true); 
    } catch (e) {
      debugPrint('Error submitting report: $e');

      // แสดงข้อความผิดพลาด
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
            // เมื่อกดกลับ ให้ส่งค่า false กลับไป
            Navigator.pop(context, false); 
          },
        ),
        title: Text(
          widget.isEnglish ? 'Report Hirer' : 'รายงานผู้ว่าจ้าง',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEnglish ? 'Select Issue Type' : 'เลือกประเภทปัญหา',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            _CircularRadioListTile(
              title: widget.isEnglish
                  ? 'Non-payment or delayed payment'
                  : 'ไม่ชำระเงินหรือชำระล่าช้า',
              value: 'non_payment_delayed_payment',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish
                  ? 'Harassment or inappropriate behavior'
                  : 'การคุกคามหรือพฤติกรรมไม่เหมาะสม',
              value: 'harassment_inappropriate_behavior',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish
                  ? 'Unsafe working conditions'
                  : 'สภาพแวดล้อมการทำงานไม่ปลอดภัย',
              value: 'unsafe_working_conditions',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish
                  ? 'Job scope mismatch'
                  : 'ขอบเขตงานไม่ตรงตามที่ตกลง',
              value: 'job_scope_mismatch',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish ? 'False accusation' : 'การกล่าวหาเท็จ',
              value: 'false_accusation',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish ? 'Violation of terms' : 'การละเมิดข้อตกลง',
              value: 'violation_of_terms',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            _CircularRadioListTile(
              title: widget.isEnglish ? 'Other issues' : 'ปัญหาอื่นๆ',
              value: 'other_issues',
              groupValue: _selectedIssue,
              onChanged: _handleIssueSelected,
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.isEnglish
                  ? 'Date and Time of Incident'
                  : 'วันที่และเวลาเกิดเหตุ',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'MM/DD/YYYY' : 'วว/ดด/ปปปป',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
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
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
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
                  borderRadius: BorderRadius.circular(15.0),
                ),
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
                onPressed: _submitReport, 
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
        currentIndex: 2, 
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          debugPrint('Bottom navigation tapped: $index');
        },
      ),
    );
  }
}

// Custom Widget สำหรับ Radio Button วงกลม (ไม่ได้เปลี่ยนแปลง)
class _CircularRadioListTile extends StatelessWidget {
  final String title;
  final String value;
  final String? groupValue; 
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