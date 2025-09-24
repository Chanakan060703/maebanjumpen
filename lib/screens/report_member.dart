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
  final Hirer? hirerUser;
  final Person? userPerson;

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
  final ReportController _reportController = ReportController();

  bool _isReported = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Check if the hire object already has a report attached
    _isReported = widget.hire.report != null;

    if (_isReported) {
      _selectedIssue = widget.hire.report!.reportTitle;
      _detailsController.text = widget.hire.report!.reportMessage ?? '';
      _dateController.text = _formatDate(
        widget.hire.report!.reportDate ?? DateTime.now(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(
          widget.isEnglish
              ? 'This job has already been reported.'
              : 'งานนี้ถูกรายงานไปแล้ว',
          isSuccess: false,
        );
      });
    } else {
      _dateController.text = _formatDate(DateTime.now());
    }
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_isReported || _isSubmitting) {
      return;
    }

    if (_selectedIssue == null || _dateController.text.isEmpty) {
      _showSnackBar(
        widget.isEnglish
            ? 'Please select an issue type and date.'
            : 'โปรดเลือกประเภทปัญหาและวันที่',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    DateTime? parsedDate;
    try {
      parsedDate =
          widget.isEnglish
              ? DateFormat('MM/dd/yyyy').parseStrict(_dateController.text)
              : DateFormat('dd/MM/yyyy').parseStrict(_dateController.text);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(
        widget.isEnglish
            ? 'Invalid date format. Please select from calendar.'
            : 'รูปแบบวันที่ไม่ถูกต้อง โปรดเลือกจากปฏิทิน',
      );
      return;
    }

    Hirer? reporterHirer = widget.hirerUser;
    if (reporterHirer == null) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(
        widget.isEnglish
            ? 'Reporter (Hirer) information is missing. Cannot submit report.'
            : 'ไม่พบข้อมูลผู้รายงาน (ผู้ว่าจ้าง) ไม่สามารถส่งรายงานได้',
      );
      return;
    }

    Housekeeper? reportedHousekeeper = widget.hire.housekeeper;
    if (reportedHousekeeper == null) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(
        widget.isEnglish
            ? 'Reported Housekeeper information is missing. Cannot submit report.'
            : 'ไม่พบข้อมูลผู้ถูกรายงาน (แม่บ้าน) ไม่สามารถส่งรายงานได้',
      );
      return;
    }

    // IMPORTANT: Add the hire object to the report
    final newReport = Report(
      reportTitle: _selectedIssue,
      reportMessage: _detailsController.text,
      reportDate: parsedDate,
      reportStatus: 'pending',
      reporter: reporterHirer,
      hirer: reporterHirer,
      housekeeper: reportedHousekeeper,
      penalty: null,
      hire: widget.hire, // CRITICAL FIX: Pass the hire object
    );

    try {
      final savedReport = await _reportController.addReport(newReport);
      debugPrint('Report submitted successfully: ${savedReport.toJson()}');

      _showSnackBar(
        widget.isEnglish
            ? 'Report submitted successfully.'
            : 'ส่งรายงานสำเร็จแล้ว',
        isSuccess: true,
      );

      if (mounted) {
        // Pop the current route and return true to indicate success
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');

      String translatedMessage;
      String errorDetails = '';

      // ตรวจสอบว่า error เป็นประเภทที่เรารู้จักหรือไม่
      if (e.toString().contains('409') &&
          e.toString().contains('This job has already been reported')) {
        translatedMessage =
            widget.isEnglish
                ? 'This job has already been reported.'
                : 'งานนี้ถูกรายงานไปแล้ว';
      } else if (e.toString().contains('400')) {
        // ตัวอย่างการจัดการ HTTP 400 Bad Request
        translatedMessage =
            widget.isEnglish
                ? 'Invalid data submitted. Please check the form.'
                : 'ข้อมูลที่ส่งไม่ถูกต้อง โปรดตรวจสอบฟอร์มอีกครั้ง';
      } else if (e.toString().contains('500')) {
        translatedMessage =
            widget.isEnglish
                ? 'You have already reported this item. You cannot report it again.'
                : 'คุณเคยรายงานรายการนี้ไปแล้ว ไม่สามารถรายงานได้อีกครั้ง';
      }else {
        // กรณี error ทั่วไป
        errorDetails =
            e.toString().contains(':')
                ? e.toString().split(':').last.trim()
                : e.toString();
        translatedMessage =
            widget.isEnglish
                ? 'Failed to submit report. Please try again.'
                : 'ส่งรายงานไม่สำเร็จ โปรดลองอีกครั้ง';
      }

      _showSnackBar(translatedMessage, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
            Navigator.pop(context, false);
          },
        ),
        title: Text(
          _isReported
              ? (widget.isEnglish ? 'Report Submitted' : 'รายงานที่ส่งแล้ว')
              : (widget.isEnglish ? 'Report Housekeeper' : 'รายงานแม่บ้าน'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body:
          _isReported
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.isEnglish
                        ? 'This job has already been reported. You cannot submit a new report.'
                        : 'งานนี้ถูกรายงานไปแล้ว ไม่สามารถส่งรายงานใหม่ได้',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEnglish
                          ? 'Select Issue Type'
                          : 'เลือกประเภทปัญหา',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Unauthorized access to private areas'
                              : 'เข้าถึงพื้นที่ส่วนตัวโดยไม่ได้รับอนุญาต',
                      value: 'unauthorized_access',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Mishandling of personal belongings'
                              : 'จัดการทรัพย์สินส่วนตัวไม่เหมาะสม',
                      value: 'mishandling_belongings',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Inappropriate behavior with family members'
                              : 'พฤติกรรมไม่เหมาะสมกับสมาชิกในครอบครัว',
                      value: 'inappropriate_behavior',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Poor work performance'
                              : 'ประสิทธิภาพการทำงานไม่ดี',
                      value: 'poor_performance',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Violation of agreed working hours'
                              : 'ละเมิดชั่วโมงการทำงานที่ตกลงกัน',
                      value: 'violation_hours',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Misuse of household equipment'
                              : 'ใช้อุปกรณ์ในบ้านในทางที่ผิด',
                      value: 'misuse_equipment',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish
                              ? 'Communication problems'
                              : 'ปัญหาในการสื่อสาร',
                      value: 'communication_problems',
                      groupValue: _selectedIssue,
                      onChanged: _handleIssueSelected,
                    ),
                    _CircularRadioListTile(
                      title:
                          widget.isEnglish ? 'Other concerns' : 'ข้อกังวลอื่นๆ',
                      value: 'other_concerns',
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
                        hintText:
                            widget.isEnglish ? 'mm/dd/yyyy' : 'วว/ดด/ปปปป',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.isEnglish
                          ? 'Additional Details'
                          : 'รายละเอียดเพิ่มเติม',
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
                        hintText:
                            widget.isEnglish
                                ? 'Please provide any additional details about the incident...'
                                : 'โปรดระบุรายละเอียดเพิ่มเติมเกี่ยวกับเหตุการณ์...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isSubmitting ? Colors.grey : Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  widget.isEnglish
                                      ? 'Submit Report'
                                      : 'ส่งรายงาน',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                  ),
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
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
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
