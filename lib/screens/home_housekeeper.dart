import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/joblisthistory_housekeeper.dart';
import 'package:maebanjumpen/screens/jobrequests_housekeeper.dart';
import 'package:maebanjumpen/screens/listrequestwithdraw_housekeeper.dart';
import 'package:maebanjumpen/screens/profile_housekeeper.dart';
import 'package:maebanjumpen/screens/requestwithdraw_housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart'; // ตรวจสอบให้แน่ใจว่าได้ import HousekeeperSkill และ SkillType
import 'package:maebanjumpen/model/skill_type.dart';
import 'package:provider/provider.dart'; // เพิ่ม import สำหรับ Provider
import 'package:maebanjumpen/controller/notification_manager.dart'; // เพิ่ม import สำหรับ NotificationManager
import 'package:maebanjumpen/screens/notificationScreen.dart'; // เพิ่ม import สำหรับ NotificationScreen

class HousekeeperPage extends StatefulWidget {
  final Housekeeper user;
  final bool isEnglish;

  const HousekeeperPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  State<HousekeeperPage> createState() => _HousekeeperPageState();
}

class _HousekeeperPageState extends State<HousekeeperPage> {
  // *** เพิ่ม GlobalKey สำหรับ Scaffold ***
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  final GlobalKey<JobListHistoryScreenState> _jobHistoryKey = GlobalKey();

  late List<Widget> _pages;

  late Housekeeper _currentHousekeeperUser;
  final HousekeeperController _housekeeperController = HousekeeperController();

  // แผนที่เก็บรายละเอียดทักษะ พร้อมชื่อภาษาอังกฤษและไทย
  final Map<String, Map<String, dynamic>> _skillDetails = {
    'General Cleaning': {'icon': Icons.cleaning_services, 'enName': 'General Cleaning', 'thaiName': 'ทำความสะอาดทั่วไป'},
    'Laundry': {'icon': Icons.local_laundry_service, 'enName': 'Laundry', 'thaiName': 'ซักรีด'},
    'Cooking': {'icon': Icons.restaurant, 'enName': 'Cooking', 'thaiName': 'ทำอาหาร'},
    'Garden': {'icon': Icons.local_florist, 'enName': 'Garden', 'thaiName': 'ดูแลสวน'},
    'Pet Care': {'icon': Icons.pets, 'enName': 'Pet Care', 'thaiName': 'ดูแลสัตว์เลี้ยง'},
    'Window Cleaning': {'icon': Icons.window, 'enName': 'Window Cleaning', 'thaiName': 'ทำความสะอาดหน้าต่าง'},
    'Organization': {'icon': Icons.category, 'enName': 'Organization', 'thaiName': 'จัดระเบียบ'},
  };

  @override
  void initState() {
    super.initState();
    _currentHousekeeperUser = widget.user;

    _initializePages(); // แยกการสร้าง _pages ออกมาเป็นเมธอด
    _fetchHousekeeperData();
  }

  // สร้างเมธอดแยกเพื่อ initialize _pages เพื่อให้สามารถเรียกใช้ซ้ำได้เมื่อข้อมูลอัปเดต
  void _initializePages() {
    _pages = [
      _buildHomePageContent(),
      JobListHistoryScreen(
        key: _jobHistoryKey,
        isEnglish: widget.isEnglish,
        housekeeperId: _currentHousekeeperUser.id!, // ใช้ _currentHousekeeperUser
        onGoToHome: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        currentHousekeeper: _currentHousekeeperUser, // ส่ง _currentHousekeeperUser
      ),
      ListRequestsWithdrawalScreen(
        user: _currentHousekeeperUser,
        isEnglish: widget.isEnglish,
      ),
      ProfilePage(user: _currentHousekeeperUser, isEnglish: widget.isEnglish),
    ];
  }

  Future<void> _fetchHousekeeperData() async {
    print('Fetching latest Housekeeper data...');
    try {
      final updatedHousekeeper =
          await _housekeeperController.getHousekeeperById(widget.user.id!);
      if (mounted && updatedHousekeeper != null) { // เพิ่มการตรวจสอบ null
        setState(() {
          _currentHousekeeperUser = updatedHousekeeper;
          _initializePages(); // เรียกใหม่เพื่ออัปเดตข้อมูลใน _pages
        });
        print('Housekeeper data fetched and updated.');
      } else if (mounted) {
        print('Updated housekeeper data is null or widget is not mounted.');
      }
    } catch (e) {
      print('Error fetching Housekeeper data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to load latest profile data.'
                  : 'ไม่สามารถโหลดข้อมูลโปรไฟล์ล่าสุดได้',
            ),
          ),
        );
      }
    }
  }

  int _calculateReviewsCount(Housekeeper hk) {
    if (hk.hires == null) return 0;
    return hk.hires!.where((hire) => hire.review != null).length;
  }

  double _getDisplayRatingForStars(double? actualRating) {
    if (actualRating == null || actualRating < 0.0) return 0.0; // ตรวจสอบค่าลบด้วย
    return (actualRating * 2).roundToDouble() / 2;
  }

  Widget _buildStarRating(double displayRating, {double iconSize = 14.0}) {
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

  // ฟังก์ชันช่วยในการดึงชื่อทักษะและไอคอนตามภาษา
  Map<String, dynamic> _getSkillDisplayInfo(String? skillTypeName) {
    if (skillTypeName == null || skillTypeName.isEmpty) {
      return {
        'name': widget.isEnglish ? 'Unknown Skill' : 'ทักษะไม่ระบุ',
        'icon': Icons.help_outline,
      };
    }
    final detail = _skillDetails[skillTypeName];
    if (detail != null) {
      return {
        'name': widget.isEnglish ? detail['enName']! : detail['thaiName']!,
        'icon': detail['icon']!,
      };
    } else {
      // ถ้าไม่พบใน _skillDetails ให้ใช้ชื่อเดิมที่ได้มา (เป็น fallback)
      return {
        'name': widget.isEnglish ? skillTypeName : skillTypeName,
        'icon': Icons.help_outline,
      };
    }
  }

  Widget _buildHomePageContent() {
    final housekeeper = _currentHousekeeperUser;
    final isEnglish = widget.isEnglish;

    final reviewsCount = _calculateReviewsCount(housekeeper);
    final displayRatingForStars = _getDisplayRatingForStars(housekeeper.rating);

    ImageProvider? profileImage;
    if (housekeeper.person?.pictureUrl != null &&
        housekeeper.person!.pictureUrl!.isNotEmpty) {
      profileImage = NetworkImage(housekeeper.person!.pictureUrl!);
    } else {
      profileImage = const AssetImage('assets/profile.jpg');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: profileImage,
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${housekeeper.person?.firstName} ${housekeeper.person?.lastName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // ตรวจสอบ statusVerify ก่อนแสดงเครื่องหมายถูก
                        if (housekeeper.statusVerify == 'verified') // เปลี่ยนจาก 'Verified' เป็น 'verified'
                          const Icon(Icons.verified, color: Colors.blue, size: 18), // เปลี่ยนเป็นสีน้ำเงินเพื่อความชัดเจน
                      ],
                    ),
                    Row(
                      children: [
                        _buildStarRating(displayRatingForStars, iconSize: 16.0),
                        const SizedBox(width: 4),
                        Text(
                          housekeeper.rating != null
                              ? housekeeper.rating!.toStringAsFixed(1)
                              : "0.0",
                          style: const TextStyle(color: Colors.orange), // ใช้สีส้มเพื่อให้เห็นชัด
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "($reviewsCount ${isEnglish ? 'reviews' : 'รีวิว'})",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      housekeeper.person?.address ?? (isEnglish ? 'Address not available' : 'ที่อยู่ไม่ระบุ'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // *** เปลี่ยน Badge และ Icon เป็น Consumer และ IconButton ***
              Consumer<NotificationManager>(
                builder: (context, notificationManager, child) {
                  final unreadCount = notificationManager.unreadCount;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, size: 28),
                        onPressed: () {
                          // *** เปิด EndDrawer แทนการนำทางไปหน้าใหม่ ***
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ตรวจสอบและแสดงทักษะที่มี
                  if (housekeeper.housekeeperSkills != null && housekeeper.housekeeperSkills!.isNotEmpty)
                    ...housekeeper.housekeeperSkills!.map((skill) {
                      // ตรวจสอบให้แน่ใจว่า skill.skillType ไม่เป็น null ก่อนส่งไป _getSkillDisplayInfo
                      if (skill.skillType != null) {
                        final skillDisplayInfo = _getSkillDisplayInfo(skill.skillType!.skillTypeName);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildServiceChip(
                            skillDisplayInfo['name'], // ใช้ชื่อที่แปลแล้ว
                            Colors.blue,
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // หาก skillType เป็น null ให้ซ่อนไป
                    })
                  else
                    // แสดง "No skills" เมื่อไม่มีทักษะ
                    _buildServiceChip(
                      isEnglish ? 'No skills' : 'ไม่มีทักษะ',
                      Colors.grey,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMenuButton(
                Icons.assignment,
                isEnglish ? "Job Requests" : "งานที่รับ",
                Colors.purple,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobRequestsPage(
                        housekeeper: _currentHousekeeperUser,
                        isEnglish: widget.isEnglish,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                Icons.account_balance_wallet,
                isEnglish ? "Withdrawal" : "ถอนเงิน",
                Colors.green,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestWithdrawalScreen(
                        user: _currentHousekeeperUser,
                        isEnglish: widget.isEnglish,
                      ),
                    ),
                  );
                  if (result == true) {
                    _fetchHousekeeperData();
                  }
                },
              ),
              _buildMenuButton(
                Icons.history,
                isEnglish ? "View Job History" : "ประวัติงาน",
                Colors.blue,
                onPressed: () {
                  setState(() {
                    _currentIndex = 1; // สลับไปที่แท็บประวัติงาน (Index 1)
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }

  Widget _buildMenuButton(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.grey, width: 0.2),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // เพิ่ม overflow
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // *** กำหนด key ให้กับ Scaffold ***
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (int index) {
          if (index == _currentIndex && index == 1) {
            _jobHistoryKey.currentState?.refreshJobHistory();
          } else {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0 || index == 3) {
              _fetchHousekeeperData();
            }
          }
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: widget.isEnglish ? 'History' : 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
      ),
      // *** เพิ่ม EndDrawer ตรงนี้ ***
      endDrawer: Drawer(
        child: NotificationScreen(isEnglish: widget.isEnglish),
      ),
    );
  }
}
