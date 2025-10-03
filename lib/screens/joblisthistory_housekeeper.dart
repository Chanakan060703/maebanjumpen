import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/screens/report_housekeeper.dart';
import 'package:maebanjumpen/screens/report_member.dart';
import 'package:maebanjumpen/screens/view_review_housekeeper.dart';
import 'package:maebanjumpen/widgets/jobhistory_card.dart';

class JobListHistoryScreen extends StatefulWidget {
  final bool isEnglish;
  final int housekeeperId;
  final VoidCallback? onGoToHome;
  final Housekeeper currentHousekeeper;
  const JobListHistoryScreen({
    super.key,
    required this.isEnglish,
    required this.housekeeperId,
    required this.currentHousekeeper,
    this.onGoToHome,
  });
  @override
  State<JobListHistoryScreen> createState() => JobListHistoryScreenState();
}

class JobListHistoryScreenState extends State<JobListHistoryScreen> {
  late Future<List<Hire>> _futureHires;
  final Hirecontroller _hireController = Hirecontroller();
  @override
  void initState() {
    super.initState();
    _futureHires = fetchJobHistory();
  }

  Future<void> refreshJobHistory() async {
    print('Refreshing Job History Data from JobListHistoryScreenState...');
    setState(() {
      _futureHires = fetchJobHistory();
    });
  }

  Future<List<Hire>> fetchJobHistory() async {
    try {
      final List<Hire>? hires = await _hireController.getHiresByHousekeeperId(
        widget.housekeeperId,
      );
      if (hires == null) return [];
      final List<String> excludedStatuses = [
        'Upcoming',
        'In progress',
        'Pending',
        'PendingApproval',
        'Rejected',
      ];
      return hires
          .where((hire) => !excludedStatuses.contains(hire.jobStatus))
          .toList();
    } catch (e) {
      print('Error fetching job history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to load job history.'
                  : 'ไม่สามารถโหลดประวัติงานได้',
            ),
          ),
        );
      }
      return [];
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    if (widget.isEnglish) {
      return '${date.month}/${date.day}/${date.year}';
    } else {
      return '${date.day}/${date.month}/${date.year + 543}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Reported': // สถานะใหม่สำหรับการรายงานชั่วคราว/ถาวร
        return Colors.pink; // เลือกสีที่ชัดเจนสำหรับ Reported
      case 'Pending':
        return Colors.orange;
      case 'Upcoming':
        return Colors.orange;
      case 'Reviewed':
        return Colors.grey;
      case 'Accepted':
        return Colors.blue;
      case 'Declined':
        return Colors.redAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'In progress':
        return Colors.blueGrey;
      case 'PendingApproval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _navigateToReportPage(Hire hire) async {
    final bool? reportedSuccess = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReportMemberPage(
              hire: hire,
              isEnglish: widget.isEnglish,
              housekeeper: widget.currentHousekeeper,
              userPerson: widget.currentHousekeeper.person,
            ),
      ),
    );
    if (reportedSuccess == true) {
      // เมื่อรายงานสำเร็จ ให้อัปเดตสถานะบน UI ทันที (Optimistic Update)
      final List<Hire>? currentHires = await _futureHires;
      final int index =
          currentHires?.indexWhere((h) => h.hireId == hire.hireId) ?? -1;
      if (index != -1) {
        // สร้าง Dummy Report เพื่อซ่อนปุ่ม Report
        final dummyReport = Report(reportId: 0);
        final Hire reportedHire = currentHires![index].copyWith(
          jobStatus: 'Reported',
          report: dummyReport,
        );
        setState(() {
          currentHires[index] = reportedHire;
          // ตั้ง Future ใหม่เป็นค่าปัจจุบัน
          _futureHires = Future.value(currentHires);
        });
        // ตั้งเวลาเรียก refreshJobHistory() หลัง 3 วินาที เพื่อดึงสถานะจริงจาก Server
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            refreshJobHistory();
          }
        });
      } else {
        // ถ้าหา index ไม่เจอ ให้รีเฟรชทันที
        refreshJobHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hire>>(
      future: _futureHires,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              widget.isEnglish
                  ? 'Error: ${snapshot.error}'
                  : 'เกิดข้อผิดพลาด: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              widget.isEnglish ? 'No job history found.' : 'ไม่พบประวัติงาน',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        } else {
          // (โค้ดการเรียงลำดับยังคงเดิม)
          snapshot.data!.sort((a, b) {
            if (a.jobStatus == 'Completed' && b.jobStatus != 'Completed')
              return -1;
            if (a.jobStatus != 'Completed' && b.jobStatus == 'Completed')
              return 1;
            if (b.startDate == null && a.startDate == null) return 0;
            if (b.startDate == null) return -1;
            if (a.startDate == null) return 1;
            return b.startDate!.compareTo(a.startDate!);
          });
          return RefreshIndicator(
            onRefresh: refreshJobHistory, // ⬅️ ดึงลงเพื่อรีเฟรช
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              separatorBuilder:
                  (context, index) => const SizedBox(height: 16.0),
              itemBuilder: (context, index) {
                final hire = snapshot.data![index];
                final hirerName =
                    hire.hirer?.person?.firstName != null &&
                            hire.hirer?.person?.lastName != null
                        ? '${hire.hirer!.person!.firstName!} ${hire.hirer!.person!.lastName!}'
                        : (widget.isEnglish
                            ? 'Unknown Hirer'
                            : 'ผู้ว่าจ้างไม่ระบุ');
                final profileImageUrl =
                    hire.hirer?.person?.pictureUrl ??
                    'https://via.placeholder.com/50/CCCCCC/FFFFFF?Text=User';
                final jobPrice =
                    hire.paymentAmount != null
                        ? '${hire.paymentAmount!.toStringAsFixed(2)} ${widget.isEnglish ? 'THB' : 'บาท'}'
                        : (widget.isEnglish ? 'N/A' : 'ไม่ระบุ');
                final jobAddress =
                    hire.location?.isNotEmpty == true
                        ? hire.location!
                        : (widget.isEnglish ? 'No address' : 'ไม่มีที่อยู่');
                final jobStatusText =
                    hire.jobStatus ??
                    (widget.isEnglish ? 'Unknown' : 'ไม่ระบุสถานะ');
                // ตรรกะ: แสดงปุ่ม Report ก็ต่อเมื่อเป็น 'Completed' และยังไม่ถูก Report (hire.report == null)
                // ถ้าสถานะเป็น 'Reported' หรือมี Report แนบมาแล้ว (แม้สถานะจะกลับไปเป็น Completed) ปุ่มก็จะถูกซ่อน
                final bool showReportButton =
                    jobStatusText == 'Completed' && hire.report == null;
                final bool showViewReviewButton =
                    jobStatusText == 'Completed' && hire.review != null;
                final String jobServiceName =
                    hire.hireName ??
                    (widget.isEnglish ? 'Unknown Service' : 'บริการไม่ระบุ');
                return JobCardHistory(
                  name: hirerName,
                  serviceName: jobServiceName,
                  date: _formatDate(hire.startDate),
                  time: '${hire.startTime ?? ''} - ${hire.endTime ?? ''}',
                  address: jobAddress,
                  status: jobStatusText,
                  price: jobPrice,
                  imageUrl: profileImageUrl,
                  details:
                      hire.hireDetail ??
                      (widget.isEnglish ? 'No description' : 'ไม่มีรายละเอียด'),
                  statusColor: _getStatusColor(jobStatusText),
                  isEnglish: widget.isEnglish,
                  showReportButton: showReportButton,
                  showViewReviewButton: showViewReviewButton,
                  onReportPressed:
                      showReportButton
                          ? () => _navigateToReportPage(hire)
                          : null,
                  onViewReviewPressed:
                      showViewReviewButton
                          ? () {
                            if (hire.review != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ViewReviewScreen(
                                        hire: hire,
                                        isEnglish: widget.isEnglish,
                                      ),
                                ),
                              );
                            }
                          }
                          : null,
                );
              },
            ),
          );
        }
      },
    );
  }
}
