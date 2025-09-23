import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/penaltyController.dart';
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/model/penalty.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/home_admin.dart';
import 'package:maebanjumpen/model/person.dart';

class PenaltyScreen extends StatefulWidget {
  final Report report;
  final bool isEnglish;

  const PenaltyScreen({
    super.key,
    required this.report,
    required this.isEnglish,
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
    final String localeCode = widget.isEnglish ? 'en_US' : 'th_TH';

    if (widget.report.penalty?.penaltyDate != null) {
      _selectedPenaltyDate = widget.report.penalty!.penaltyDate;
      _dateController.text = DateFormat(
        'dd/MM/yyyy',
        localeCode,
      ).format(_selectedPenaltyDate!);
    }
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
    final Locale currentLocale =
        widget.isEnglish ? const Locale('en', 'US') : const Locale('th', 'TH');

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPenaltyDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(
        2101,
      ),
      locale: currentLocale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
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
        _dateController.text = DateFormat(
          'dd/MM/yyyy',
          currentLocale.toLanguageTag(),
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

    String? reporterId = widget.report.reporter?.id?.toString();
    String? hirerId = widget.report.hirer?.id?.toString();
    String? housekeeperId = widget.report.housekeeper?.id?.toString();

    String? targetHirerId;
    String? targetHousekeeperId;

    if (reporterId == hirerId) {
      targetHousekeeperId = housekeeperId;
    } else if (reporterId == housekeeperId) {
      targetHirerId = hirerId;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Unable to determine the user to apply penalty to.'
                : 'ไม่สามารถระบุผู้ใช้ที่ต้องการลงโทษได้',
          ),
        ),
      );
      return;
    }

    try {
      final penaltyToCreate = Penalty(
        penaltyType: _selectedPenaltyType,
        penaltyDetail: _detailsController.text,
        penaltyDate: penaltyDateForBackend,
        penaltyStatus: 'อนุมัติ',
      );

      print('กำลังพยายามเพิ่มบทลงโทษไปยัง Backend...');
      
      final createdPenalty = await _penaltyController.addPenalty(
        penaltyToCreate,
        widget.report.reportId!.toString(),
        targetHirerId,
        targetHousekeeperId,
      );

      print(
        'สร้างบทลงโทษบน Backend สำเร็จด้วย ID: ${createdPenalty.penaltyId}',
      );

      final updatedReport = Report(
        reportId: widget.report.reportId,
        reportTitle: widget.report.reportTitle,
        reportMessage: widget.report.reportMessage,
        reportDate: widget.report.reportDate,
        reportStatus: 'resolved', 
        reporter: widget.report.reporter,
        hirer: widget.report.hirer,
        housekeeper: widget.report.housekeeper,
        penalty: createdPenalty, 
      );

      print(
        'กำลังพยายามอัปเดตสถานะรายงานเป็น resolved และเชื่อมโยง Penalty ID: ${createdPenalty.penaltyId}',
      );
      
      final resultReport = await _reportController.updateReport(
        widget.report.reportId!,
        updatedReport,
      );

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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeAdminPage(
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
    Person? reportedPerson;
    if (widget.report.reporter?.id == widget.report.hirer?.id) {
      reportedPerson = widget.report.housekeeper?.person;
    } else {
      reportedPerson = widget.report.hirer?.person;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Penalty' : 'บทลงโทษ',
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
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  widget.isEnglish
                      ? 'Applying penalty to: ${reportedPerson?.firstName ?? 'N/A'} ${reportedPerson?.lastName ?? ''}'
                      : 'กำลังใช้บทลงโทษกับ: ${reportedPerson?.firstName ?? 'ไม่ระบุ'} ${reportedPerson?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text(
              widget.isEnglish
                  ? 'Select Penalty Type'
                  : 'เลือกประเภทบทลงโทษ',
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
                    ),
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
                    ),
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
            Text(
              widget.isEnglish ? 'Penalty Date' : 'วันที่ลงโทษ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText:
                    widget.isEnglish ? 'DD/MM/YYYY (AD)' : 'วว/ดด/ปปปป (พ.ศ.)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isEnglish
                  ? 'Penalty Details'
                  : 'รายละเอียดบทลงโทษ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    widget.isEnglish ? 'Please provide more details about the incident...' : 'โปรดระบุรายละเอียดเพิ่มเติมเกี่ยวกับเหตุการณ์...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitPenalty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isEnglish
                      ? 'Submit Penalty'
                      : 'ส่งบทลงโทษ',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
