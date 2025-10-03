import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Note: Assuming these imports are correct within the project structure
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/ReportedPersonSummary.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/screens/ReportedPersonReportsListScreen.dart';
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
  List<Report>? _reports; // เก็บรายการรายงานทั้งหมดที่ดึงมาจาก API
  List<ReportedPersonSummary> _aggregatedReports =
      []; 
  bool _isLoading = true;
  String? _error;
  // ตัวเลือกการกรอง (เพิ่ม 'Resolved' และ 'Blocked')
  final List<Map<String, String>> _filterOptions = const [
    {'display': 'All Reports', 'value': 'all'},
    {'display': 'Member', 'value': 'hirer'},
    {'display': 'Housekeeper', 'value': 'housekeeper'},
    {'display': 'Pending', 'value': 'pending'},
    {'display': 'Resolved', 'value': 'resolved'}, // เพิ่มตัวกรอง Resolved
    {'display': 'Blocked', 'value': 'blocked'}, // เพิ่มตัวกรอง Blocked
  ];
  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // Helper เพื่อดึง Person ที่ถูกรายงาน
  Person? _getReportedPerson(Report report) {
    // Logic: ถ้า hirer ID ไม่ใช่ reporter ID แสดงว่า hirer คือผู้ที่ถูกรายงาน
    if (report.hirer?.person?.personId != report.reporter?.person?.personId) {
      return report.hirer?.person;
    }
    // มิฉะนั้น housekeeper คือผู้ที่ถูกรายงาน
    return report.housekeeper?.person;
  }

  // Helper เพื่อดึงประเภทผู้ใช้ที่ถูกรายงาน (ในภาษาอังกฤษเท่านั้นสำหรับการกรอง)
  String _getReportedUserTypeForFilter(Report report) {
    if (report.hirer?.person?.personId != report.reporter?.person?.personId) {
      return 'hirer';
    }
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

  // ฟังก์ชันรวมกลุ่มรายงานตาม Reported Person ID
  void _aggregateReports(List<Report> reports) {
    if (reports.isEmpty) {
      _aggregatedReports = [];
      return;
    }
    // Map: Reported Person ID (String) -> List of Reports
    final Map<String, List<Report>> groupedReports = {};
    for (final report in reports) {
      final reportedPerson = _getReportedPerson(report);
      final reportedPersonId =
          reportedPerson?.personId; // นี่คือตัวแปรที่อาจเป็น int?
      // 1. แปลง reportedPersonId เป็น String เสมอสำหรับใช้เป็น Map Key
      // ใช้ null-aware access (?.) และ null coalescing (??) เพื่อจัดการค่า null
      final mapKey = reportedPersonId?.toString() ?? '';
      // 2. ตรวจสอบว่า mapKey ไม่ใช่ค่าว่างเปล่า
      if (mapKey.isNotEmpty) {
        if (!groupedReports.containsKey(mapKey)) {
          groupedReports[mapKey] = [];
        }
        // รายงานถูกจัดเรียงตามวันที่ล่าสุดแล้ว, เราจะเพิ่มเข้าไปเพื่อให้รายการย่อยยังคงถูกจัดเรียง
        groupedReports[mapKey]!.add(report);
      } else {
        debugPrint(
          'Skipping report ID ${report.reportId ?? 'N/A'} due to missing or invalid reported person ID.',
        );
      }
    }
    // ใช้ ReportedPersonSummary
    final List<ReportedPersonSummary> aggregatedList = [];
    for (final entry in groupedReports.entries) {
      final personReports = entry.value;
      // รายงานถูกจัดเรียงตามวันที่ล่าสุดแล้ว, รายงานแรกคือรายงานล่าสุด
      final latestReport = personReports.first;
      final reportedPerson = _getReportedPerson(latestReport);
      // ตรวจสอบข้อมูลที่จำเป็นก่อนสร้าง AggregatedReport
      if (reportedPerson == null ||
          reportedPerson.personId == null ||
          reportedPerson.firstName == null ||
          reportedPerson.firstName!.isEmpty) {
        debugPrint(
          'Skipping aggregated entry for person ID ${entry.key} due to missing essential Person data.',
        );
        continue;
      }
      aggregatedList.add(
        ReportedPersonSummary(
          reportedPerson: reportedPerson,
          userTypeForDisplay: _getReportedUserTypeForDisplay(latestReport),
          totalReportCount: personReports.length,
          latestReport: latestReport,
          allReports: personReports,
        ),
      );
    }
    // ตั้งค่า Aggregated Reports ใน State
    _aggregatedReports = aggregatedList;
    debugPrint(
      'Aggregated ${_aggregatedReports.length} unique reported persons.',
    );
  }

  // ฟังก์ชันดึงข้อมูลรายงานทั้งหมด
  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _aggregatedReports = []; // ล้างรายการที่รวมกลุ่มก่อนเริ่มโหลด
    });
    try {
      List<Report> fetchedReports = await _reportController.getAllReport();
      // 1. จัดเรียงรายงานตามวันที่ล่าสุด (สำคัญสำหรับการกำหนด 'latestReport' สำหรับแสดงสถานะและข้อมูล)
      fetchedReports.sort(
        (a, b) => (b.reportDate ?? DateTime(0)).compareTo(
          a.reportDate ?? DateTime(0),
        ),
      );
      // 2. รวมกลุ่มรายงาน
      _aggregateReports(fetchedReports);
      setState(() {
        _reports = fetchedReports; // เก็บรายการทั้งหมดไว้
        _isLoading = false;
      });
      debugPrint('Fetched ${fetchedReports.length} reports successfully.');
    } catch (e) {
      setState(() {
        _error =
            widget.isEnglish
                ? 'Failed to load reports: $e'
                : 'ไม่สามารถโหลดรายงานได้: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // เปลี่ยนไปใช้ ReportedPersonSummary
    List<ReportedPersonSummary> filteredReports = [];
    if (!_isLoading && _error == null) {
      // ใช้รายการที่รวมกลุ่มแล้วในการกรอง
      filteredReports =
          _aggregatedReports.where((aggregatedData) {
            final Report latestReport = aggregatedData.latestReport;
            final String userTypeForFilter = _getReportedUserTypeForFilter(
              latestReport,
            );
            final String reportStatusLower =
                latestReport.reportStatus?.toLowerCase() ?? 'unknown';
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
                return reportStatusLower == 'blocked';
              default:
                return false;
            }
          }).toList();
    }
    return Scaffold(
      body: SingleChildScrollView(
        // ปรับปรุง: ใช้ AlwaysScrollableScrollPhysics เพื่อรองรับการเลื่อนเสมอ
        physics: const AlwaysScrollableScrollPhysics(),
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
                  children:
                      _filterOptions.map((option) {
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
            // ส่วนแสดงรายการ (Loading/Error/Empty/Data)
            _isLoading
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                )
                : _error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
                : filteredReports.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      widget.isEnglish
                          ? 'No reports found for this filter.'
                          : 'ไม่พบการรายงานในตัวกรองนี้',
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
                  // ปรับปรุง: ใช้ ListView.builder สำหรับประสิทธิภาพที่ดีขึ้น
                  child: ListView.builder(
                    shrinkWrap:
                        true, // ทำให้ ListView ใช้พื้นที่เท่าที่จำเป็นภายใน SingleChildScrollView
                    physics:
                        const NeverScrollableScrollPhysics(), // ปิดการเลื่อนของ ListView ให้ SingleChildScrollView จัดการ
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final aggregatedData = filteredReports[index];
                      final Person reportedPerson =
                          aggregatedData.reportedPerson;
                      final Report latestReport = aggregatedData.latestReport;
                      

                      if (reportedPerson.firstName == null ||
                          reportedPerson.firstName!.isEmpty ||
                          reportedPerson.lastName == null ||
                          reportedPerson.lastName!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final String reportTitle =
                          latestReport.reportTitle != null
                              ? ReportTitles.getTitle(
                                latestReport.reportTitle!,
                                widget.isEnglish,
                              )
                              : (widget.isEnglish
                                  ? 'No description'
                                  : 'ไม่มีคำอธิบาย');
                      final String formattedDate =
                          latestReport.reportDate != null
                              ? (widget.isEnglish
                                  ? DateFormat(
                                    'MM/dd/yyyy',
                                  ).format(latestReport.reportDate!.toLocal())
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(latestReport.reportDate!.toLocal()))
                              : (widget.isEnglish ? 'No date' : 'ไม่มีวันที่');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: ReportedUserCard(
                          imageUrl:
                              reportedPerson.pictureUrl?.isNotEmpty == true
                                  ? reportedPerson.pictureUrl!
                                  : 'assets/images/default_profile.png',
                          username:
                              '${reportedPerson.firstName!} ${reportedPerson.lastName!}',
                          reportDescription: reportTitle,
                          date: formattedDate,
                          reportStatus:
                              latestReport.reportStatus?.toLowerCase() ??
                              'unknown',
                          reportCount: aggregatedData.totalReportCount,
                          userType: aggregatedData.userTypeForDisplay,
                          isEnglish: widget.isEnglish,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ReportedPersonReportsListScreen(
                                      reportedPersonSummary: aggregatedData,
                                      isEnglish: widget.isEnglish, 
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // สร้างปุ่มกรอง (Filter Button)
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
          color: isSelected ? Colors.red.shade700 : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          widget.isEnglish
              ? displayText
              : _getLocalizedFilterText(displayText), // แปลข้อความแสดงผล
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // แปลข้อความตัวเลือกการกรองเป็นภาษาไทย
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

// วิดเจ็ตการ์ดแสดงผู้ใช้ที่ถูกรายงาน (ไม่เปลี่ยนแปลง)
class ReportedUserCard extends StatelessWidget {
  final String imageUrl;
  final String username;
  final String reportDescription;
  final String date;
  final int reportCount; // รับจำนวนรายงานที่ถูกรวมกลุ่ม
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

  // แปลสถานะเป็นภาษาไทย
  String _getLocalizedStatus(String status) {
    if (isEnglish) {
      // ทำให้ตัวอักษรแรกเป็นตัวใหญ่
      return status.substring(0, 1).toUpperCase() +
          status.substring(1).toLowerCase();
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
              // รูปโปรไฟล์
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    imageUrl.startsWith('http')
                        ? NetworkImage(imageUrl) as ImageProvider
                        : AssetImage(imageUrl),
                backgroundColor: Colors.grey[200],
                onBackgroundImageError: (exception, stackTrace) {
                  // Fallback to default if network image fails
                  debugPrint(
                    'DEBUG(ReportedUserCard): Error loading image: $exception',
                  );
                  // This is where you might set a state to use a fallback asset if this was a stateful widget
                },
                child:
                    imageUrl.startsWith('http')
                        ? null
                        : const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 30,
                        ),
              ),
              const SizedBox(width: 15),
              // รายละเอียด
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
                    // แถบสถานะ/ประเภทผู้ใช้
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        // จำนวนรายงาน (ใช้ reportCount ที่ถูกรวมกลุ่ม)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
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
                        // สถานะรายงาน
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reportStatus),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _getLocalizedStatus(reportStatus),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // ประเภทผู้ใช้ที่ถูกรายงาน
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.shade400,
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
              // ไอคอนลูกศรนำทาง
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
