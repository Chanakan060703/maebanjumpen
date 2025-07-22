import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirehousekeeper_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';

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
  int _currentIndex = 0;

  // Map skill names (จาก backend ที่เป็นภาษาอังกฤษ) ไปยังไอคอนที่เหมาะสม
  // และ map ไปยังข้อความภาษาไทยเพื่อแสดงผล
  final Map<String, Map<String, dynamic>> skillDetails = {
    'General Cleaning': {'icon': Icons.cleaning_services, 'thaiName': 'ทำความสะอาดทั่วไป'},
    'Laundry': {'icon': Icons.local_laundry_service, 'thaiName': 'ซักรีด'},
    'Cooking': {'icon': Icons.restaurant, 'thaiName': 'ทำอาหาร'},
    'Garden': {'icon': Icons.local_florist, 'thaiName': 'ดูแลสวน'},
    // เพิ่มการจับคู่สกิลอื่นๆ ที่เป็นภาษาอังกฤษจาก backend และชื่อภาษาไทยที่ต้องการแสดงผล
  };

  @override
  void initState() {
    super.initState();
    // *** Debugging Reviews ***
    print('--- Debugging Housekeeper Reviews in ViewHousekeeperPage ---');
    print('Housekeeper ID: ${widget.housekeeper.id}');
    print('Housekeeper Name: ${widget.housekeeper.person?.firstName} ${widget.housekeeper.person?.lastName}');
    print('Housekeeper Current Rating (from Backend): ${widget.housekeeper.rating}');
    print('Housekeeper Skills: ${widget.housekeeper.housekeeperSkills ?? "No skills provided"}'); // Debugging skills

    if (widget.housekeeper.hires == null || widget.housekeeper.hires!.isEmpty) {
      print('No hires found for this housekeeper. Reviews cannot be displayed.');
    } else {
      print('Total hires for housekeeper: ${widget.housekeeper.hires!.length}');
      int completedHiresWithReviews = 0;
      for (var i = 0; i < widget.housekeeper.hires!.length; i++) {
        var hire = widget.housekeeper.hires![i];
        print('    Hire #${i + 1} (ID: ${hire.hireId}):');
        print('      Job Status: ${hire.jobStatus}');
        print('      Review Object is NULL: ${hire.review == null}');
        if (hire.review != null) {
          completedHiresWithReviews++;
          print('        Review Message: "${hire.review?.reviewMessage}"');
          print('        Review Score: ${hire.review?.score}');
          print('        Review Date: ${hire.review?.reviewDate}');
          print('        Reviewer Name: ${hire.hirer?.person?.firstName ?? 'N/A'}');
          print('        Reviewer Picture: ${hire.hirer?.person?.pictureUrl ?? 'N/A'}');
        } else {
          print('        !!! Review is STILL NULL for this hire (check Backend Housekeeper fetch & serialization) !!!');
        }
      }
      print('Total completed hires with reviews: $completedHiresWithReviews');
    }
    print('--- End Debugging Housekeeper Reviews ---');
  }

  // --- ฟังก์ชันสำหรับแปลง String เป็น ImageProvider ---
  ImageProvider _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/placeholder_image.png'); // รูปภาพสำรอง
    }

    // ตรวจสอบว่าเป็น URL
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return NetworkImage(imageData);
    }

    // ตรวจสอบว่าเป็น Base64
    if (imageData.contains('data:image/') || imageData.length > 100) {
      try {
        String base64Stripped = imageData.contains(',') ? imageData.split(',')[1] : imageData;
        final decodedBytes = base64Decode(base64Stripped);
        return MemoryImage(decodedBytes);
      } catch (e) {
        debugPrint('Error decoding Base64 image: $e');
        return const AssetImage('assets/placeholder_image.png'); // รูปภาพสำรองเมื่อ Base64 ผิดพลาด
      }
    }
    return const AssetImage('assets/placeholder_image.png'); // รูปภาพสำรองสุดท้าย
  }

  // --- ฟังก์ชันสำหรับคำนวณคะแนนที่ใช้แสดงผลดาว (ใช้กับ review score) ---
  double _getDisplayScore(double? actualScore) {
    if (actualScore == null) return 0.0;
    double scoreAsDouble = actualScore.toDouble();
    if (scoreAsDouble % 1 == 0) {
      return scoreAsDouble;
    } else {
      return scoreAsDouble.floorToDouble() + 0.5;
    }
  }

  // --- ฟังก์ชันสำหรับสร้าง Widget แสดงผลดาว (ใช้กับ review score) ---
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

  // เมธอดนี้ถูกเก็บไว้ แต่ค่า rating หลักจะมาจาก backend โดยตรง
  double _calculateAverageRatingLocally() {
    if (widget.housekeeper.hires == null || widget.housekeeper.hires!.isEmpty) {
      return 0.0;
    }

    double totalScore = 0.0;
    int reviewCount = 0;

    for (var hire in widget.housekeeper.hires!) {
      // ตรวจสอบว่า hire นี้เป็น "Completed" และมีรีวิว
      if (hire.jobStatus == 'Completed' && hire.review != null && hire.review!.score != null) {
        totalScore += hire.review!.score!;
        reviewCount++;
      }
    }

    return reviewCount > 0 ? totalScore / reviewCount : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double? backendRating = widget.housekeeper.rating;
    final String displayRatingText = backendRating != null && backendRating > 0
        ? backendRating.toStringAsFixed(1)
        : (widget.isEnglish ? "No Rating" : "ไม่มีคะแนน");

    // นับจำนวนงานที่ทำเสร็จสิ้นและมีรีวิว
    final int completedJobsWithReviews = widget.housekeeper.hires
            ?.where((hire) => hire.jobStatus == 'Completed' && hire.review != null)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEnglish ? 'Housekeeper Info' : 'ข้อมูลแม่บ้าน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                user: widget.user,
                isEnglish: widget.isEnglish,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // --- ส่วนรูปโปรไฟล์และสถานะ ---
            CircleAvatar(
              radius: 60,
              backgroundImage: _getImageProvider(
                widget.housekeeper.person?.pictureUrl,
              ),
              backgroundColor: Colors.red,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading housekeeper profile image: $exception');
              },
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
              "${widget.housekeeper.person?.firstName ?? ''} ${widget.housekeeper.person?.lastName ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_pin, color: Colors.grey, size: 18),
                  Text(
                    widget.housekeeper.person?.address ?? '',
                    style: const TextStyle(color: Colors.grey),
                   )
              ],
            ),
            const SizedBox(height: 16),

            // --- ส่วนคะแนนเฉลี่ยและจำนวนงานที่ทำ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      // *** แสดงคะแนนเฉลี่ยเป็นตัวเลขตามค่าจาก Backend ***
                      Text(
                        displayRatingText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      Text(widget.isEnglish ? "Average Rating" : "คะแนนเฉลี่ย"),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.work, color: Colors.red),
                      Text(
                        // แสดงจำนวนงานที่ทำเสร็จและมีรีวิว
                        '$completedJobsWithReviews',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.isEnglish ? "Jobs Done" : "งานที่ทำ"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ส่วนแสดงทักษะ (Skills) ---
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
                  if (widget.housekeeper.housekeeperSkills != null &&
                      widget.housekeeper.housekeeperSkills!.isNotEmpty)
                    Wrap(
                      spacing: 12.0, // ช่องว่างแนวนอนระหว่างชิป
                      runSpacing: 12.0, // ช่องว่างแนวตั้งระหว่างแถวของชิป
                      children: widget.housekeeper.housekeeperSkills!
                          .map(
                            (skill) {
                              final String backendSkillName = skill.skillType?.skillTypeName ?? '';
                              final Map<String, dynamic>? details = skillDetails[backendSkillName];

                              final IconData icon = details?['icon'] ?? Icons.build; // Default icon if not found
                              final String displayName = widget.isEnglish
                                  ? backendSkillName.isNotEmpty ? backendSkillName : 'No skill name'
                                  : details?['thaiName'] ?? 'ไม่มีชื่อทักษะ';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  mainAxisSize: MainAxisSize.min, // ทำให้ Row หดขนาดตามเนื้อหา
                                  children: [
                                    Icon(icon, color: Colors.red, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          .toList(),
                    )
                  else
                    Text(
                      widget.isEnglish ? "No skills listed" : "ไม่มีความสามารถระบุ",
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
                          Text("${widget.housekeeper.dailyRate} ฿ / วัน", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    // --- ปุ่มจ้างเลยพร้อมเงื่อนไข ---
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
                        // ตรวจสอบยอดเงินก่อนที่จะไปหน้า Hire
                        if (widget.user.balance != null &&
                            widget.housekeeper.dailyRate != null &&
                            widget.user.balance! >= widget.housekeeper.dailyRate!) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HireHousekeeperPage(
                                housekeeper: widget.housekeeper,
                                isEnglish: widget.isEnglish,
                                user: widget.user,
                              ),
                            ),
                          );
                        } else {
                          // แสดง AlertDialog แจ้งเตือนว่าเงินไม่พอ
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(widget.isEnglish ? "Insufficient Balance" : "ยอดเงินไม่เพียงพอ"),
                                content: Text(
                                  widget.isEnglish
                                      ? "Your balance (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'} ฿) is less than the housekeeper's daily rate (${widget.housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'} ฿). Please top up your balance."
                                      : "ยอดเงินของคุณ (${widget.user.balance?.toStringAsFixed(2) ?? '0.00'} ฿) ไม่เพียงพอต่อค่าบริการรายวันของแม่บ้าน (${widget.housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'} ฿) กรุณาเติมเงิน",
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(widget.isEnglish ? "OK" : "ตกลง"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                  Text(
                    widget.isEnglish ? "Reviews" : "รีวิว",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.housekeeper.hires != null &&
                      widget.housekeeper.hires!.any(
                          (hire) => hire.review != null && hire.jobStatus == 'Completed'))
                    ...widget.housekeeper.hires!
                        .where((hire) => hire.review != null && hire.jobStatus == 'Completed')
                        .map(
                          (hire) => buildReview(
                            name: hire.hirer?.person?.firstName ?? (widget.isEnglish ? 'Unknown User' : 'ผู้ใช้ไม่ทราบชื่อ'), // เปลี่ยนเป็นภาษาไทย
                            comment: hire.review?.reviewMessage ?? '',
                            rating: hire.review?.score ?? 0.0,
                            avatarUrl: hire.hirer?.person?.pictureUrl ?? 'https://placehold.co/150x150/EEEEEE/313131?text=No+Image',
                            reviewDate: hire.review?.reviewDate, // ส่ง DateTime? ไปให้ buildReview จัดการ
                          ),
                        )
                        
                  else
                    Text(
                      widget.isEnglish ? "No reviews yet" : "ยังไม่มีรีวิว", // เปลี่ยนเป็นภาษาไทย
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ส่วนติดต่อเรา ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? "Contact Us" : "ติดต่อเรา", // เปลี่ยนเป็นภาษาไทย
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  contactButton(
                    Icons.phone,
                    widget.isEnglish ? "Phone Number" : "เบอร์โทรศัพท์",
                    widget.housekeeper.person?.phoneNumber ?? (widget.isEnglish ? "+66 XXX XXX XXXX" : "+66 XXX XXX XXXX"),
                    Colors.red,
                    widget.isEnglish ? "Call Now" : "โทรเลย",
                  ),
                  contactButton(
                    Icons.message,
                    "LINE ID",
                    widget.housekeeper.lineId ?? (widget.isEnglish ?
                    "LINE ID (Not provided)" : "LINE ID (ไม่ได้ระบุ)"), // เพิ่ม lineId ใน Housekeeper model
                    Colors.green,
                    widget.isEnglish ? "Open Page" : "เปิดหน้า",
                  ),
                  contactButton(
                    Icons.facebook,
                    "Facebook",
                    widget.housekeeper.facebookLink ?? (widget.isEnglish ? "Facebook (Not provided)" : "Facebook (ไม่ได้ระบุ)"), // เพิ่ม facebookLink ใน Housekeeper model
                    Colors.blue,
                    widget.isEnglish ? "Open Page" : "เปิดหน้า",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ส่วนแผนที่ (ตัวอย่าง) ---
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(widget.housekeeper.person?.address ?? (widget.isEnglish ? "Address Not Available" : "ไม่พบที่อยู่")),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://maps.googleapis.com/maps/api/staticmap?center=13.7563,100.5018&zoom=14&size=400x200&key=YOUR_API_KEY", // แทนที่ด้วย API Key ของคุณ
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardpageMember(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HireListPage(
                  isEnglish: widget.isEnglish,
                  user: widget.user,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileMemberPage(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: widget.isEnglish ? 'Home' : 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card),
            label: widget.isEnglish ? 'Cards' : 'บัตร',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: widget.isEnglish ? 'Hire' : 'การจ้าง'),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: widget.isEnglish ? 'Profile' : 'โปรไฟล์'),
        ],
      ),
    );
  }

  // --- Widget สำหรับแสดงรีวิวแต่ละรายการ ---
  Widget buildReview({
    required String name,
    required String comment,
    required double rating,
    required DateTime? reviewDate, // รับเป็น DateTime?
    required String avatarUrl,
  }) {
    final displayRatingForReview = _getDisplayScore(rating);
    // จัดรูปแบบ reviewDate ให้เป็นวันที่ที่อ่านง่าย (เช่น "มิ.ย. 11, 2025")
    String formattedReviewDate = '';
    if (reviewDate != null) {
      formattedReviewDate = DateFormat('MMM dd, yyyy', widget.isEnglish ? 'en_US' : 'th_TH').format(reviewDate.toLocal()); // แสดงเวลาท้องถิ่น
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
            Text(comment),
            Text(
              formattedReviewDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget สำหรับปุ่มติดต่อ (Phone, LINE, Facebook) ---
  Widget contactButton(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String actionLabel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            debugPrint('Contact action for $title: $subtitle');
            // TODO: เพิ่ม logic สำหรับการโทร, เปิด LINE/Facebook
          },
          child: Text(actionLabel),
        ),
      ),
    );
  }
}