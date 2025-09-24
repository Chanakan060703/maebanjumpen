import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/report_member.dart';
import 'package:maebanjumpen/screens/reviewhousekeeper_member.dart';
import 'package:maebanjumpen/widgets/filter_hire_button.dart';
import 'package:maebanjumpen/widgets/hire_card.dart';
import 'package:maebanjumpen/screens/viewhirehousekeeper_member.dart';
import 'package:provider/provider.dart';

class HireListPage extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const HireListPage({super.key, this.isEnglish = true, required this.user});

  @override
  _HireListPageState createState() => _HireListPageState();
}

class _HireListPageState extends State<HireListPage> {
  int _currentIndex = 2;
  String _selectedFilter = 'All';
  List<Hire> _allHires = [];
  List<Hire> _filteredHires = [];
  List<Hire> _previousHires = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHires();
  }

  Future<void> _fetchHires() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      _previousHires = List.from(_allHires);

      final response = await http.get(
        Uri.parse('$baseURL/maeban/hires/hirer/${widget.user.id}'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        List<Hire> fetchedHires =
            jsonList.map((json) => Hire.fromJson(json)).toList();
        setState(() {
          _allHires = fetchedHires;
          _applyFilter(_selectedFilter);
        });
        _checkAndNotifyHireStatusChanges();
      } else {
        _showMessage(
          widget.isEnglish
              ? 'Failed to load hire list. Status: ${response.statusCode}'
              : 'ไม่สามารถโหลดรายการจ้างได้. สถานะ: ${response.statusCode}',
        );
        print('Failed to load hires: ${response.body}');
      }
    } catch (e) {
      print('Error fetching hires: $e');
      if (!mounted) return;
      _showMessage(
        widget.isEnglish
            ? 'Network error or unable to connect to the server.'
            : 'ข้อผิดพลาดเครือข่าย หรือไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _checkAndNotifyHireStatusChanges() {
    final notificationManager = Provider.of<NotificationManager>(
      context,
      listen: false,
    );

    for (final newHire in _allHires) {
      final oldHire = _previousHires.firstWhereOrNull(
        (h) => h.hireId == newHire.hireId,
      );

      final String eventKey =
          'hire_status_change_${newHire.hireId}_${newHire.jobStatus}';

      if (oldHire == null) {
        notificationManager.addNotification(
          title: widget.isEnglish ? 'New Hire Created!' : 'สร้างการจ้างใหม่แล้ว!',
          body: widget.isEnglish
              ? 'You have created a new hire: "${newHire.hireName ?? 'Unnamed Hire'}" with status "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}".'
              : 'คุณได้สร้างการจ้างใหม่: "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" สถานะ "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}"',
          payload: 'new_hire_created_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey,
        );
      } else if (oldHire.jobStatus != newHire.jobStatus) {
        final String oldStatusLocalized = _getLocalizedJobStatus(
          oldHire.jobStatus ?? '',
        );
        final String newStatusLocalized = _getLocalizedJobStatus(
          newHire.jobStatus ?? '',
        );

        notificationManager.addNotification(
          title: widget.isEnglish ? 'Hire Status Updated!' : 'สถานะการจ้างอัปเดตแล้ว!',
          body: widget.isEnglish
              ? 'The hire "${newHire.hireName ?? 'Unnamed Hire'}" has changed from "$oldStatusLocalized" to "$newStatusLocalized".'
              : 'การจ้าง "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" เปลี่ยนสถานะจาก "$oldStatusLocalized" เป็น "$newStatusLocalized" แล้ว',
          payload: 'hire_status_update_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey,
        );
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredHires = List.from(_allHires);
      } else {
        final filterLower = filter.toLowerCase();
        _filteredHires = _allHires.where((hire) {
          final jobStatus = hire.jobStatus?.toLowerCase();
          switch (filterLower) {
            case 'upcoming':
              return jobStatus == 'pending';
            case 'completed':
              return jobStatus == 'completed' || jobStatus == 'reviewed';
            case 'cancelled':
              return jobStatus == 'cancelled';
            case 'verified':
              return jobStatus == 'verified';
            case 'rejected':
              return jobStatus == 'rejected';
            case 'pending approval':
              return jobStatus == 'pendingapproval';
            case 'in progress':
              return jobStatus == 'in_progress';
            default:
              return false;
          }
        }).toList();
      }
      _filteredHires.sort((a, b) {
        final dateA = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);

        final dateComparison = dateB.compareTo(dateA);
        if (dateComparison != 0) {
          return dateComparison;
        }

        final statusOrder = {
          'pending': 0,
          'pendingapproval': 1,
          'in_progress': 2,
          'accepted': 3,
          'completed': 4,
          'reviewed': 5,
          'cancelled': 6,
          'rejected': 7,
          'verified': 8,
        };
        final orderA = statusOrder[a.jobStatus?.toLowerCase() ?? ''] ?? 99;
        final orderB = statusOrder[b.jobStatus?.toLowerCase() ?? ''] ?? 99;

        return orderA.compareTo(orderB);
      });
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return widget.isEnglish ? 'N/A' : 'ไม่ระบุ';
    if (widget.isEnglish) {
      return DateFormat.yMMMd('en_US').format(date);
    } else {
      final thaiYear = date.year + 543;
      return '${DateFormat('dd MMM', 'th_TH').format(date)} $thaiYear';
    }
  }

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
      case 'pending':
        return Colors.orange;
      case 'upcoming':
        return Colors.orange[700]!;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'pendingapproval':
        return Colors.yellow[700]!;
      case 'reviewed':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildFilterButtons() {
    final filters = [
      'All',
      'Upcoming',
      'Pending Approval',
      'In Progress',
      'Accepted',
      'Completed',
      'Reviewed',
      'Cancelled',
      'Rejected',
      'Verified',
    ];
    return filters.map((filter) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterButton(
          text: widget.isEnglish
              ? filter
              : _getLocalizedJobStatus(filter.toLowerCase()),
          isSelected: _selectedFilter == filter,
          onPressed: () => _applyFilter(filter),
        ),
      );
    }).toList();
  }

  void _handleReport(BuildContext context, Hire hire) async {
    if (hire.housekeeper != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportHousekeeperPage(
            hire: hire,
            isEnglish: widget.isEnglish,
            hirerUser: widget.user,
          ),
        ),
      );

      if (result == true) {
        _fetchHires();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Housekeeper information is missing.'
                : 'ไม่พบข้อมูลแม่บ้าน',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                user: widget.user,
                isEnglish: widget.isEnglish,
              ),
            ),
          ),
        ),
        title: Text(
          widget.isEnglish ? 'Hire List' : 'รายการจ้าง',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHires,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildFilterButtons()),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : _filteredHires.isEmpty
                      ? Center(
                          child: Text(
                            widget.isEnglish ? 'No hires found.' : 'ไม่พบรายการจ้าง',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredHires.length,
                          itemBuilder: (context, index) {
                            final hire = _filteredHires[index];
                            final status = hire.jobStatus?.toLowerCase() ?? '';

                            final bool hasReport = hire.report != null;
                            final bool hasReview = hire.review != null;

                            return JobCard(
                              name: hire.housekeeper?.person?.firstName ??
                                  (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'),
                              date: _formatDate(hire.startDate),
                              time:
                                  '${hire.startTime ?? ''} - ${hire.endTime ?? ''}',
                              address: hire.location ??
                                  (widget.isEnglish ? 'Unknown Address' : 'ที่อยู่ไม่ระบุ'),
                              status: _getLocalizedJobStatus(status),
                              price: '฿${hire.paymentAmount?.toStringAsFixed(0) ?? '0'}',
                              imageUrl: hire.housekeeper?.person?.pictureUrl,
                              details: hire.hireDetail ??
                                  (widget.isEnglish ? 'No details' : 'ไม่มีรายละเอียด'),
                              statusColor: _getStatusColor(status),
                              showVerifyButton: status == 'pendingapproval',
                              showReportButton: (status == 'pendingapproval' ||
                                  status == 'completed' ||
                                  status == 'reviewed') && !hasReport,
                              showReviewButton: status == 'completed' && !hasReview,
                              isEnglish: widget.isEnglish,
                              hire: hire,
                              hirerUser: widget.user,
                              onReportPressed: () => _handleReport(context, hire),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewhireHousekeeperPage(
                                      hire: hire,
                                      isEnglish: widget.isEnglish,
                                      user: widget.user,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchHires();
                                }
                              },
                              onReviewPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewHousekeeperPage(
                                      hire: hire,
                                      isEnglish: widget.isEnglish,
                                      user: widget.user,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchHires();
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

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