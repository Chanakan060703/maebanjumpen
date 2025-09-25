import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/housekeeper.dart'; // **เพิ่ม: Import Housekeeper model**
import 'package:maebanjumpen/screens/report_housekeeper.dart';
import 'package:maebanjumpen/screens/view_review_housekeeper.dart';
import 'package:maebanjumpen/widgets/jobhistory_card.dart';

class JobListHistoryScreen extends StatefulWidget {
  final bool isEnglish;
  final int housekeeperId;
  final VoidCallback? onGoToHome;
  final Housekeeper currentHousekeeper; // **เพิ่ม: รับ Housekeeper object เข้ามา**

  const JobListHistoryScreen({
    super.key,
    required this.isEnglish,
    required this.housekeeperId,
    required this.currentHousekeeper, // **เพิ่ม: กำหนดให้เป็น required**
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
    setState(() {
      _futureHires = fetchJobHistory();
    });
  }

  Future<List<Hire>> fetchJobHistory() async {
    try {
      final List<Hire>? hires =
          await _hireController.getHiresByHousekeeperId(widget.housekeeperId);

      if (hires == null) return [];

      final List<String> excludedStatuses = [
        'Upcoming',
        'In progress',
        'Pending',
        'PendingApproval',
      ];

      return hires.where((hire) => !excludedStatuses.contains(hire.jobStatus)).toList();
    } catch (e) {
      print('Error fetching job history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Failed to load job history.'
                  : 'ไม่สามารถโหลดประวัติงานได้')),
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
      case 'Rejected':
        return Colors.redAccent;
      case 'In progress':
        return Colors.blueGrey;
      case 'PendingApproval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () {
            widget.onGoToHome?.call();
          },
        ),
        title: Text(
          widget.isEnglish ? 'Job History' : 'ประวัติงาน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              refreshJobHistory();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Hire>>(
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
            snapshot.data!.sort((a, b) {
              if (a.jobStatus == 'Completed' && b.jobStatus != 'Completed') return -1;
              if (a.jobStatus != 'Completed' && b.jobStatus == 'Completed') return 1;
              if (b.startDate == null && a.startDate == null) return 0;
              if (b.startDate == null) return -1;
              if (a.startDate == null) return 1;
              return b.startDate!.compareTo(a.startDate!);
            });

            return RefreshIndicator(
              onRefresh: refreshJobHistory,
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16.0),
                itemBuilder: (context, index) {
                  final hire = snapshot.data![index];

                  final hirerName = hire.hirer?.person?.firstName != null &&
                          hire.hirer?.person?.lastName != null
                      ? '${hire.hirer!.person!.firstName!} ${hire.hirer!.person!.lastName!}'
                      : (widget.isEnglish ? 'Unknown Hirer' : 'ผู้ว่าจ้างไม่ระบุ');

                  final profileImageUrl = hire.hirer?.person?.pictureUrl ??
                      'https://via.placeholder.com/50/CCCCCC/FFFFFF?Text=User';

                  final jobPrice = hire.paymentAmount != null
                      ? '${hire.paymentAmount!.toStringAsFixed(2)} ${widget.isEnglish ? 'THB' : 'บาท'}'
                      : (widget.isEnglish ? 'N/A' : 'ไม่ระบุ');

                  final jobAddress = hire.location?.isNotEmpty == true
                      ? hire.location!
                      : (widget.isEnglish ? 'No address' : 'ไม่มีที่อยู่');

                  final jobStatusText = hire.jobStatus ??
                      (widget.isEnglish ? 'Unknown' : 'ไม่ระบุสถานะ');

                  final bool showViewReviewButton =
                      jobStatusText == 'Completed' && hire.review != null;
                  final bool showReportButton = jobStatusText == 'Completed';

                  return JobCardHistory(
                    name: hirerName,
                    date: _formatDate(hire.startDate),
                    time: '${hire.startTime ?? ''} - ${hire.endTime ?? ''}',
                    address: jobAddress,
                    status: jobStatusText,
                    price: jobPrice,
                    imageUrl: profileImageUrl,
                    details: hire.hireDetail ??
                        (widget.isEnglish ? 'No description' : 'ไม่มีรายละเอียด'),
                    statusColor: _getStatusColor(jobStatusText),
                    isEnglish: widget.isEnglish,
                    showReportButton: showReportButton,
                    showViewReviewButton: showViewReviewButton,
                    onReportPressed: showReportButton
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportMemberPage(
                                  hire: hire, // ส่ง object hire ไปด้วย
                                  isEnglish: widget.isEnglish,
                                  housekeeper: widget.currentHousekeeper, // ส่ง housekeeper object ผู้รายงานไป
                                ),
                              ),
                            ).then((value) {
                              // ถ้าหน้า ReportMemberPage ถูก pop กลับมา (เช่น กด Back หรือส่งสำเร็จ)
                              // คุณอาจจะ refresh ประวัติงานตรงนี้ก็ได้
                              if (value != null) {
                                refreshJobHistory();
                              }
                            });
                          }
                        : null,
                    onViewReviewPressed: showViewReviewButton
                        ? () {
                            if (hire.review != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewReviewScreen(
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
      ),
    );
  }
}