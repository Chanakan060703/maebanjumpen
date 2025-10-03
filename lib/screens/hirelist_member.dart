import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/controller/reportController.dart';
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
  // --- [สำคัญ] เพิ่มตัวแปรสำหรับ Report Controller และสถานะการรายงาน ---
  final ReportController _reportApi = ReportController();
  Map<int, bool> _hasReported = {}; // <Hire ID, Is Reported by current user>
  bool _isCheckingReports = false; // สถานะกำลังเช็ค API รายงานซ้ำ

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

  // --- [แก้ไข] อัปเดต _fetchHires เพื่อเรียกใช้ API ตรวจสอบการรายงานซ้ำ ---
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
        
        // 1. อัปเดตรายการ Hire
        setState(() {
          _allHires = fetchedHires;
          _applyFilter(_selectedFilter);
        });
        
        // 2. ตรวจสอบสถานะการรายงานซ้ำ (จะอัปเดต _hasReported ทั้งหมด)
        await _checkAllReportStatuses(_allHires);

        // 3. ตรวจสอบการเปลี่ยนแปลงสถานะสำหรับแจ้งเตือน
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

  // --- [แก้ไข] เมธอดสำหรับดึงสถานะการรายงานซ้ำจาก API (ใช้สำหรับรีเฟรชสถานะปุ่ม) ---
  Future<void> _checkAllReportStatuses(List<Hire> hires) async {
    if (_isCheckingReports) return;
    setState(() => _isCheckingReports = true);

    final reporterId = widget.user.id; // ใช้ Hirer ID เป็น Reporter ID

    if (reporterId == null || reporterId == 0) {
      if (mounted) setState(() => _isCheckingReports = false);
      return;
    }

    // สร้าง Map ชั่วคราวสำหรับสถานะใหม่
    final Map<int, bool> newReportStatuses = {}; 

    // ใช้ Future.wait เพื่อเรียก API พร้อมกันทุกรายการ
    List<Future<void>> checks = [];

    for (var hire in hires) {
      final hireId = hire.hireId;
      if (hireId != null && hireId != 0) {
        // เช็คสถานะการรายงานใหม่ทั้งหมด
        checks.add(_reportApi.hasReported(hireId, reporterId).then((isReported) {
          if (mounted) {
            newReportStatuses[hireId] = isReported;
          }
        }).catchError((e) {
          print('Error checking report for Hire ID $hireId: $e');
          if (mounted) {
            newReportStatuses[hireId] = false; // ถ้าเกิด Error ให้ถือว่ายังไม่ได้รายงาน
          }
        }));
      }
    }

    await Future.wait(checks);

    if (mounted) {
      setState(() {
        // อัปเดต Map หลักด้วยผลลัพธ์ใหม่ทั้งหมด
        _hasReported = newReportStatuses; 
        _isCheckingReports = false;
      });
    }
  }


  Future<void> _updateHireStatus(String hireId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('$baseURL/maeban/hires/$hireId/status'),
        headers: headers,
        body: jsonEncode({'jobStatus': newStatus}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage(
              widget.isEnglish
                  ? 'Hire status updated to ${_getLocalizedJobStatus(newStatus)}.'
                  : 'อัปเดตสถานะการจ้างเป็น ${_getLocalizedJobStatus(newStatus)} แล้ว',
              );
        await _fetchHires();
      } else {
        _showMessage(
              widget.isEnglish
                  ? 'Failed to update hire status. Status: ${response.statusCode}'
                  : 'ไม่สามารถอัปเดตสถานะการจ้างได้. สถานะ: ${response.statusCode}',
              );
        print('Failed to update status: ${response.body}');
      }
    } catch (e) {
      print('Error updating status: $e');
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

      final String eventKeyPrefix = 'hire_${newHire.hireId}';

      if (oldHire == null) {
        notificationManager.addNotification(
          title:
              widget.isEnglish ? 'New Hire Created!' : 'สร้างการจ้างใหม่แล้ว!',
          body:
              widget.isEnglish
                  ? 'You have created a new hire: "${newHire.hireName ?? 'Unnamed Hire'}" with status "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}".'
                  : 'คุณได้สร้างการจ้างใหม่: "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" สถานะ "${_getLocalizedJobStatus(newHire.jobStatus ?? '')}"',
          payload: 'new_hire_created_${newHire.hireId}',
          showNow: true,
          eventKey: '${eventKeyPrefix}_created',
        );
      } else if (oldHire.jobStatus != newHire.jobStatus) {
        final String oldStatusLocalized = _getLocalizedJobStatus(
              oldHire.jobStatus ?? '',
            );
        final String newStatusLocalized = _getLocalizedJobStatus(
              newHire.jobStatus ?? '',
            );

        notificationManager.addNotification(
          title:
              widget.isEnglish
                  ? 'Hire Status Updated!'
                  : 'สถานะการจ้างอัปเดตแล้ว!',
          body:
              widget.isEnglish
                  ? 'The hire "${newHire.hireName ?? 'Unnamed Hire'}" has changed from "$oldStatusLocalized" to "$newStatusLocalized".'
                  : 'การจ้าง "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" เปลี่ยนสถานะจาก "$oldStatusLocalized" เป็น "$newStatusLocalized" แล้ว',
          payload: 'hire_status_update_${newHire.hireId}',
          showNow: true,
          eventKey: '${eventKeyPrefix}_status_change_${newHire.jobStatus}',
        );
      }
      if (oldHire?.review == null && newHire.review != null) {
        notificationManager.addNotification(
          title: widget.isEnglish ? 'Hire Reviewed!' : 'มีการรีวิวการจ้างแล้ว!',
          body:
              widget.isEnglish
                  ? 'The hire "${newHire.hireName ?? 'Unnamed Hire'}" has been reviewed.'
                  : 'การจ้าง "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" ได้รับการรีวิวแล้ว',
          payload: 'hire_reviewed_${newHire.hireId}',
          showNow: true,
          eventKey: '${eventKeyPrefix}_reviewed',
        );
      }
      // ตรวจสอบ Report จากสถานะที่มาจาก Back-end (หากมี)
      if (oldHire?.report == null && newHire.report != null) {
        notificationManager.addNotification(
          title: widget.isEnglish ? 'Hire Reported!' : 'มีการรายงานการจ้าง!',
          body:
              widget.isEnglish
                  ? 'The hire "${newHire.hireName ?? 'Unnamed Hire'}" has been reported.'
                  : 'การจ้าง "${newHire.hireName ?? 'การจ้างที่ไม่มีชื่อ'}" ได้รับการรายงานแล้ว',
          payload: 'hire_reported_${newHire.hireId}',
          showNow: true,
          eventKey: '${eventKeyPrefix}_reported',
        );
      }
    }
  }

  String _formatTimeWithoutSeconds(String timeString) {
    if (timeString.isEmpty) return '';

    return timeString
        .split(' - ')
        .map((part) {
          final parts = part.split(':');
          if (parts.length >= 2) {
            return '${parts[0]}:${parts[1]}';
          }
          return part;
        })
        .join(' - ');
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
        _filteredHires =
            _allHires.where((hire) {
              final jobStatus = hire.jobStatus?.toLowerCase();
              switch (filterLower) {
                case 'upcoming':
                  return jobStatus == 'pending' || jobStatus == 'accepted';
                case 'completed':
                  return jobStatus == 'completed' || jobStatus == 'reviewed' || jobStatus == 'verified';
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
                case 'accepted':
                  return jobStatus == 'accepted';
                case 'pending':
                  return jobStatus == 'pending';
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
          'accepted': 1,
          'pendingapproval': 2,
          'in_progress': 3,
          'reported': 4, // จัดลำดับให้ Reported อยู่สูงกว่า Completed ชั่วคราว
          'completed': 5,
          'reviewed': 6,
          'verified': 7,
          'cancelled': 8,
          'rejected': 9,
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
      'reported': 'Reported (Temp)',
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
      'reported': 'ถูกรายงาน (ชั่วคราว)',
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
      case 'reported':
        return Colors.deepOrange;
      case 'accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildFilterButtons() {
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Upcoming',
      'Pending Approval',
      'In Progress',
      'Completed',
      'Cancelled',
      'Rejected',
    ];
    return filters.map((filter) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterButton(
          text:
              widget.isEnglish
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
          builder:
              (context) => ReportHousekeeperPage(
                hire: hire,
                isEnglish: widget.isEnglish,
                hirerUser: widget.user,
              ),
        ),
      );

      // เมื่อกลับมาจากหน้า Report ให้ทำการดึงรายการใหม่เพื่ออัปเดตสถานะการรายงาน
      if (result == true) {
        // อัปเดตสถานะการรายงานใน Map ทันทีเพื่อซ่อนปุ่ม (เพื่อให้ปุ่มหายไปทันทีโดยไม่ต้องรอ API)
        if (hire.hireId != null && mounted) {
          setState(() {
            _hasReported[hire.hireId!] = true;
          });
        }
        _fetchHires(); // ดึงข้อมูลใหม่จากเซิร์ฟเวอร์
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEnglish
                  ? 'Housekeeper information is missing, cannot report.'
                  : 'ไม่พบข้อมูลแม่บ้าน ไม่สามารถรายงานได้',
              ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleVerify(BuildContext context, Hire hire) {
    if (hire.hireId == null) {
      _showMessage(
            widget.isEnglish ? 'Hire ID is missing.' : 'ไม่พบรหัสการจ้าง',
            );
      return;
    }

    if (hire.jobStatus?.toLowerCase() == 'pendingapproval') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
                widget.isEnglish ? 'Confirm Verification' : 'ยืนยันการตรวจสอบ',
                ),
            content: Text(
                widget.isEnglish
                    ? 'Are you sure you want to verify this completed job?'
                    : 'คุณแน่ใจหรือไม่ที่จะยืนยันงานที่เสร็จสิ้นแล้วนี้?',
                ),
            actions: <Widget>[
              TextButton(
                child: Text(widget.isEnglish ? 'Cancel' : 'ยกเลิก'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(
                  widget.isEnglish ? 'Verify' : 'ตรวจสอบ',
                  style: const TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateHireStatus(hire.hireId!.toString(), 'verified');
                },
              ),
            ],
          );
        },
      );
    } else {
      _showMessage(
            widget.isEnglish
                ? 'This hire is not in "Pending Approval" status.'
                : 'การจ้างนี้ไม่ได้อยู่ในสถานะ "รอการอนุมัติ"',
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
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => HomePage(
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
              child:
                  _isLoading || _isCheckingReports 
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        )
                      : _filteredHires.isEmpty
                          ? Center(
                              child: Text(
                                widget.isEnglish
                                    ? 'No hires found.'
                                    : 'ไม่พบรายการจ้าง',
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredHires.length,
                              itemBuilder: (context, index) {
                                final hire = _filteredHires[index];
                                final status = hire.jobStatus?.toLowerCase() ?? '';
                                
                                // ตรวจสอบสถานะการรายงานจาก Map (ซึ่งถูกรีเฟรชจาก API แล้ว)
                                final bool isReportedByMe = _hasReported[hire.hireId] ?? false; 
                                
                                final bool hasReview = hire.review != null;

                                final String displayTime = _formatTimeWithoutSeconds(
                                  '${hire.startTime ?? ''} ${hire.endTime != null ? '- ${hire.endTime}' : ''}',
                                );
                                
                                // ตรรกะการซ่อนปุ่ม: ซ่อนถ้าผู้ใช้คนนี้เคยรายงานไปแล้ว
                                final bool shouldHideReport = isReportedByMe;

                                return JobCard(
                                  name:
                                      hire.housekeeper?.person?.firstName ?? hire.housekeeper?.person?.lastName ??
                                      (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'),
                                  date: _formatDate(hire.startDate),
                                  time: displayTime,
                                  address:
                                      hire.location ??
                                      (widget.isEnglish
                                          ? 'Unknown Address'
                                          : 'ที่อยู่ไม่ระบุ'),
                                  status: _getLocalizedJobStatus(status),
                                  price:
                                      '฿${hire.paymentAmount?.toStringAsFixed(0) ?? '0'}',
                                  imageUrl: hire.housekeeper?.person?.pictureUrl,
                                  serviceName:
                                      hire.hireName ??
                                      (widget.isEnglish
                                          ? 'Unnamed Service'
                                          : 'บริการที่ไม่มีชื่อ'),
                                  details:
                                      hire.hireDetail ??
                                      (widget.isEnglish
                                          ? 'No details'
                                          : 'ไม่มีรายละเอียด'),
                                  statusColor: _getStatusColor(status),
                                  showVerifyButton: status == 'pendingapproval',
                                  
                                  onVerifyPressed: hire.hireId != null
                                      ? () => _handleVerify(context, hire)
                                      : null, 

                                  // ตรรกะการแสดงปุ่ม Report:
                                  showReportButton:
                                      (status == 'pendingapproval' ||
                                          status == 'completed' ||
                                          status == 'reviewed' ||
                                          status == 'in_progress' ||
                                          status == 'accepted') &&
                                          !shouldHideReport, // ซ่อนถ้าถูกรายงานแล้วโดยผู้ใช้คนนี้

                                  showReviewButton:
                                      status == 'completed' &&
                                          !hasReview &&
                                          status != 'reviewed',
                                  
                                  isEnglish: widget.isEnglish,
                                  hire: hire,
                                  hirerUser: widget.user,
                                  onReportPressed: () => _handleReport(context, hire),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ViewhireHousekeeperPage(
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
                                        builder:
                                            (context) => ReviewHousekeeperPage(
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