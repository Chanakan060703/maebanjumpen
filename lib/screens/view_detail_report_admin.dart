import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/ReportedPersonSummary.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/screens/penalty_admin.dart';
import 'package:maebanjumpen/styles/report_titles.dart';

class ViewDetailReportScreen extends StatefulWidget {
  final List<Report> aggregatedReports;
  final int initialIndex;
  final bool isEnglish;

  const ViewDetailReportScreen({
    super.key,
    required this.aggregatedReports,
    required this.initialIndex,
    required this.isEnglish,
  });

  @override
  State<ViewDetailReportScreen> createState() => _ViewDetailReportScreenState();
}

class _ViewDetailReportScreenState extends State<ViewDetailReportScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // กำหนด Controller ให้เริ่มต้นที่ index ของรายงานที่ถูกเลือกมา
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  // Helper เพื่อดึง Person ของผู้รายงาน (Reporter)
  Person? _getReporterPerson(Report report) {
    return report.reporter?.person;
  }

  // Helper เพื่อดึง Person ของผู้ถูกรายงาน (Reported Party)
  // ตรวจสอบ Hirer หรือ Housekeeper ที่ไม่ใช่ผู้รายงาน
  Person? _getReportedPartyPerson(Report report) {
    final reporterPersonId = report.reporter?.person?.personId;

    // ตรวจสอบ Hirer
    if (report.hirer?.person?.personId != null &&
        report.hirer!.person!.personId != reporterPersonId) {
      return report.hirer!.person;
    }
    // ตรวจสอบ Housekeeper
    if (report.housekeeper?.person?.personId != null &&
        report.housekeeper!.person!.personId != reporterPersonId) {
      return report.housekeeper!.person;
    }
    return null;
  }

  // Helper เพื่อแปลสถานะรายงาน
  String _getLocalizedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return widget.isEnglish ? 'Pending' : 'รอดำเนินการ';
      case 'resolved':
        return widget.isEnglish ? 'Resolved' : 'แก้ไขแล้ว';
      case 'blocked':
        return widget.isEnglish ? 'Blocked' : 'ถูกบล็อก';
      default:
        return widget.isEnglish ? 'Unknown Status' : 'ไม่ทราบสถานะ';
    }
  }

  // Helper เพื่อแปลประเภทผู้ใช้
  String _getLocalizedUserType(PartyRole? partyRole) {
    if (partyRole is Hirer) {
      return widget.isEnglish ? 'Member' : 'สมาชิก';
    } else if (partyRole is Housekeeper) {
      return widget.isEnglish ? 'Housekeeper' : 'แม่บ้าน';
    } else if (partyRole is Admin) {
      return widget.isEnglish ? 'Admin' : 'ผู้ดูแล';
    }
    return widget.isEnglish ? 'Unknown' : 'ไม่ระบุ';
  }

  // --- Widget Builders ---

  // Widget Helper สำหรับสร้างแถวข้อมูล (ไอคอน หัวข้อ: ค่า)
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isMultiLine ? 5 : 1,
                  overflow:
                      isMultiLine ? TextOverflow.clip : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper สำหรับสร้าง Card แสดงข้อมูลบุคคล (ผู้รายงาน/ผู้ถูกรายงาน)
  Widget _buildPersonDetailCard(
    String title,
    Person? person,
    String fullName,
    String userType,
    String email,
    String profileImageUrl,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 40,
              backgroundImage: profileImageUrl.startsWith('http') &&
                      !profileImageUrl.contains('default_profile.png')
                  ? NetworkImage(profileImageUrl) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
              backgroundColor: Colors.grey[200],
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint(
                  'DEBUG(ViewDetailReport): Error loading image for $title: $exception',
                );
              },
              child: profileImageUrl.startsWith('http')
                  ? null
                  : const Icon(Icons.person, color: Colors.grey, size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              userType,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 15),
            // รายละเอียดส่วนตัวในรูปแบบรายการ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.email_outlined,
                  widget.isEnglish ? 'Email' : 'อีเมล',
                  email,
                ),
                _buildInfoRow(
                  Icons.phone_outlined,
                  widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                  person?.phoneNumber ?? (widget.isEnglish ? 'N/A' : 'ไม่มี'),
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  widget.isEnglish ? 'Address' : 'ที่อยู่',
                  person?.address ?? (widget.isEnglish ? 'N/A' : 'ไม่มี'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


    


  Widget _buildReportPage(Report report) {
  final Person? reporterPerson = _getReporterPerson(report);
  final Person? reportedPartyPerson = _getReportedPartyPerson(report);

  // ข้อมูลสำหรับผู้รายงาน (Reporter)
  final String reporterFullName =
      reporterPerson != null
          ? '${reporterPerson.firstName ?? ''} ${reporterPerson.lastName ?? ''}'.trim()
          : (widget.isEnglish ? 'Unknown Reporter' : 'ผู้รายงานไม่ระบุ');
  final String reporterEmail =
      reporterPerson?.email ?? (widget.isEnglish ? 'N/A' : 'ไม่มี');
  final String reporterProfileImageUrl =
      reporterPerson?.pictureUrl ?? 'assets/images/default_profile.png';
  final String reporterUserType = _getLocalizedUserType(report.reporter);

  // ข้อมูลสำหรับผู้ถูกรายงาน (Reported Party)
  final String reportedPartyFullName =
      reportedPartyPerson != null
          ? '${reportedPartyPerson.firstName ?? ''} ${reportedPartyPerson.lastName ?? ''}'.trim()
          : (widget.isEnglish ? 'Unknown Party' : 'ผู้ถูกรายงานไม่ระบุ');
  final String reportedPartyEmail =
      reportedPartyPerson?.email ?? (widget.isEnglish ? 'N/A' : 'ไม่มี');
  final String reportedPartyProfileImageUrl =
      reportedPartyPerson?.pictureUrl ?? 'assets/images/default_profile.png';

  String reportedPartyUserType = widget.isEnglish ? 'N/A' : 'ไม่มี';
  if (reportedPartyPerson != null) {
    if (report.hirer?.person?.personId == reportedPartyPerson.personId) {
      reportedPartyUserType = _getLocalizedUserType(report.hirer);
    } else if (report.housekeeper?.person?.personId == reportedPartyPerson.personId) {
      reportedPartyUserType = _getLocalizedUserType(report.housekeeper);
    } else {
      reportedPartyUserType = widget.isEnglish ? 'Unknown' : 'ไม่ระบุ';
    }
  }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ส่วนข้อมูลผู้ถูกรายงาน
          _buildPersonDetailCard(
            widget.isEnglish
                ? 'Reported Party Information'
                : 'ข้อมูลผู้ถูกรายงาน',
            reportedPartyPerson,
            reportedPartyFullName,
            reportedPartyUserType,
            reportedPartyEmail,
            reportedPartyProfileImageUrl,
          ),
          const SizedBox(height: 20),

          // การ์ดรายละเอียดรายงาน (latest report)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? 'Latest Report Details' : 'รายละเอียดรายงานล่าสุด',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 25), // เพิ่ม Divider เพื่อความชัดเจน
                  _buildInfoRow(
                    Icons.title,
                    widget.isEnglish ? 'Title' : 'หัวข้อ',
                    report.reportTitle != null
                        ? ReportTitles.getTitle(
                            report.reportTitle!,
                            widget.isEnglish,
                          )
                        : (widget.isEnglish ? 'N/A' : 'ไม่มี'),
                  ),
                  _buildInfoRow(
                    Icons.message_outlined,
                    widget.isEnglish ? 'Message' : 'ข้อความ',
                    report.reportMessage ??
                        (widget.isEnglish ? 'N/A' : 'ไม่มี'),
                    isMultiLine: true,
                  ),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    widget.isEnglish ? 'Date' : 'วันที่',
                    report.reportDate != null
                        ? (widget.isEnglish
                            ? '${report.reportDate!.toLocal().month.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().day.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().year}'
                            : '${report.reportDate!.toLocal().day.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().month.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().year + 543}')
                        : (widget.isEnglish ? 'N/A' : 'ไม่มี'),
                  ),
                  _buildInfoRow(
                    Icons.info_outline,
                    widget.isEnglish ? 'Status' : 'สถานะ',
                    _getLocalizedStatus(report.reportStatus ?? 'N/A'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

        // ส่วนข้อมูลผู้รายงาน
          _buildPersonDetailCard(
            widget.isEnglish ? 'Reporter Information' : 'ข้อมูลผู้รายงาน',
            reporterPerson,
            reporterFullName,
            reporterUserType,
            reporterEmail,
            reporterProfileImageUrl,
          ),
          const SizedBox(height: 20),

          
          // ปุ่มส่งการลงโทษ
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              // ปุ่มจะใช้งานได้ก็ต่อเมื่อสถานะรายงานเป็น 'pending'
              onPressed:
                  report.reportStatus?.toLowerCase() == 'pending'
                      ? () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PenaltyScreen(
                                      report: report,
                                      isEnglish: widget.isEnglish,
                                    ),
                            ),
                          );

                          // หาก PenaltyScreen ส่งค่า true กลับมา แสดงว่ามีการส่งบทลงโทษสำเร็จ
                          if (result == true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.isEnglish
                                        ? 'Penalty Submitted Successfully!'
                                        : 'ส่งการลงโทษสำเร็จ!',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      : null, // ถ้าสถานะไม่ใช่ 'pending' ปุ่มจะถูกปิดใช้งาน
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.isEnglish ? 'Submit Penalty' : 'ส่งการลงโทษ',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // เพิ่มพื้นที่ด้านล่าง
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          widget.isEnglish ? 'Detail Report' : 'รายละเอียดรายงาน',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.aggregatedReports.length,
        itemBuilder: (context, index) {
          final Report report = widget.aggregatedReports[index];
          return _buildReportPage(report);  
        },
      ),
    );
  }
}
