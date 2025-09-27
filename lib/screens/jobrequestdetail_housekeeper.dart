import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hire.dart'; // Import Hire model
import 'package:maebanjumpen/controller/hireController.dart'; // Import Hirecontroller
import 'package:maebanjumpen/screens/workprogress_housekeeper.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart'; // Import AppColors
import 'package:intl/intl.dart'; // Import this for date formatting

class JobRequestDetailsPage extends StatefulWidget {
  final Hire hire; // The Hire object passed from the previous screen
  final bool isEnglish; // Language preference

  const JobRequestDetailsPage({
    super.key,
    required this.hire,
    required this.isEnglish,
  });

  @override
  State<JobRequestDetailsPage> createState() => _JobRequestDetailsPageState();
}

class _JobRequestDetailsPageState extends State<JobRequestDetailsPage> {
  // Local state variable to manage the job data and its status
  late Hire _currentHire;
  final Hirecontroller _hireController = Hirecontroller();
  bool _isLoading = false; // To show a loading indicator during the API call

  @override
  void initState() {
    super.initState();
    // Initialize the local state with the data from the widget
    _currentHire = widget.hire;
  }

  // START: Job Status Logic - for consistent UI display
  String _getLocalizedJobStatus(String status, bool isEnglish) {
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

    return isEnglish
        ? enMap[status.toLowerCase()] ?? status
        : thMap[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'upcoming':
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

  // Function to update the job status via API
  Future<void> _updateJobStatus(String newStatus) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      if (_currentHire.hireId == null) {
        throw Exception(widget.isEnglish ? 'Hire ID is null.' : 'ไม่พบรหัสงาน.');
      }

      // Create a new Hire object with the updated status
      final updatedHire = _currentHire.copyWith(jobStatus: newStatus);

      // Call the updateHire method in the controller
      final response = await _hireController.updateHire(_currentHire.hireId!, updatedHire);

      if (response != null && response.jobStatus == newStatus) {
        // Update the local state with the new data from the API response
        setState(() {
          _currentHire = response;
        });

        _showSnackBar(
            widget.isEnglish
                ? 'Job status updated to ${_getLocalizedJobStatus(newStatus, widget.isEnglish)}.'
                : 'อัปเดตสถานะงานเป็น ${_getLocalizedJobStatus(newStatus, widget.isEnglish)} แล้ว.',
            Colors.green);

        // Pop the current page and pass a result to the previous screen
        // to signal that it should refresh its data.
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
            widget.isEnglish
                ? 'Failed to update job status.'
                : 'ไม่สามารถอัปเดตสถานะงานได้.',
            Colors.red);
      }
    } catch (e) {
      _showSnackBar(
          widget.isEnglish
              ? 'Error updating job status: $e'
              : 'เกิดข้อผิดพลาดในการอัปเดตสถานะงาน: $e',
          Colors.red);
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Function to show a SnackBar notification
  void _showSnackBar(String message, Color color) {
    if (!mounted) return; // Prevents showing a SnackBar if the widget is not in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color and text for the current job
    final String currentStatus = _currentHire.jobStatus?.toLowerCase() ?? 'unknown';
    final Color statusColor = _getStatusColor(currentStatus);
    final String statusText = _getLocalizedJobStatus(currentStatus, widget.isEnglish);

    // Format the date
    String formattedDate = '';
    if (_currentHire.startDate != null) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      formattedDate = formatter.format(_currentHire.startDate!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Job Details' : 'รายละเอียดงาน',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30.0,
                          backgroundImage: (_currentHire.hirer?.person?.pictureUrl != null && _currentHire.hirer!.person!.pictureUrl!.isNotEmpty)
                              ? NetworkImage(_currentHire.hirer!.person!.pictureUrl!)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentHire.hirer?.person?.firstName != null && _currentHire.hirer!.person!.lastName != null
                                  ? '${_currentHire.hirer!.person!.firstName} ${_currentHire.hirer!.person!.lastName}'
                                  : (widget.isEnglish ? 'Unknown Hirer' : 'ผู้จ้างไม่ทราบชื่อ'),
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14.0),
                                const SizedBox(width: 4.0),
                                Text(
                                  _currentHire.location ?? (widget.isEnglish ? 'No address provided' : 'ไม่มีที่อยู่'),
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: Colors.blue, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          '${widget.isEnglish ? 'Service Name' : 'ชื่องาน'}: ',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _currentHire.hireName ?? (widget.isEnglish ? 'No Service Name' : 'ไม่มีชื่อบริการ'),
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 14.0),
                        const SizedBox(width: 4.0),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, color: Colors.grey, size: 14.0),
                        const SizedBox(width: 4.0),
                        Text(
                          '${_currentHire.startTime ?? (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล')} ',
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.isEnglish ? 'Requirements:' : 'ความต้องการ:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    if (_currentHire.hireDetail != null && _currentHire.hireDetail!.isNotEmpty)
                      ..._currentHire.hireDetail!
                          .split(',')
                          .map((service) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16.0),
                                    const SizedBox(width: 8.0),
                                    Text(service.trim()),
                                  ],
                                ),
                              )),
                    if (_currentHire.hireDetail == null || _currentHire.hireDetail!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(widget.isEnglish ? 'No specific requirements.' : 'ไม่มีข้อกำหนดพิเศษ'),
                      ),
                    const SizedBox(height: 16.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.attach_money, color: Colors.yellow, size: 20.0),
                        const SizedBox(width: 4.0),
                        Text(
                          _currentHire.paymentAmount != null ? '${_currentHire.paymentAmount}' : (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล'),
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.isEnglish ? 'Current Status' : 'สถานะปัจจุบัน'}: ',
                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24.0),

                    // Display buttons based on current job status
                    if (currentStatus == 'pending')
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _updateJobStatus('upcoming'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  ),
                                  child: Text(
                                    widget.isEnglish ? 'Accept Job' : 'รับงาน',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _updateJobStatus('rejected'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  ),
                                  child: Text(
                                    widget.isEnglish ? 'Reject Job' : 'ปฏิเสธงาน',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    
                    if (currentStatus == 'upcoming' || currentStatus == 'in_progress')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkProgressScreen(
                                  hire: _currentHire,
                                  isEnglish: widget.isEnglish,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          child: Text(
                            currentStatus == 'upcoming'
                                ? (widget.isEnglish ? 'Start Work' : 'เริ่มงาน')
                                : (widget.isEnglish ? 'Continue Work Report' : 'ทำรายงานต่อ'),
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) // Show Full-screen loading overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
