import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/ReportedPersonSummary.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart'; // ต้องมั่นใจว่า Report model มี copyWith()
import 'package:maebanjumpen/screens/view_detail_report_admin.dart';
import 'package:maebanjumpen/styles/report_titles.dart';


// ReportedPersonReportsListScreen: หน้าจอแสดงรายการรายงานทั้งหมดที่บุคคลคนหนึ่งได้รับ
// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
class ReportedPersonReportsListScreen extends StatefulWidget {
  final ReportedPersonSummary reportedPersonSummary;
  final bool isEnglish;

  const ReportedPersonReportsListScreen({
    super.key,
    required this.reportedPersonSummary,
    required this.isEnglish,
  });

  @override
  State<ReportedPersonReportsListScreen> createState() => _ReportedPersonReportsListScreenState();
}

class _ReportedPersonReportsListScreenState extends State<ReportedPersonReportsListScreen> {
  // ใช้ตัวแปร state เพื่อเก็บข้อมูลสรุปและรายงานทั้งหมด ทำให้สามารถอัปเดตได้
  late ReportedPersonSummary _currentSummary;

  @override
  void initState() {
    super.initState();
    // คัดลอกข้อมูลเริ่มต้นมาเก็บไว้ใน state
    _currentSummary = widget.reportedPersonSummary;
  }

  // Helper เพื่อแปลสถานะรายงาน
  String _getLocalizedStatus(String status) {
    if (widget.isEnglish) {
      // ทำให้ตัวอักษรแรกเป็นตัวใหญ่
      return status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase();
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'resolved':
        return 'แก้ไขแล้ว';
      case 'blocked':
        return 'ถูกบล็อก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // กำหนดสีตามสถานะ
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'resolved':
        return Colors.green.shade700;
      case 'blocked':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Person reportedPerson = _currentSummary.reportedPerson;
    final List<Report> allReports = _currentSummary.allReports;
    final String fullName = '${reportedPerson.firstName!} ${reportedPerson.lastName!}';
    final String userType = _currentSummary.userTypeForDisplay;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEnglish ? 'Reports on $fullName' : 'รายงานทั้งหมดของ $fullName',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: reportedPerson.pictureUrl?.isNotEmpty == true
                      ? NetworkImage(reportedPerson.pictureUrl!) as ImageProvider
                      : const AssetImage('assets/images/default_profile.png'),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$userType | ${_currentSummary.totalReportCount} ${widget.isEnglish ? 'Reports Total' : 'รายงานทั้งหมด'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Report List
          Expanded(
            child: ListView.builder(
              itemCount: allReports.length,
              itemBuilder: (context, index) {
                final report = allReports[index];
                final reporterPerson = report.reporter?.person;
                final String reporterName = reporterPerson != null
                    ? '${reporterPerson.firstName ?? ''} ${reporterPerson.lastName ?? ''}'.trim()
                    : (widget.isEnglish ? 'Unknown Reporter' : 'ผู้รายงานไม่ระบุ');
                
                final String reportTitle = report.reportTitle != null
                    ? ReportTitles.getTitle(report.reportTitle!, widget.isEnglish)
                    : (widget.isEnglish ? 'No title' : 'ไม่มีหัวข้อ');
                
                final String formattedDate = report.reportDate != null
                    ? (widget.isEnglish
                        ? DateFormat('MMM d, yyyy').format(report.reportDate!.toLocal())
                        : DateFormat('d MMM yyyy', 'th').format(report.reportDate!.toLocal()))
                    : (widget.isEnglish ? 'N/A' : 'ไม่มีวันที่');
                
                final String status = report.reportStatus?.toLowerCase() ?? 'unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(status).withOpacity(0.1),
                      child: Icon(Icons.description, color: _getStatusColor(status)),
                    ),
                    title: Text(
                      reportTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          widget.isEnglish ? 'Reported by: $reporterName' : 'รายงานโดย: $reporterName',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _getLocalizedStatus(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () async {
                      // 1. ใช้อัญเชิญ Navigator.push และรอผลลัพธ์กลับมา
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewDetailReportScreen(
                            aggregatedReports: allReports,
                            initialIndex: index,
                            isEnglish: widget.isEnglish,
                          ),
                        ),
                      );

                      // 2. ตรวจสอบผลลัพธ์และอัปเดตสถานะ
                      // เราคาดหวังผลลัพธ์เป็น Map<String, dynamic> เช่น
                      // {'index': index, 'newStatus': 'Resolved', 'penaltyId': 'PNT-123'}
                      if (result != null && result is Map<String, dynamic> && result['newStatus'] is String) {
                        final int updatedIndex = result['index'];
                        final String newStatus = result['newStatus'];

                        if (updatedIndex == index && updatedIndex >= 0 && updatedIndex < allReports.length) {
                          setState(() {
                            // ใช้ copyWith เพื่อสร้าง Report object ใหม่ที่มีสถานะที่ถูกอัปเดต
                            final updatedReport = allReports[updatedIndex].copyWith(
                              reportStatus: newStatus,
                              // หาก Report model มีฟิลด์ penaltyId สามารถอัปเดตตรงนี้ได้
                              // penaltyId: result['penaltyId'],
                            );
                            
                            // แทนที่ Report เดิมใน List ด้วย Report ใหม่
                            _currentSummary.allReports[updatedIndex] = updatedReport;

                            // Note: ไม่จำเป็นต้อง update totalReportCount เพราะจำนวนรายงานยังเท่าเดิม
                          });
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
