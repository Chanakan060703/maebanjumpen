import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/screens/view_detail_report_admin.dart';
import 'package:maebanjumpen/styles/report_titles.dart';

class ListReportScreen extends StatefulWidget {
  final Person user;
  final Admin admin;
  final bool isEnglish;

  const ListReportScreen({
    super.key,
    required this.user,
    required this.admin,
    required this.isEnglish,
  });

  @override
  State<ListReportScreen> createState() => _ListReportScreenState();
}

class _ListReportScreenState extends State<ListReportScreen> {
  String _selectedFilterValue = 'all';
  final ReportController _reportController = ReportController();
  List<Report>? _reports;
  bool _isLoading = true;
  String? _error;

  final List<Map<String, String>> _filterOptions = const [
    {'display': 'All Reports', 'value': 'all'},
    {'display': 'Member', 'value': 'hirer'},
    {'display': 'Housekeeper', 'value': 'housekeeper'},
    {'display': 'Pending', 'value': 'pending'},
    {'display': 'Resolved', 'value': 'resolved'},
    {'display': 'Blocked', 'value': 'blocked'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // โค้ดส่วนนี้จะทำการเรียกใช้ getAllReport() จาก ReportController จริง
      // และแปลงข้อมูลที่ได้มาเป็น List<Report>
      List<Report> fetchedReports = await _reportController.getAllReport();
      setState(() {
        _reports = fetchedReports;
        _isLoading = false;
      });
      debugPrint('Fetched ${fetchedReports.length} reports successfully.');
    } catch (e) {
      setState(() {
        _error = widget.isEnglish ? 'Failed to load reports: $e' : 'ไม่สามารถโหลดรายงานได้: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching reports: $e');
    }
  }

  // Helper เพื่อดึง Person ที่ถูกรายงาน
  Person? _getReportedPerson(Report report) {
    // แก้ไข logic: ถ้า hirer ไม่ใช่ reporter แสดงว่า hirer คือผู้ที่ถูกรายงาน
    if (report.hirer?.person?.personId != report.reporter?.person?.personId) {
      return report.hirer?.person;
    }
    // มิฉะนั้น housekeeper คือผู้ที่ถูกรายงาน
    return report.housekeeper?.person;
  }

  // Helper เพื่อดึงประเภทผู้ใช้ที่ถูกรายงาน (ในภาษาอังกฤษเท่านั้นสำหรับการกรอง)
  String _getReportedUserTypeForFilter(Report report) {
    // แก้ไข logic: ถ้า hirer ไม่ใช่ reporter แสดงว่า hirer คือผู้ที่ถูกรายงาน
    if (report.hirer?.person?.personId != report.reporter?.person?.personId) {
      return 'hirer';
    }
    // มิฉะนั้น housekeeper คือผู้ที่ถูกรายงาน
    return 'housekeeper';
  }

  // Helper เพื่อดึงประเภทผู้ใช้ที่ถูกรายงาน (สำหรับแสดงผล UI)
  String _getReportedUserTypeForDisplay(Report report) {
    final String userTypeForFilter = _getReportedUserTypeForFilter(report);
    if (userTypeForFilter == 'hirer') {
      return widget.isEnglish ? 'Member' : 'สมาชิก';
    }
    if (userTypeForFilter == 'housekeeper') {
      return widget.isEnglish ? 'Housekeeper' : 'แม่บ้าน';
    }
    return widget.isEnglish ? 'Unknown' : 'ไม่ระบุ';
  }

  @override
  Widget build(BuildContext context) {
    List<Report> filteredReports = [];
    if (_reports != null) {
      filteredReports = _reports!.where((report) {
        final String userTypeForFilter = _getReportedUserTypeForFilter(report);
        final String reportStatusLower = report.reportStatus?.toLowerCase() ?? 'unknown';

        switch (_selectedFilterValue) {
          case 'all':
            return true;
          case 'hirer':
            return userTypeForFilter == 'hirer';
          case 'housekeeper':
            return userTypeForFilter == 'housekeeper';
          case 'pending':
            return reportStatusLower == 'pending';
          case 'resolved':
            return reportStatusLower == 'resolved';
          case 'blocked':
            // การกรองสถานะ blocked ควรตรวจสอบจาก report.reportStatus หรือ accountStatus ของคนนั้นๆ
            // ในที่นี้จะกรองจาก reportStatus เป็นหลัก
            return reportStatusLower == 'blocked';
          default:
            return false;
        }
      }).toList();
    }

    return Scaffold(
      body: SingleChildScrollView(
        physics: _isLoading || _error != null || filteredReports.isEmpty
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ส่วนปุ่ม Filter
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterButton(
                        option['display']!,
                        option['value']!,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // ส่วนรายการผู้ใช้ที่ถูกรายงาน
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : filteredReports.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  widget.isEnglish
                      ? 'No reports found.'
                      : 'ไม่พบการรายงาน',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Column(
                children: filteredReports.map((report) {
                  final Person? reportedPerson = _getReportedPerson(report);
                  final String userType = _getReportedUserTypeForDisplay(report);

                  // ตรวจสอบข้อมูลที่จำเป็นก่อนสร้าง ReportedUserCard
                  if (reportedPerson == null ||
                      reportedPerson.firstName == null ||
                      reportedPerson.firstName!.isEmpty ||
                      reportedPerson.lastName == null ||
                      reportedPerson.lastName!.isEmpty) {
                    debugPrint(
                        'Skipping report ID ${report.reportId ?? 'N/A'} due to missing or incomplete reported person data.');
                    return const SizedBox.shrink(); // ไม่แสดงถ้าหาข้อมูล Person ไม่เจอ หรือไม่สมบูรณ์
                  }

                  final String reportTitle = report.reportTitle != null
                      ? ReportTitles.getTitle(report.reportTitle!, widget.isEnglish)
                      : (widget.isEnglish ? 'No description' : 'ไม่มีคำอธิบาย');

                  final String formattedDate = report.reportDate != null
                      ? (widget.isEnglish
                      ? DateFormat('MM/dd/yyyy').format(report.reportDate!.toLocal())
                      : DateFormat('dd/MM/yyyy').format(report.reportDate!.toLocal()))
                      : (widget.isEnglish ? 'No date' : 'ไม่มีวันที่');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: ReportedUserCard(
                      imageUrl: reportedPerson.pictureUrl != null &&
                          reportedPerson.pictureUrl!.isNotEmpty
                          ? reportedPerson.pictureUrl!
                          : 'assets/images/default_profile.png',
                      username:
                      '${reportedPerson.firstName!} ${reportedPerson.lastName!}',
                      reportDescription: reportTitle,
                      date: formattedDate,
                      reportStatus: report.reportStatus?.toLowerCase() ?? 'unknown',
                      reportCount: report.reportCount ?? 1, // ใช้ค่าจาก API, ถ้าไม่มีให้ใช้ 1
                      userType: userType,
                      isEnglish: widget.isEnglish,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewDetailReportScreen(
                              report: report,
                              isEnglish: widget.isEnglish,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String displayText, String filterValue) {
    final bool isSelected = _selectedFilterValue == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterValue = filterValue;
        });
        debugPrint('Selected filter: $displayText (value: $filterValue)');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          widget.isEnglish
              ? displayText
              : _getLocalizedFilterText(displayText),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getLocalizedFilterText(String englishText) {
    switch (englishText) {
      case 'All Reports':
        return 'รายงานทั้งหมด';
      case 'Member':
        return 'สมาชิก';
      case 'Housekeeper':
        return 'แม่บ้าน';
      case 'Pending':
        return 'รอดำเนินการ';
      case 'Resolved':
        return 'แก้ไขแล้ว';
      case 'Blocked':
        return 'ถูกบล็อก';
      default:
        return englishText;
    }
  }
}

class ReportedUserCard extends StatelessWidget {
  final String imageUrl;
  final String username;
  final String reportDescription;
  final String date;
  final int reportCount;
  final String userType;
  final String reportStatus;
  final bool isEnglish;
  final VoidCallback onTap;

  const ReportedUserCard({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.reportDescription,
    required this.date,
    required this.reportCount,
    required this.userType,
    required this.reportStatus,
    required this.isEnglish,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedStatus(String status) {
    if (isEnglish) {
      return status;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl) as ImageProvider
                    : AssetImage(imageUrl),
                backgroundColor: Colors.grey[200],
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('DEBUG(ReportedUserCard): Error loading image: $exception');
                },
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$reportCount ${isEnglish ? 'reports' : 'รายงาน'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reportStatus),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isEnglish
                                ? reportStatus
                                : _getLocalizedStatus(reportStatus),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            userType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
