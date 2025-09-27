import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/hire.dart'; // Import Hire model
import 'package:maebanjumpen/model/housekeeper.dart'; // Import Housekeeper model
import 'package:maebanjumpen/model/hirer.dart'; // Import Hirer model if needed for hire details
import 'package:maebanjumpen/screens/home_housekeeper.dart';
import 'package:maebanjumpen/screens/jobrequestdetail_housekeeper.dart';
import 'package:maebanjumpen/screens/profile_housekeeper.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart'; // Make sure this path is correct
import 'package:provider/provider.dart'; // Import Provider

class JobRequestsPage extends StatefulWidget {
  final Housekeeper housekeeper; // Pass the logged-in housekeeper object
  final bool isEnglish;

  const JobRequestsPage({
    super.key,
    required this.housekeeper,
    required this.isEnglish,
  });

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  final Hirecontroller _hireController = Hirecontroller();
  List<Hire> _currentJobRequests = []; // To hold the actual list after fetching
  List<Hire> _previousJobRequests = []; // For status comparison
  bool _isLoading = true;
  String? _errorMessage;

  // ไม่ต้องใช้ _notifiedEventKeys ที่นี่แล้ว เพราะจะย้ายไปจัดการใน NotificationManager

  int _currentIndex = 1; // ตั้งค่าเริ่มต้นให้เป็น index ของ Job Requests (สมมติว่าเป็นแท็บที่ 1)

  @override
  void initState() {
    super.initState();
    _fetchJobRequests();
  }

  void _fetchJobRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Store current data before fetching new
      // การสร้าง List.from(_currentJobRequests) จะสร้าง List ใหม่ที่มีข้อมูลเหมือนเดิม
      // ทำให้ _previousJobRequests ไม่ได้ชี้ไปยัง object เดียวกันกับ _currentJobRequests
      _previousJobRequests = List.from(_currentJobRequests);

      if (widget.housekeeper.id != null) {
        final List<Hire>? fetchedHires = await _hireController.getHiresByHousekeeperId(widget.housekeeper.id!);

        if (mounted) {
          setState(() {
            if (fetchedHires != null) {
              // Filter out 'completed', 'reviewed', 'cancelled', 'rejected' job requests
              _currentJobRequests = fetchedHires
                  .where((request) =>
                      request.jobStatus?.toLowerCase() != 'completed' &&
                      request.jobStatus?.toLowerCase() != 'reviewed' &&
                      request.jobStatus?.toLowerCase() != 'cancelled' &&
                      request.jobStatus?.toLowerCase() != 'rejected')
                  .toList();
            } else {
              _currentJobRequests = [];
            }
            _isLoading = false;
          });
          _checkAndNotifyJobStatusChanges(); // Check after new data is set
        }
      } else {
        if (mounted) {
          setState(() {
            _currentJobRequests = [];
            _isLoading = false;
            _errorMessage = widget.isEnglish ? 'Housekeeper ID is null.' : 'ไม่พบรหัสแม่บ้าน';
          });
        }
      }
    } catch (e) {
      print('Error fetching job requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.isEnglish ? 'Failed to load job requests. Please try again.' : 'ไม่สามารถโหลดรายการงานได้ กรุณาลองใหม่';
        });
      }
    }
  }

  /// Checks for status changes between current and previous job requests
  /// and sends notifications if changes are detected.
  void _checkAndNotifyJobStatusChanges() {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

    for (final newHire in _currentJobRequests) {
      final oldHire = _previousJobRequests.firstWhereOrNull(
        (h) => h.hireId == newHire.hireId,
      );

      // สร้าง eventKey ที่ไม่ซ้ำกันสำหรับสถานะใหม่ของแต่ละ hire
      // รูปแบบ: 'job_status_change_{hireId}_{jobStatus}'
      final String eventKey = 'job_status_change_${newHire.hireId}_${newHire.jobStatus}';

      if (oldHire == null) {
        // This is a brand new job request
        // ส่ง eventKey ไปยัง NotificationManager เพื่อให้จัดการการแจ้งเตือนซ้ำซ้อน
        notificationManager.addNotification(
          title: widget.isEnglish ? 'New Job Request!' : 'มีคำขอจ้างงานใหม่!',
          body: widget.isEnglish
              ? 'You have a new job request: "${newHire.hireName ?? 'Unnamed Job'}" with status "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}".'
              : 'คุณมีคำขอจ้างงานใหม่: "${newHire.hireName ?? 'งานที่ไม่มีชื่อ'}" สถานะ "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}"',
          payload: 'new_job_request_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey, // ส่ง eventKey ไปที่ NotificationManager
        );
      } else if (oldHire.jobStatus != newHire.jobStatus) {
        // Status has changed for an existing job
        // ส่ง eventKey ไปยัง NotificationManager เพื่อให้จัดการการแจ้งเตือนซ้ำซ้อน
        final String oldStatusLocalized = _getLocalizedJobStatus(oldHire.jobStatus ?? '');
        final String newStatusLocalized = _getLocalizedJobStatus(newHire.jobStatus ?? '');

        notificationManager.addNotification(
          title: widget.isEnglish ? 'Job Status Updated!' : 'สถานะงานอัปเดตแล้ว!',
          body: widget.isEnglish
              ? 'The job "${newHire.hireName ?? 'Unnamed Job'}" has changed from "$oldStatusLocalized" to "$newStatusLocalized".'
              : 'งาน "${newHire.hireName ?? 'งานที่ไม่มีชื่อ'}" เปลี่ยนสถานะจาก "$oldStatusLocalized" เป็น "$newStatusLocalized" แล้ว',
          payload: 'job_status_update_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey, // ส่ง eventKey ไปที่ NotificationManager
        );
      }
    }
  }

  // START: Job Status Logic - Copied and adapted from HireListPage
  String _getLocalizedJobStatus(String status) {
    Map<String, String> enMap = {
      'all': 'All',
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'in_progress': 'In Progress',
      'verified': 'Verified',
      'rejected': 'Rejected',
      'pendingapproval': 'Pending Approval',
      'reviewed': 'Reviewed',
      'pending': 'Pending',
      'accepted': 'Accepted',
    };

    Map<String, String> thMap = {
      'all': 'ทั้งหมด',
      'upcoming': 'กำลังจะมาถึง',
      'completed': 'เสร็จสิ้น',
      'cancelled': 'ยกเลิกแล้ว',
      'in_progress': 'กำลังดำเนินการ',
      'verified': 'ได้รับการยืนยัน',
      'rejected': 'ถูกปฏิเสธ',
      'pendingapproval': 'รอการอนุมัติ',
      'reviewed': 'รีวิวแล้ว',
      'pending': 'รอดำเนินการ',
      'accepted': 'ตอบรับแล้ว',
    };

    return widget.isEnglish
        ? enMap[status.toLowerCase()] ?? status
        : thMap[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.orange;
      case 'pending':
        return Colors.orange;
      case 'pendingapproval':
        return Colors.orange;
      case 'accepted':
      case 'completed':
      case 'verified':
      case 'reviewed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  // END: Job Status Logic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Job Requests' : 'รายการงานที่รับ',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchJobRequests,
                          child: Text(widget.isEnglish ? 'Retry' : 'ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              : _currentJobRequests.isEmpty
                  ? Center(
                      child: Text(
                        widget.isEnglish ? 'No active job requests found.' : 'ไม่พบการจ้างงาน',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _fetchJobRequests(), // Enable pull-to-refresh
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _currentJobRequests.length,
                        itemBuilder: (context, index) {
                          final request = _currentJobRequests[index];
                          // Determine status color and text using the new helper methods
                          final String currentStatus =
                              request.jobStatus?.toLowerCase() ?? 'unknown';
                          final Color statusColor = _getStatusColor(currentStatus);
                          final String statusText = _getLocalizedJobStatus(currentStatus);

                          // ✅ แก้ไข: กำหนดตัวแปรสำหรับวันที่เริ่มงาน
                          final String formattedHireDate = request.hireDate != null
                              ? DateFormat('yyyy-MM-dd').format(request.hireDate!)
                              : (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล');

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.hireName ??
                                        (widget.isEnglish ? 'No Job Name' : 'ไม่มีชื่องาน'),
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          color: Colors.grey, size: 16.0),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        request.hirer?.person?.firstName != null &&
                                                request.hirer!.person!.lastName != null
                                            ? '${request.hirer!.person!.firstName} ${request.hirer!.person!.lastName}'
                                            : (widget.isEnglish
                                                ? 'Unknown Hirer'
                                                : 'ผู้จ้างไม่ทราบชื่อ'),
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          color: Colors.grey, size: 16.0),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          request.location ??
                                              (widget.isEnglish
                                                  ? 'No address provided'
                                                  : 'ไม่มีที่อยู่'),
                                          style: const TextStyle(fontSize: 14.0),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_outlined,
                                          color: Colors.grey, size: 16.0),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        '${request.startTime ?? (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล')}',
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: Colors.grey, size: 16.0),
                                      const SizedBox(width: 8.0),
                                      // ✅ แก้ไข: แสดง Hire Date ที่ถูก format แล้ว
                                      Text(
                                        formattedHireDate,
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          color: Colors.grey, size: 16.0),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        '${widget.isEnglish ? 'Status' : 'สถานะ'}: $statusText',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        print('View Request Job for: ${request.hireName}');
                                        // Navigate to details page and wait for result
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => JobRequestDetailsPage(
                                              hire: request,
                                              isEnglish: widget.isEnglish,
                                            ),
                                          ),
                                        );
                                        // If result is true, refresh the list
                                        if (result == true) {
                                          _fetchJobRequests();
                                        }
                                      },
                                      icon: const Icon(Icons.visibility,
                                          color: Colors.white, size: 18.0),
                                      label: Text(
                                        widget.isEnglish ? 'View Request Job' : 'ดูรายละเอียดงาน',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color.fromARGB(255, 0, 207, 107),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 10.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// Extension เพื่อช่วยในการค้นหาใน List
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}