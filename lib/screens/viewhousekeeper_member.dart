import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/review.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirehousekeeper_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maebanjumpen/screens/review_list_page.dart';

class ViewHousekeeperPage extends StatefulWidget {
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
  late Housekeeper _housekeeperDetail;
  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _skillDetails = {
    'GeneralCleaning': {
      'icon': Icons.cleaning_services,
      'thaiName': 'ทำความสะอาดทั่วไป',
    },
    'Laundry': {'icon': Icons.local_laundry_service, 'thaiName': 'ซักรีด'},
    'Cooking': {'icon': Icons.restaurant, 'thaiName': 'ทำอาหาร'},
    'Garden': {'icon': Icons.local_florist, 'thaiName': 'ดูแลสวน'},
  };

  // ตั้งค่าเป็น 0 เสมอเนื่องจากหน้า ViewHousekeeperPage ไม่ได้อยู่บน BottomNav หลัก
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _housekeeperDetail = widget.housekeeper;
    _fetchHousekeeperDetails();
    _printDebugInfo();
  }

  Future<void> _fetchHousekeeperDetails() async {
    try {
      // ⚠️ การเรียก API นี้สำคัญมากในการดึง Reviews ที่มีรายละเอียด Hirer (Reviewer)
      final updatedHousekeeper =
          await HousekeeperController.fetchHousekeeperWithDetails(
            widget.housekeeper.id!,
          );

      if (mounted) {
        setState(() {
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
    }
  }

  void _printDebugInfo() {
    debugPrint('---Debugging Housekeeper Reviews in ViewHousekeeperPage---');
    debugPrint('Housekeeper ID: ${widget.housekeeper.id}');
    debugPrint(
      'Housekeeper Initial Rating (from Props): ${widget.housekeeper.rating}',
    );
    debugPrint('---End Debugging Housekeeper Reviews---');
  }

  ImageProvider _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      // Fallback: Default local image
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

    // Default Fallback
    return const AssetImage('assets/image/icon_user.png');
  }

  // ปรับคะแนนให้เป็น 0.0, 0.5, 1.0, 1.5 ...
  double _getDisplayScore(double? actualScore) {
    if (actualScore == null || actualScore <= 0.0) return 0.0;
    // ปัดเศษให้ใกล้เคียง 0.5 ที่สุด เช่น 4.2 -> 4.0, 4.3 -> 4.5
    return (actualScore * 2).round() / 2.0;
  }

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

  Widget _buildContactButton(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String actionLabel,
  ) {
    String finalUrl = '';
    String displaySubtitle = subtitle;
    // ตรวจสอบว่าผู้ใช้ปัจจุบันมีการเข้าสู่ระบบหรือไม่ (มีข้อมูล Person)
    bool isUserLoggedIn = widget.user.person != null;
    bool isActionEnabled =
        isUserLoggedIn && subtitle != 'N/A' && subtitle != 'ไม่ระบุ';

    if (title == (widget.isEnglish ? "Phone Number" : "เบอร์โทรศัพท์")) {
      if (isUserLoggedIn) {
        // หาก Login แล้ว ให้สร้าง URL สำหรับโทร
        finalUrl = 'tel:${subtitle.replaceAll(' ', '')}';
        displaySubtitle = subtitle;
      } else {
        // หากยังไม่ได้ Login ให้ซ่อนเบอร์และไม่เปิดใช้งาน Action
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
                      // ไปหน้า Login หากยังไม่ได้ Login
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

  @override
  Widget build(BuildContext context) {
    final Housekeeper housekeeper = _housekeeperDetail;
    final double? backendRating = housekeeper.rating;
    final double displayRating = _getDisplayScore(backendRating);
    final String displayRatingText =
        backendRating != null && backendRating > 0
            ? backendRating.toStringAsFixed(1)
            : "0.0";

    final int totalCompletedJobs = housekeeper.jobsCompleted ?? 0;
    // ⭐️ ใช้ reviews จาก object ที่ได้จากการ fetch ล่าสุด
    final List<Review> reviewsToShow = _housekeeperDetail.reviews ?? [];

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

    // ⭐️ การคำนวณราคาต่ำสุดสำหรับ Daily Rate
    double minDailyRateToCompare = 0.0;
    final String? rateString = housekeeper.dailyRate;
    if (rateString != null) {
      final parts = rateString.split(' - ');
      if (parts.isNotEmpty) {
        // ใช้ค่าแรกเป็น Min Rate
        minDailyRateToCompare = double.tryParse(parts.first) ?? 0.0;
      }
    }
    // -------------------------------------------------------------
    final String housekeeperFullName =
        "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}";

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
            // ... (โค้ดส่วน Avatar และ Name)
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
                    housekeeper.statusVerify  == 'APPROVED'
                        ? (widget.isEnglish ? 'Verified' : 'ยืนยันตัวตนแล้ว')
                        : (widget.isEnglish ? 'Not Verified' : 'ยังไม่ยืนยันตัวตน'),
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              housekeeperFullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStarRating(displayRating, iconSize: 18.0),
                const SizedBox(width: 4),
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
                        displayRatingText,
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

            // --- ส่วนของปุ่มจ้างและราคา ---
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
                            // ⭐️ แสดง Daily Rate ที่เป็นช่วงราคา
                            "${housekeeper.dailyRate ?? "0.00"} ฿${widget.isEnglish ? '/day' : '/วัน'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                          // ต้อง Login ก่อน
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        }
                        // ⭐️ ใช้ minDailyRateToCompare ในเงื่อนไขการจ้าง
                        else if (widget.user.balance != null &&
                            widget.user.balance! >= minDailyRateToCompare) {
                          // ยอดเงินพอ -> ไปหน้า Hire
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => HireHousekeeperPage(
                                    housekeeper: housekeeper,
                                    user: widget.user,
                                    isEnglish: widget.isEnglish,
                                  ),
                            ),
                          );
                        } else {
                          // ยอดเงินไม่พอ -> แสดงแจ้งเตือน
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
                                      ? "Your balance (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'}฿) is less than the housekeeper's starting daily rate (${minDailyRateToCompare.toStringAsFixed(2)}฿). Please top up your balance."
                                      : "ยอดเงินของคุณ (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'}฿) ไม่เพียงพอต่อค่าบริการรายวันเริ่มต้นของแม่บ้าน (${minDailyRateToCompare.toStringAsFixed(2)}฿) กรุณาเติมเงิน",
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

            // --- ส่วนของ Reviews ---
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (reviewsToShow.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ReviewListPage(
                                      reviews: reviewsToShow,
                                      isEnglish: widget.isEnglish,
                                      // ✅ ส่งชื่อแม่บ้านสำหรับใช้ในหน้า ReviewListPage
                                      housekeeperName: housekeeperFullName,
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
                  if (reviewsToShow.isNotEmpty)
                    ...reviewsToShow.take(3).map((review) {
                      final String reviewerFirstName =
                          review.hirerFirstName ?? '';
                      final String reviewerLastName =
                          review.hirerLastName ?? '';
                      final String reviewerName =
                          (reviewerFirstName.isEmpty &&
                                  reviewerLastName.isEmpty)
                              ? (widget.isEnglish
                                  ? 'Anonymous User'
                                  : 'ผู้ใช้ไม่ระบุชื่อ')
                              : "$reviewerFirstName $reviewerLastName";
                      return _buildReviewWidget(
                        name: reviewerName,
                        comment:
                            review.reviewMessage ??
                            (widget.isEnglish
                                ? 'No comment provided.'
                                : 'ไม่มีข้อความรีวิว'),
                        rating: review.score ?? 0.0,
                        avatarUrl:
                            review.hirerPictureUrl, // 👈 แก้ไขตาม Backend (ถ้ามีฟิลด์ใหม่)
                        reviewDate: review.reviewDate,
                      );
                    }).toList()
                  else
                    Text(
                      widget.isEnglish ? "No reviews yet" : "ยังไม่มีรีวิว",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),

            // --- ส่วนของ Contact Us ---
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
    );
  }
}
