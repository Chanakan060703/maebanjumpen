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
import 'package:maebanjumpen/screens/reviewhousekeeper_member.dart';
import 'package:maebanjumpen/widgets/filter_hire_button.dart';
import 'package:maebanjumpen/widgets/hire_card.dart';
import 'package:maebanjumpen/screens/viewhirehousekeeper_member.dart';
import 'package:provider/provider.dart'; // Import Provider

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
  List<Hire> _previousHires = []; // เพิ่ม List สำหรับเก็บสถานะก่อนหน้า
  bool _isLoading = false;

  // ไม่ต้องใช้ _notifiedEventKeys ที่นี่แล้ว เพราะจะย้ายไปจัดการใน NotificationManager
  // final Set<String> _notifiedEventKeys = {};

  @override
  void initState() {
    super.initState();
    // เรียก _fetchHires ทันทีเมื่อหน้าถูกสร้างขึ้น
    _fetchHires();
  }

  Future<void> _fetchHires() async {
    if (_isLoading) return; // ป้องกันการดึงข้อมูลซ้ำซ้อนหากกำลังโหลดอยู่แล้ว
    setState(() => _isLoading = true);
    try {
      // เก็บสถานะปัจจุบันก่อนดึงข้อมูลใหม่
      _previousHires = List.from(_allHires);

      final response = await http.get(
        Uri.parse('$baseURL/maeban/hires/hirer/${widget.user.id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        List<Hire> fetchedHires =
            jsonList.map((json) => Hire.fromJson(json)).toList();
        setState(() {
          _allHires = fetchedHires;
          _applyFilter(
              _selectedFilter); // ใช้ filter ที่เลือกไว้เพื่ออัปเดตรายการที่แสดง
        });
        _checkAndNotifyHireStatusChanges(); // ตรวจสอบการเปลี่ยนแปลงสถานะและส่งแจ้งเตือน
      } else {
        _showMessage(
          widget.isEnglish
              ? 'Failed to load hire list. Status: ${response.statusCode}'
              : 'ไม่สามารถโหลดรายการจ้างได้. สถานะ: ${response.statusCode}',
        );
        print('Failed to load hires: ${response.body}'); // สำหรับการดีบัก
      }
    } catch (e) {
      print('Error fetching hires: $e'); // สำหรับการดีบัก
      _showMessage(
        widget.isEnglish
            ? 'Network error or unable to connect to the server.'
            : 'ข้อผิดพลาดเครือข่าย หรือไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Checks for status changes between current and previous hire requests
  /// and sends notifications if changes are detected.
  void _checkAndNotifyHireStatusChanges() {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

    for (final newHire in _allHires) {
      final oldHire = _previousHires.firstWhereOrNull(
        (h) => h.hireId == newHire.hireId,
      );

      // สร้าง eventKey ที่ไม่ซ้ำกันสำหรับสถานะใหม่ของแต่ละ hire
      // รูปแบบ: 'hire_status_change_{hireId}_{jobStatus}'
      final String eventKey = 'hire_status_change_${newHire.hireId}_${newHire.jobStatus}';

      if (oldHire == null) {
        // This is a brand new hire request
        // ส่ง eventKey ไปยัง NotificationManager เพื่อให้จัดการการแจ้งเตือนซ้ำซ้อน
        notificationManager.addNotification(
          title: widget.isEnglish ? 'New Hire Created!' : 'สร้างการจ้างใหม่แล้ว!',
          body: widget.isEnglish
              ? 'You have created a new hire: "${newHire.hireName ?? 'Unnamed Hire'}" with status "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}".'
              : 'คุณได้สร้างการจ้างใหม่: "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" สถานะ "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}"',
          payload: 'new_hire_created_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey, // ส่ง eventKey ไปที่ NotificationManager
        );
      } else if (oldHire.jobStatus != newHire.jobStatus) {
        // Status has changed for an existing hire
        final String oldStatusLocalized = _getLocalizedJobStatus(oldHire.jobStatus ?? '');
        final String newStatusLocalized = _getLocalizedJobStatus(newHire.jobStatus ?? '');
        // ไม่ต้องใช้ _notifiedEventKeys.add(eventKey) ที่นี่แล้ว

        notificationManager.addNotification(
          title: widget.isEnglish ? 'Hire Status Updated!' : 'สถานะการจ้างอัปเดตแล้ว!',
          body: widget.isEnglish
              ? 'The hire "${newHire.hireName ?? 'Unnamed Hire'}" has changed from "$oldStatusLocalized" to "$newStatusLocalized".'
              : 'การจ้าง "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" เปลี่ยนสถานะจาก "$oldStatusLocalized" เป็น "$newStatusLocalized" แล้ว',
          payload: 'hire_status_update_${newHire.hireId}',
          showNow: true,
          eventKey: eventKey, // ส่ง eventKey ไปที่ NotificationManager
        );
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
      // เรียงลำดับรายการที่ถูกกรองเพื่อแสดงรายการล่าสุดก่อน ตามวันที่เริ่มงาน จากนั้นตามสถานะ
      _filteredHires.sort((a, b) {
        // 1. การเรียงลำดับหลัก: ตาม startDate ในลำดับจากมากไปน้อย (วันที่ล่าสุดก่อน)
        // ตรวจสอบวันที่ที่เป็น null และถือว่าเป็นวันที่เก่ามากสำหรับการเรียงลำดับ
        final dateA = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);

        final dateComparison = dateB.compareTo(dateA); // ลำดับจากมากไปน้อยสำหรับวันที่
        if (dateComparison != 0) {
          return dateComparison; // หากวันที่ต่างกัน ให้เรียงตามวันที่
        }

        // 2. การเรียงลำดับรอง (หากวันที่เหมือนกัน): ตาม jobStatus ตามลำดับที่กำหนดไว้
        final statusOrder = {
          'pending': 0,
          'pendingapproval': 1,
          'in_progress': 2,
          'accepted': 3, // เพิ่ม accepted
          'completed': 4,
          'reviewed': 5,
          'cancelled': 6,
          'rejected': 7,
          'verified': 8,
        };
        final orderA = statusOrder[a.jobStatus?.toLowerCase() ?? ''] ?? 99;
        final orderB = statusOrder[b.jobStatus?.toLowerCase() ?? ''] ?? 99;

        return orderA.compareTo(orderB); // ลำดับจากน้อยไปมากสำหรับลำดับสถานะ
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
      'all': 'All', // เพิ่ม 'All' สำหรับการแสดงผลปุ่ม filter
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'in_progress': 'In Progress',
      'verified': 'Verified',
      'rejected': 'Rejected',
      'pendingapproval': 'Pending Approval',
      'reviewed': 'Reviewed',
      'pending': 'Pending',
      'accepted': 'Accepted', // เพิ่ม accepted
    };

    Map<String, String> thMap = {
      'all': 'ทั้งหมด', // เพิ่ม 'ทั้งหมด' สำหรับการแสดงผลปุ่ม filter
      'upcoming': 'กำลังจะมาถึง',
      'completed': 'เสร็จสิ้น',
      'cancelled': 'ยกเลิกแล้ว',
      'in_progress': 'กำลังดำเนินการ',
      'verified': 'ได้รับการยืนยัน',
      'rejected': 'ถูกปฏิเสธ',
      'pendingapproval': 'รอการอนุมัติ',
      'reviewed': 'รีวิวแล้ว',
      'pending': 'รอดำเนินการ',
      'accepted': 'ตอบรับแล้ว', // เพิ่ม ตอบรับแล้ว
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
        return Colors.orange[700]!; // ใช้ ! สำหรับ non-nullable
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
        return Colors.yellow[700]!; // ใช้ ! สำหรับ non-nullable
      case 'reviewed':
        return Colors.purple;
      case 'accepted': // เพิ่ม accepted
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildFilterButtons() {
    final filters = [
      'All',
      'Upcoming',
      'Pending Approval', // เปลี่ยนลำดับสำหรับ workflow ทั่วไป
      'In Progress', // เพิ่ม in progress
      'Accepted', // เพิ่ม Accepted
      'Completed',
      'Reviewed', // เพิ่ม reviewed
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(user: widget.user, isEnglish: widget.isEnglish),
            ),
          ), // เปลี่ยนจาก pushReplacement เป็น pop
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
      body: RefreshIndicator( // เพิ่ม RefreshIndicator ที่นี่
        onRefresh: _fetchHires, // เมื่อดึงลงจะเรียก _fetchHires เพื่อรีเฟรชข้อมูล
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
                            return JobCard(
                              name: hire.housekeeper?.person?.firstName ??
                                  (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'),
                              date: _formatDate(hire.startDate),
                              time:
                                  '${hire.startTime ?? ''} - ${hire.endTime ?? ''}',
                              address: hire.location ??
                                  (widget.isEnglish
                                      ? 'Unknown Address'
                                      : 'ที่อยู่ไม่ระบุ'),
                              status: _getLocalizedJobStatus(status),
                              price:
                                  '฿${hire.paymentAmount?.toStringAsFixed(0) ?? '0'}',
                              imageUrl: hire.housekeeper?.person?.pictureUrl,
                              details: hire.hireDetail ??
                                  (widget.isEnglish ? 'No details' : 'ไม่มีรายละเอียด'),
                              statusColor: _getStatusColor(status),
                              showVerifyButton: status == 'pendingapproval',
                              showReportButton: status == 'pendingapproval' ||
                                  status == 'completed' ||
                                  status == 'reviewed',
                              showReviewButton: status == 'completed',
                              isEnglish: widget.isEnglish,
                              hire: hire, // ส่ง hire object ทั้งหมด
                              hirerUser: widget.user, // ส่ง hirerUser
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
                                // หาก ViewhireHousekeeperPage ส่งค่า true กลับมา (ซึ่งเกิดขึ้นเมื่อมีการยกเลิกสำเร็จ)
                                if (result == true) {
                                  _fetchHires(); // จะเรียก _fetchHires() เพื่อรีเฟรชข้อมูลล่าสุด
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
                                // หาก ReviewHousekeeperPage ส่งค่า true กลับมา (ซึ่งอาจจะเกิดขึ้นเมื่อมีการรีวิวแล้วเปลี่ยนสถานะ)
                                if (result == true) {
                                  _fetchHires(); // จะเรียก _fetchHires() เพื่อรีเฟรชข้อมูลล่าสุด
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
