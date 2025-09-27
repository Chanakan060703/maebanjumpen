import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/hireController.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง
import 'package:maebanjumpen/model/hire.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง
import 'package:maebanjumpen/model/hirer.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง
import 'package:intl/intl.dart'; // อย่าลืมเพิ่ม dependency ใน pubspec.yaml
// import 'dart:convert'; // ไม่จำเป็นต้องใช้แล้ว ถ้าไม่ได้จัดการ Base64 ที่นี่
import 'package:maebanjumpen/constant/constant_value.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง
import 'package:maebanjumpen/screens/profile_member.dart'; // ตรวจสอบเส้นทางว่าถูกต้อง

class ViewhireHousekeeperPage extends StatefulWidget {
  final Hire hire;
  final bool isEnglish;
  final Hirer user;

  const ViewhireHousekeeperPage({
    super.key,
    required this.hire,
    required this.isEnglish,
    required this.user,
  });

  @override
  State<ViewhireHousekeeperPage> createState() => _ViewhireHousekeeperPageState();
}

class _ViewhireHousekeeperPageState extends State<ViewhireHousekeeperPage> {
  final Hirecontroller _hireController = Hirecontroller();
  late Hire _currentHire;
  int _currentIndex = 2; // สำหรับ BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _currentHire = widget.hire; // กำหนดค่าเริ่มต้นจาก widget.hire ที่ส่งเข้ามา
  }

  // เมธอดสำหรับแสดง Alert ยืนยันการยกเลิก
  void _showCancelAlert(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CancelHireAlert(isEnglish: widget.isEnglish);
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        // ใช้ copyWith เพื่อสร้าง Hire object ใหม่ที่เปลี่ยนแค่ jobStatus
        final updatedHire = _currentHire.copyWith(jobStatus: 'Cancelled');

        try {
          // ตรวจสอบว่า hireId ไม่เป็น null ก่อนส่ง
          if (_currentHire.hireId == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.isEnglish ? 'Error: Hire ID is missing.' : 'ข้อผิดพลาด: ไม่พบรหัสการจ้างงาน')),
            );
            return;
          }

          final Hire? resultHire = await _hireController.updateHire(_currentHire.hireId!, updatedHire);

          if (resultHire != null) {
            if (!mounted) return;

            // อัปเดตสถานะของ _currentHire ในหน้านี้ทันที
            setState(() {
              _currentHire = resultHire; // ใช้ resultHire ที่ได้รับกลับมา (ถ้า Backend คืน Hire object ที่อัปเดตแล้ว)
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.isEnglish ? 'Hire cancelled successfully!' : 'ยกเลิกการจ้างงานสำเร็จ!')),
            );
            // สำคัญ: pop หน้าปัจจุบันออกไปพร้อมส่งค่า true กลับไปยังหน้า HireListPage
            // เพื่อให้ HireListPage รู้ว่าต้องรีเฟรชข้อมูล
            Navigator.pop(context, true);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.isEnglish ? 'Failed to cancel hire.' : 'ไม่สามารถยกเลิกได้')),
            );
          }
        } catch (e) {
          debugPrint('Error during hire cancellation: $e'); // สำหรับ Debug
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isEnglish ? 'Network error or unable to cancel.' : 'เกิดข้อผิดพลาดเครือข่ายหรือไม่สามารถยกเลิกได้')),
          );
        }
      }
    });
  }

  // เมธอดสำหรับจัดรูปแบบวันที่ (รองรับภาษาไทย/อังกฤษ)
  String _formatDate(DateTime? date) {
    if (date == null) return widget.isEnglish ? 'N/A' : 'ไม่ระบุ';
    if (widget.isEnglish) {
      return DateFormat.yMMMd('en_US').format(date);
    } else {
      // สำหรับภาษาไทย, เปลี่ยนปีเป็นพุทธศักราช
      // ตรวจสอบว่า 'th_TH' locale ถูกโหลดและ supported ใน MaterialApp ของคุณ
      final String formattedDate = DateFormat('dd MMM', 'th_TH').format(date);
      final int buddhistYear = date.year + 543;
      return '$formattedDate $buddhistYear';
    }
  }

  // ฟังก์ชันช่วยเหลือเพื่อรับ ImageProvider ที่เหมาะสม
  ImageProvider _getHousekeeperProfileImage(String? pictureUrl) {
    if (pictureUrl != null && pictureUrl.isNotEmpty &&
        (pictureUrl.startsWith('http://') || pictureUrl.startsWith('https://'))) {
      return NetworkImage(pictureUrl);
    }
    debugPrint('Warning: Invalid or empty image URL. Using placeholder: $pictureUrl');
    // ตรวจสอบว่า 'assets/images/default_profile.png' มีอยู่จริงในโปรเจกต์ของคุณและได้ระบุใน pubspec.yaml
    return const AssetImage('assets/images/default_profile.png');
  }

  // เมธอดสำหรับคืนค่าสีตามสถานะงาน (Job Status)
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'pendingapproval':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'verified':
        return Colors.teal;
      case 'rejected':
        return Colors.deepOrange;
      case 'reviewed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // เมธอดสำหรับแสดงสถานะงานในภาษาที่เลือก
  String _getLocalizedJobStatus(String? status) {
    Map<String, String> enMap = {
      'pending': 'Pending',
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'in_progress': 'In Progress',
      'verified': 'Verified',
      'rejected': 'Rejected',
      'pendingapproval': 'Pending Approval',
      'reviewed': 'Reviewed',
    };

    Map<String, String> thMap = {
      'pending': 'กำลังดำเนินการ',
      'upcoming': 'กำลังจะมาถึง',
      'completed': 'เสร็จสิ้น',
      'cancelled': 'ยกเลิกแล้ว',
      'in_progress': 'กำลังดำเนินการ',
      'verified': 'ได้รับการยืนยัน',
      'rejected': 'ถูกปฏิเสธ',
      'pendingapproval': 'รอการอนุมัติ',
      'reviewed': 'รีวิวแล้ว',
    };
    final lowerStatus = status?.toLowerCase() ?? 'unknown';
    return widget.isEnglish
        ? enMap[lowerStatus] ?? lowerStatus
        : thMap[lowerStatus] ?? lowerStatus;
  }

  @override
  Widget build(BuildContext context) {
    final hire = _currentHire; // ใช้ _currentHire ที่เป็น mutable state

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () {
            // เมื่อกดปุ่มย้อนกลับ ให้ pop หน้าออกไปพร้อมค่า true เพื่อให้หน้า HireListPage รีเฟรชข้อมูล
            Navigator.pop(context, true);
          },
        ),
        title: Text(
          widget.isEnglish ? 'View Hire Details' : 'รายละเอียดการจ้าง',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนรูปโปรไฟล์และชื่อ
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _getHousekeeperProfileImage(hire.housekeeper?.person?.pictureUrl), // ใช้ profileImageUrl
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading housekeeper profile image: $exception');
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (hire.housekeeper?.person?.firstName != null && hire.housekeeper?.person?.lastName != null)
                          ? '${hire.housekeeper!.person!.firstName} ${hire.housekeeper!.person!.lastName}'
                          : (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'), // ใช้ personName
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(hire.startDate), // ใช้ hire.startDate
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${hire.startTime ?? ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),

            // สถานะงาน
            _buildDetailRow(
              widget.isEnglish ? 'Job Status' : 'สถานะงาน',
              _getLocalizedJobStatus(hire.jobStatus),
              color: _getStatusColor(hire.jobStatus),
            ),
            const SizedBox(height: 16),

            // รายละเอียดบริการ
            _buildInfoCard(hire),
            const SizedBox(height: 16),

            // รายการบริการที่รวม (Updated to include hireName and hireDetail)
            _buildServiceIncludedCard(hire), // Pass the hire object
            const SizedBox(height: 24),

            // ปุ่ม Cancel
            // แสดงปุ่ม Cancel เฉพาะเมื่อ jobStatus เป็น 'pending' หรือ 'in_progress'
            if (hire.jobStatus?.toLowerCase() == 'pending' ||
                hire.jobStatus?.toLowerCase() == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCancelAlert(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.isEnglish ? 'Cancel' : 'ยกเลิก',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _currentIndex = index);
          Widget nextPage;
          switch (index) {
            case 0:
              nextPage = HomePage(user: widget.user, isEnglish: widget.isEnglish);
              break;
            case 1:
              nextPage = DepositMemberPage(user: widget.user, isEnglish: widget.isEnglish);
              break;
            case 2:
            // เมื่อกด Tab Hirelist ให้ไปที่ HireListPage โดยใช้ pushReplacement
            // เพื่อไม่ให้ซ้อนหน้าเดิมซ้ำๆ ใน Stack
              nextPage = HireListPage(user: widget.user, isEnglish: widget.isEnglish,);
              break;
            case 3:
              nextPage = ProfileMemberPage(user: widget.user, isEnglish: widget.isEnglish);
              break;
            default:
              return;
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextPage));
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: widget.isEnglish ? 'Home' : 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), label: widget.isEnglish ? 'Cards' : 'บัตร'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: widget.isEnglish ? 'Hire' : 'การจ้าง'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: widget.isEnglish ? 'Profile' : 'โปรไฟล์'),
        ],
      ),
    );
  }

  // เมธอดช่วยเหลือสำหรับแสดงรายละเอียดเป็น Row
  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // กำหนดความกว้างคงที่สำหรับ label
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card สำหรับแสดงรายละเอียดบริการ
  Widget _buildInfoCard(Hire hire) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.isEnglish ? 'Service Details' : 'รายละเอียดบริการ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(hire.location ?? (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'), style: TextStyle(color: Colors.grey[600])))
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.timer_outlined, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${hire.startTime ?? ''} ', style: TextStyle(color: Colors.grey[600])),
          ]),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '฿${hire.paymentAmount?.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Card สำหรับแสดงรายการบริการที่รวม
  // Modified to include hireName and hireDetail
  Widget _buildServiceIncludedCard(Hire hire) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.isEnglish ? 'Service Includes' : 'บริการที่รวม',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // Display hireName
          if (hire.hireName != null && hire.hireName!.isNotEmpty)
            ServiceItem(text: '${widget.isEnglish ? 'Service Name: ' : 'ชื่อบริการ: '}${hire.hireName!}', isEnglish: widget.isEnglish),
          // Display hireDetail
          if (hire.hireDetail != null && hire.hireDetail!.isNotEmpty)
            ServiceItem(text: '${widget.isEnglish ? 'Details: ' : 'รายละเอียด: '}${hire.hireDetail!}', isEnglish: widget.isEnglish),

        ],
      ),
    );
  }
}

// Widget สำหรับแสดงแต่ละรายการบริการ
class ServiceItem extends StatelessWidget {
  final String text;
  final bool isEnglish;

  const ServiceItem({super.key, required this.text, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line text
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.red, size: 20), // Adjusted icon size slightly
          const SizedBox(width: 8),
          Expanded( // Use Expanded for text that might wrap
            child: Text(text, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

// Alert Dialog สำหรับยืนยันการยกเลิก
class CancelHireAlert extends StatelessWidget {
  final bool isEnglish;

  const CancelHireAlert({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEnglish ? 'Confirm Cancellation' : 'ยืนยันการยกเลิก'),
      content: Text(isEnglish ? 'Are you sure you want to cancel this hire?' : 'คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการจ้างงานนี้?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // ผู้ใช้ไม่ยืนยัน
          child: Text(isEnglish ? 'No' : 'ไม่'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // ผู้ใช้ยืนยัน
          child: Text(isEnglish ? 'Yes' : 'ใช่'),
        ),
      ],
    );
  }
}