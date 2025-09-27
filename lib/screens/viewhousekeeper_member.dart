import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ต้องสร้าง ReviewListPage ด้วย
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirehousekeeper_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the new ReviewListPage
import 'package:maebanjumpen/screens/review_list_page.dart';

class ViewHousekeeperPage extends StatefulWidget {
  // ใช้อ็อบเจกต์ Housekeeper ที่ได้รับมาเป็น initial data
  final Housekeeper housekeeper;
  final bool isEnglish;
  final Hirer user;

  const ViewHousekeeperPage({
    super.key,
    required this.housekeeper,
    required this.isEnglish,
    required this.user,
  });

  @override
  State<ViewHousekeeperPage> createState() => _ViewHousekeeperPageState();
}

class _ViewHousekeeperPageState extends State<ViewHousekeeperPage> {
  // ใช้ตัวแปรนี้เก็บข้อมูลแม่บ้านล่าสุดที่ดึงมาจาก API
  late Housekeeper _housekeeperDetail;
  bool _isLoading = true; // เพิ่มตัวแปรโหลด

  // Map สำหรับรายละเอียดทักษะเพิ่มเติม
  final Map<String, Map<String, dynamic>> _skillDetails = {
    'GeneralCleaning': {
      'icon': Icons.cleaning_services,
      'thaiName': 'ทำความสะอาดทั่วไป',
    },
    'Laundry': {'icon': Icons.local_laundry_service, 'thaiName': 'ซักรีด'},
    'Cooking': {'icon': Icons.restaurant, 'thaiName': 'ทำอาหาร'},
    'Garden': {'icon': Icons.local_florist, 'thaiName': 'ดูแลสวน'},
    // เพิ่มทักษะอื่นๆ ที่มีใน Backend ที่นี่
  };

  // ดัชนีสำหรับ Bottom Navigation Bar (ถ้าไม่ใช้งานในหน้านี้ควรนำออก)
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ใช้ข้อมูลที่ส่งมาเป็นค่าเริ่มต้นก่อน
    _housekeeperDetail = widget.housekeeper;
    _fetchHousekeeperDetails();
    _printDebugInfo();
  }

  // ดึงข้อมูลรายละเอียดแม่บ้านล่าสุดจาก API
  Future<void> _fetchHousekeeperDetails() async {
    try {
      // บรรทัดนี้ถูกต้องแล้ว เมื่อเพิ่ม static method ใน HousekeeperController

      final updatedHousekeeper =
          await HousekeeperController.fetchHousekeeperWithDetails(
        widget.housekeeper.id!,
          );

      // ตรวจสอบว่า mounted เพื่อป้องกันการเรียก setState หลัง dispose

      if (mounted) {
        setState(() {
          // แก้ไขปัญหาเรื่อง Type 'Housekeeper?' is not assignable to type 'Housekeeper'

          // ด้วยการตรวจสอบ updatedHousekeeper ว่าไม่เป็น null ก่อน assign

          if (updatedHousekeeper != null) {
            _housekeeperDetail = updatedHousekeeper;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching housekeeper details: $e');

      if (mounted) {
        setState(() {
          _isLoading = false; // หยุดโหลดแม้มี error
        });
      }

      // สามารถแสดง AlertDialog หรือ Snackbar แจ้ง error ได้
    }
  }

  void _printDebugInfo() {
    // 💡 ฟังก์ชันนี้ถูกเรียกใน initState ครั้งเดียวเท่านั้น
    // ถ้าต้องการใช้ข้อมูลที่อัปเดต ต้องเรียกใช้ _housekeeperDetail แทน widget.housekeeper
    print('---Debugging Housekeeper Reviews in ViewHousekeeperPage---');
    print('Housekeeper ID: ${widget.housekeeper.id}');
    print(
      'Housekeeper Initial Rating (from Props): ${widget.housekeeper.rating}',
    );
    print('---End Debugging Housekeeper Reviews---');
  }

  // --- Helper Methods ---

  // เมธอดสำหรับแสดงภาพจาก Base64, URL หรือ Asset
  ImageProvider _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/image/icon_user.png');
    }

    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return NetworkImage(imageData);
    }

    if (imageData.contains('data:image/') || imageData.length > 100) {
      try {
        String base64Stripped =
            imageData.contains(',') ? imageData.split(',')[1] : imageData;
        final decodedBytes = base64Decode(base64Stripped);
        return MemoryImage(decodedBytes);
      } catch (e) {
        debugPrint('Error decoding Base64 image: $e');
        return const AssetImage('assets/image/icon_user.png');
      }
    }

    return const AssetImage('assets/image/icon_user.png');
  }

  // Helper method: ปัดเศษคะแนนเป็น 0.0, 0.5, 1.0, 1.5, ... 5.0 สำหรับแสดงผลดาว
  double _getDisplayScore(double? actualScore) {
    if (actualScore == null || actualScore <= 0.0) return 0.0;
    return (actualScore * 2).round() / 2.0;
  }

  // Widget สำหรับแสดงดาว
  Widget _buildStarRating(double displayRating, {double iconSize = 16.0}) {
    List<Widget> stars = [];
    int fullStars = displayRating.floor();
    bool hasHalfStar = (displayRating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: iconSize));
      } else if (hasHalfStar && i == fullStars) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: iconSize));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: iconSize));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  // เมธอดสำหรับเปิด URL (โทรศัพท์)
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty || url == 'N/A') {
      debugPrint('URL is empty or not available. Cannot launch.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
      // แสดงข้อความแจ้งเตือนถ้าเปิดไม่ได้
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Cannot perform action.'
                  : 'ไม่สามารถดำเนินการได้',
            ),
          ),
        );
      }
    }
  }

  // --- Widgets ---

  // Widget สำหรับแสดงรีวิวแต่ละรายการ
  Widget _buildReviewWidget({
    required String name,
    required String comment,
    required double rating,
    required DateTime? reviewDate,
    required String? avatarUrl,
  }) {
    final displayRatingForReview = _getDisplayScore(rating);
    String formattedReviewDate = '';

    if (reviewDate != null) {
      formattedReviewDate = DateFormat(
        widget.isEnglish ? 'MMM dd, yyyy' : 'd MMMM yyyy',
        widget.isEnglish ? 'en_US' : 'th_TH',
      ).format(reviewDate.toLocal());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _getImageProvider(avatarUrl),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading reviewer avatar image: $exception');
          },
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarRating(displayRatingForReview, iconSize: 16.0),
            const SizedBox(height: 4),
            Text(comment, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(
              formattedReviewDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับแสดงปุ่มติดต่อ (โทรศัพท์)
  Widget _buildContactButton(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String actionLabel,
  ) {
    String finalUrl = '';
    String displaySubtitle = subtitle;
    bool isUserLoggedIn = widget.user.person != null;
    bool isActionEnabled =
        isUserLoggedIn && subtitle != 'N/A' && subtitle != 'ไม่ระบุ';

    if (title == (widget.isEnglish ? "Phone Number" : "เบอร์โทรศัพท์")) {
      if (isUserLoggedIn) {
        finalUrl = 'tel:${subtitle.replaceAll(' ', '')}';
        displaySubtitle = subtitle;
      } else {
        displaySubtitle =
            widget.isEnglish ? "Login to view" : "เข้าสู่ระบบเพื่อดู";
        finalUrl = '';
        isActionEnabled = false;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(displaySubtitle),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              isActionEnabled
                  ? () {
                    _launchUrl(finalUrl);
                  }
                  : () {
                    if (!isUserLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    } else {
                      debugPrint(
                        'Action not available or phone number is N/A.',
                      );
                    }
                  },
          child: Text(
            isUserLoggedIn
                ? actionLabel
                : (widget.isEnglish ? 'Log In' : 'เข้าสู่ระบบ'),
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    // ใช้ข้อมูลจากตัวแปร State ที่ถูกอัปเดตแล้ว
    final Housekeeper housekeeper = _housekeeperDetail;

    // [Rating]
    final double? backendRating = housekeeper.rating;
    final double displayRating = _getDisplayScore(backendRating);
    final String displayRatingText =
        backendRating != null && backendRating > 0
            ? backendRating.toStringAsFixed(1)
            : "0.0";

    // [Jobs Done] นับงานที่สถานะ 'Completed' ทั้งหมด
    final int totalCompletedJobs =
        housekeeper.hires
            ?.where((hire) => hire.jobStatus == 'Completed')
            .length ??
        0;

    // Filter สำหรับรีวิวที่จะแสดงในหน้านี้ (Completed + มี Review)
    // 💡 ใช้ `_housekeeperDetail` ซึ่งเป็น State ที่อัปเดตแล้ว
    final completedReviews =
        _housekeeperDetail.hires
            ?.where(
              (hire) => hire.jobStatus == 'Completed' && hire.review != null,
            )
            .toList() ??
        [];

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Housekeeper Info' : 'ข้อมูลแม่บ้าน'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Housekeeper Info' : 'ข้อมูลแม่บ้าน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 60,
              backgroundImage: _getImageProvider(
                housekeeper.person?.pictureUrl,
              ),
              backgroundColor: Colors.red,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.isEnglish ? "Available" : "ว่างให้บริการ",
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStarRating(displayRating, iconSize: 18.0),
                const SizedBox(width: 4),
                // [แสดงคะแนนจริง]
                Text(
                  displayRatingText,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_pin, color: Colors.grey, size: 18),
                Text(
                  housekeeper.person?.address ??
                      (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        displayRatingText, // [แสดงคะแนนจริง]
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(widget.isEnglish ? "Average Rating" : "คะแนนเฉลี่ย"),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.work, color: Colors.red),
                      Text(
                        '$totalCompletedJobs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.isEnglish ? "Jobs Done" : "งานที่ทำ"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? "Skills" : "ความสามารถ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (housekeeper.housekeeperSkills != null &&
                      housekeeper.housekeeperSkills!.isNotEmpty)
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children:
                          housekeeper.housekeeperSkills!.map((skill) {
                            final String backendSkillName =
                                skill.skillType?.skillTypeName ?? '';
                            final String? skillLevelName =
                                skill.skillLevelTier?.skillLevelName;
                            final Map<String, dynamic>? details =
                                _skillDetails[backendSkillName];

                            final IconData icon =
                                details?['icon'] ?? Icons.build;
                            final String displayName =
                                widget.isEnglish
                                    ? backendSkillName.isNotEmpty
                                        ? backendSkillName
                                        : 'No skill name'
                                    : details?['thaiName'] ?? 'ไม่มีชื่อทักษะ';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: Colors.red, size: 24),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (skillLevelName != null)
                                        Text(
                                          skillLevelName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    )
                  else
                    Text(
                      widget.isEnglish
                          ? "No skills listed"
                          : "ไม่มีความสามารถระบุ",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEnglish ? "Starting from" : "เริ่มต้นที่",
                            style: const TextStyle(color: Colors.red),
                          ),
                          Text(
                            "${housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'}฿/${widget.isEnglish ? 'day' : 'วัน'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (widget.user.person == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        } else if (widget.user.balance != null &&
                            housekeeper.dailyRate != null &&
                            widget.user.balance! >= housekeeper.dailyRate!) {
                          // ใช้ housekeeper.dailyRate
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => HireHousekeeperPage(
                                    housekeeper:
                                        housekeeper, // ใช้ housekeeper จาก state
                                    isEnglish: widget.isEnglish,
                                    user: widget.user,
                                  ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  widget.isEnglish
                                      ? "Insufficient Balance"
                                      : "ยอดเงินไม่เพียงพอ",
                                ),
                                content: Text(
                                  widget.isEnglish
                                      ? "Your balance (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'}฿) is less than the housekeeper's daily rate (${housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'}฿). Please top up your balance."
                                      : "ยอดเงินของคุณ (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'}฿) ไม่เพียงพอต่อค่าบริการรายวันของแม่บ้าน (${housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'}฿) กรุณาเติมเงิน",
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      widget.isEnglish ? "OK" : "ตกลง",
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      widget.isEnglish ? "Deposit" : "เติมเงิน",
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => DepositMemberPage(
                                                user: widget.user,
                                                isEnglish: widget.isEnglish,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Text(widget.isEnglish ? "Hire" : "จ้างเลย"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนหัวข้อ "Reviews" และปุ่ม "Review All" ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEnglish ? "Reviews" : "รีวิว",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // แสดงปุ่ม "See All" ถ้ามีรีวิวที่ทำเสร็จแล้ว
                      if (completedReviews.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ReviewListPage(
                                      housekeeperName:
                                          "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}",
                                      reviews: completedReviews,
                                      isEnglish: widget.isEnglish,
                                    ),
                              ),
                            );
                          },
                          child: Text(
                            widget.isEnglish ? "See All" : "ดูทั้งหมด",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (completedReviews.isNotEmpty)
                    // แสดงรีวิว 3 อันแรกในหน้านี้ (ถ้ามี)
                    ...completedReviews
                        .take(3)
                        .map(
                          (hire) => _buildReviewWidget(
                            name:
                                "${hire.hirer?.person?.firstName ?? ''} ${hire.hirer?.person?.lastName ?? ''}",
                            // ใช้ข้อความแสดงผลที่เหมาะสมหาก reviewMessage เป็น null
                            comment:
                                hire.review?.reviewMessage ??
                                (widget.isEnglish
                                    ? 'No comment provided.'
                                    : 'ไม่มีความคิดเห็น'),
                            rating: hire.review?.score ?? 0.0,
                            avatarUrl: hire.hirer?.person?.pictureUrl,
                            reviewDate: hire.review?.reviewDate,
                          ),
                        )
                  else
                    Text(
                      widget.isEnglish ? "No reviews yet" : "ยังไม่มีรีวิว",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? "Contact Us" : "ติดต่อเรา",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildContactButton(
                    Icons.phone,
                    widget.isEnglish ? "Phone Number" : "เบอร์โทรศัพท์",
                    housekeeper.person?.phoneNumber ??
                        (widget.isEnglish ? "N/A" : "ไม่ระบุ"),
                    Colors.red,
                    widget.isEnglish ? "Call Now" : "โทรเลย",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        // 💡 ตั้งค่าให้ไม่มีการเลือกที่ ViewHousekeeperPage
        // _currentIndex ควรเป็น 0 หากเข้าหน้านี้จาก Home (ปกติ)
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Note: การใช้ pushReplacement ในหน้า Home จะดีกว่าเมื่อมีการเข้าถึงหน้านี้จาก Home
          // แต่ถ้าเข้าจาก HireList/Profile ควรใช้ Navigator.pop(context) หรือ pushReplacement(context, builder: (context) => HomeMember())
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      user: widget.user,
                      isEnglish: widget.isEnglish,
                    ),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DepositMemberPage(
                      user: widget.user,
                      isEnglish: widget.isEnglish,
                    ),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HireListPage(
                      isEnglish: widget.isEnglish,
                      user: widget.user,
                    ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProfileMemberPage(
                      user: widget.user,
                      isEnglish: widget.isEnglish,
                    ),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card),
            label: widget.isEnglish ? 'Cards' : 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: widget.isEnglish ? 'Hire' : 'การจ้าง',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
