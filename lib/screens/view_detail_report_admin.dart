import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/screens/penalty_admin.dart';
import 'package:maebanjumpen/styles/report_titles.dart';

// ViewDetailReportScreen: หน้าจอแสดงรายละเอียดของรายงาน
class ViewDetailReportScreen extends StatelessWidget {
  final Report report;
  final bool isEnglish; // ตัวแปรสำหรับเลือกภาษา (ควรเปลี่ยนเป็นระบบ Localization ในอนาคต)

  const ViewDetailReportScreen({
    super.key,
    required this.report,
    required this.isEnglish,
  });

  // Helper เพื่อดึง Person ของผู้รายงาน (Reporter)
  Person? _getReporterPerson(Report report) {
    return report.reporter?.person;
  }

  // Helper เพื่อดึง Person ของผู้ถูกรายงาน (Reported Party)
  // Logic: หา Party ที่ไม่ใช่ผู้รายงาน
  Person? _getReportedPartyPerson(Report report) {
    final reporterPersonId = report.reporter?.person?.personId;

    if (report.hirer?.person?.personId != null &&
        report.hirer!.person!.personId != reporterPersonId) {
      return report.hirer!.person;
    }
    if (report.housekeeper?.person?.personId != null &&
        report.housekeeper!.person!.personId != reporterPersonId) {
      return report.housekeeper!.person;
    }

    // กรณีที่ไม่สามารถระบุผู้ถูกรายงานได้
    return null;
  }

  // Helper เพื่อแปลสถานะรายงาน
  String _getLocalizedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return isEnglish ? 'Pending' : 'รอดำเนินการ';
      case 'resolved':
        return isEnglish ? 'Resolved' : 'แก้ไขแล้ว';
      case 'blocked':
        return isEnglish ? 'Blocked' : 'ถูกบล็อก';
      default:
        return isEnglish ? 'Unknown Status' : 'ไม่ทราบสถานะ';
    }
  }

  // Helper เพื่อแปลประเภทผู้ใช้
  String _getLocalizedUserType(PartyRole? partyRole) {
    if (partyRole is Hirer) {
      return isEnglish ? 'Member' : 'สมาชิก';
    } else if (partyRole is Housekeeper) {
      return isEnglish ? 'Housekeeper' : 'แม่บ้าน';
    } else if (partyRole is Admin) {
      return isEnglish ? 'Admin' : 'ผู้ดูแล';
    }
    return isEnglish ? 'Unknown' : 'ไม่ระบุ';
  }

  @override
  Widget build(BuildContext context) {
    final Person? reporterPerson = _getReporterPerson(report);
    final Person? reportedPartyPerson = _getReportedPartyPerson(report);

    // ข้อมูลสำหรับผู้รายงาน (Reporter)
    final String reporterFullName = reporterPerson != null
        ? '${reporterPerson.firstName ?? ''} ${reporterPerson.lastName ?? ''}'
            .trim()
        : (isEnglish ? 'Unknown Reporter' : 'ผู้รายงานไม่ระบุ');
    final String reporterEmail =
        reporterPerson?.email ?? (isEnglish ? 'N/A' : 'ไม่มี');
    final String reporterProfileImageUrl =
        reporterPerson?.pictureUrl ?? 'assets/images/default_profile.png';
    final String reporterUserType = _getLocalizedUserType(report.reporter);

    // ข้อมูลสำหรับผู้ถูกรายงาน (Reported Party)
    final String reportedPartyFullName = reportedPartyPerson != null
        ? '${reportedPartyPerson.firstName ?? ''} ${reportedPartyPerson.lastName ?? ''}'
            .trim()
        : (isEnglish ? 'Unknown Party' : 'ผู้ถูกรายงานไม่ระบุ');
    final String reportedPartyEmail =
        reportedPartyPerson?.email ?? (isEnglish ? 'N/A' : 'ไม่มี');
    final String reportedPartyProfileImageUrl =
        reportedPartyPerson?.pictureUrl ?? 'assets/images/default_profile.png';
    final String reportedPartyUserType;
    if (reportedPartyPerson != null) {
      if (report.hirer?.person?.personId == reportedPartyPerson.personId) {
        reportedPartyUserType = _getLocalizedUserType(report.hirer);
      } else if (report.housekeeper?.person?.personId ==
          reportedPartyPerson.personId) {
        reportedPartyUserType = _getLocalizedUserType(report.housekeeper);
      } else {
        reportedPartyUserType = isEnglish ? 'Unknown' : 'ไม่ระบุ';
      }
    } else {
      reportedPartyUserType = isEnglish ? 'N/A' : 'ไม่มี';
    }

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
          isEnglish ? 'Detail Report' : 'รายละเอียดรายงาน',
          style: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ส่วนข้อมูลผู้รายงาน
            _buildPersonDetailCard(
              isEnglish ? 'Reporter Information' : 'ข้อมูลผู้รายงาน',
              reporterPerson,
              reporterFullName,
              reporterUserType,
              reporterEmail,
              reporterProfileImageUrl,
              isEnglish,
            ),
            const SizedBox(height: 20),

            // การ์ดรายละเอียดรายงาน
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
                      isEnglish ? 'Report Details' : 'รายละเอียดรายงาน',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      Icons.title,
                      isEnglish ? 'Title' : 'หัวข้อ',
                      report.reportTitle != null
                          ? ReportTitles.getTitle(report.reportTitle!, isEnglish)
                          : (isEnglish ? 'N/A' : 'ไม่มี'),
                      isEnglish,
                    ),
                    _buildInfoRow(
                        Icons.message_outlined,
                        isEnglish ? 'Message' : 'ข้อความ',
                        report.reportMessage ?? (isEnglish ? 'N/A' : 'ไม่มี'),
                        isEnglish,
                        isMultiLine: true),
                    _buildInfoRow(
                        Icons.calendar_today_outlined,
                        isEnglish ? 'Date' : 'วันที่',
                        report.reportDate != null
                            ? (isEnglish
                                ? '${report.reportDate!.toLocal().month.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().day.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().year}'
                                : '${report.reportDate!.toLocal().day.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().month.toString().padLeft(2, '0')}/${report.reportDate!.toLocal().year + 543}')
                            : (isEnglish ? 'N/A' : 'ไม่มี'),
                        isEnglish),
                    _buildInfoRow(
                        Icons.info_outline,
                        isEnglish ? 'Status' : 'สถานะ',
                        _getLocalizedStatus(report.reportStatus ?? 'N/A'),
                        isEnglish),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ส่วนข้อมูลผู้ถูกรายงาน
            _buildPersonDetailCard(
              isEnglish ? 'Reported Party Information' : 'ข้อมูลผู้ถูกรายงาน',
              reportedPartyPerson,
              reportedPartyFullName,
              reportedPartyUserType,
              reportedPartyEmail,
              reportedPartyProfileImageUrl,
              isEnglish,
            ),
            const SizedBox(height: 40),

            // ปุ่มส่งการลงโทษ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // ปุ่มจะใช้งานได้ก็ต่อเมื่อสถานะรายงานเป็น 'pending'
                onPressed: report.reportStatus?.toLowerCase() == 'pending'
                    ? () async {
                        // นำทางไปยัง PenaltyScreen และส่งออบเจกต์รายงานไปด้วย
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PenaltyScreen(
                                report: report, isEnglish: isEnglish),
                          ),
                        );

                        // หาก PenaltyScreen ส่งค่า true กลับมา แสดงว่ามีการส่งบทลงโทษสำเร็จ
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isEnglish
                                    ? 'Penalty Submitted Successfully!'
                                    : 'ส่งการลงโทษสำเร็จ!')),
                          );
                          // หมายเหตุ: การอัปเดตสถานะรายงานบนหน้านี้ ควรใช้ State Management
                          // เช่น Provider, Riverpod, BLoC เพื่อให้ UI อัปเดตอัตโนมัติ
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
                  isEnglish ? 'Submit Penalty' : 'ส่งการลงโทษ',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper สำหรับสร้างแถวข้อมูล (ไอคอน หัวข้อ: ค่า)
  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isEnglish,
      {bool isMultiLine = false}) {
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
                  overflow: TextOverflow.ellipsis,
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
    bool isEnglish,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // จัดให้อยู่ตรงกลางแนวนอนใน Card
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
              backgroundImage: profileImageUrl.startsWith('http')
                  ? NetworkImage(profileImageUrl) as ImageProvider
                  : AssetImage(profileImageUrl),
              backgroundColor: Colors.grey[200],
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint(
                    'DEBUG(ViewDetailReport): Error loading image for $title: $exception');
              },
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
              userType, // แสดงประเภทผู้ใช้แทน username
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 15),
            // รายละเอียดส่วนตัวในรูปแบบรายการ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    Icons.email_outlined,
                    isEnglish ? 'Email' : 'อีเมล',
                    email,
                    isEnglish),
                _buildInfoRow(
                    Icons.phone_outlined,
                    isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                    person?.phoneNumber ?? (isEnglish ? 'N/A' : 'ไม่มี'),
                    isEnglish),
                _buildInfoRow(
                    Icons.location_on_outlined,
                    isEnglish ? 'Address' : 'ที่อยู่',
                    person?.address ?? (isEnglish ? 'N/A' : 'ไม่มี'),
                    isEnglish),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
