import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/joblisthistory_housekeeper.dart';
import 'package:maebanjumpen/screens/jobrequests_housekeeper.dart';
import 'package:maebanjumpen/screens/listrequestwithdraw_housekeeper.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:maebanjumpen/screens/profile_housekeeper.dart';
import 'package:maebanjumpen/screens/requestwithdraw_housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/skill_type.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart';
import 'package:provider/provider.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/screens/notificationScreen.dart';

class JobListHistoryScreenState extends State<JobListHistoryScreen> {
  void refreshJobHistory() {
    print('Refreshing Job History Data...');
    if (mounted) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder
  }
}

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final GlobalKey<JobListHistoryScreenState> _jobHistoryKey = GlobalKey();
  late List<Widget> _pages;
  late Housekeeper _currentHousekeeperUser;
  final HousekeeperController _housekeeperController = HousekeeperController();
  // กำหนดสีหลักสำหรับปุ่มย้อนกลับ (ตามที่ระบุในโจทย์)
  static const Color _primaryColor = Colors.red;
  final Map<String, Map<String, dynamic>> _skillDetails = {
    'General Cleaning': {
      'icon': Icons.cleaning_services_rounded,
      'enName': 'General Cleaning',
      'thaiName': 'ทำความสะอาดทั่วไป',
    },
    'Laundry': {
      'icon': Icons.local_laundry_service_rounded,
      'enName': 'Laundry',
      'thaiName': 'ซักรีด',
    },
    'Cooking': {
      'icon': Icons.restaurant_menu_rounded,
      'enName': 'Cooking',
      'thaiName': 'ทำอาหาร',
    },
    'Garden': {
      'icon': Icons.grass_rounded,
      'enName': 'Garden',
      'thaiName': 'ดูแลสวน',
    },
    'Pet Care': {
      'icon': Icons.pets_rounded,
      'enName': 'Pet Care',
      'thaiName': 'ดูแลสัตว์เลี้ยง',
    },
    'Window Cleaning': {
      'icon': Icons.window_rounded,
      'enName': 'Window Cleaning',
      'thaiName': 'ทำความสะอาดหน้าต่าง',
    },
    'Organization': {
      'icon': Icons.auto_stories_rounded,
      'enName': 'Organization',
      'thaiName': 'จัดระเบียบ',
    },
  };
  @override
  void initState() {
    super.initState();
    _currentHousekeeperUser = widget.user;
    _initializePages();
    _fetchHousekeeperData();
  }

  void _initializePages() {
    _pages = [
      _buildHomePageContent(),
      JobListHistoryScreen(
        key: _jobHistoryKey,
        isEnglish: widget.isEnglish,
        housekeeperId: _currentHousekeeperUser.id!,
        onGoToHome: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        currentHousekeeper: _currentHousekeeperUser,
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
      final updatedHousekeeper = await _housekeeperController
          .getHousekeeperById(widget.user.id!);
      if (mounted && updatedHousekeeper != null) {
        setState(() {
          _currentHousekeeperUser = updatedHousekeeper;
          _initializePages();
        });
        print('Housekeeper data fetched and updated.');
      }
    } catch (e) {
      print('Error fetching Housekeeper data: $e');
    }
  }

  int _calculateJobsDone(Housekeeper hk) {
    return hk.hires?.where((hire) => hire.jobStatus == "finished").length ?? 0;
  }

  double _getDisplayRatingForStars(double? actualRating) {
    if (actualRating == null || actualRating < 0.0) return 0.0;
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
      return {
        'name': widget.isEnglish ? skillTypeName : skillTypeName,
        'icon': Icons.help_outline,
      };
    }
  }

  // Widget สำหรับ Header ของหน้า Home ที่มีปุ่มแจ้งเตือน
  Widget _buildHomeHeader(bool isEnglish) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isEnglish ? 'Home' : 'หน้าหลัก',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24, // ให้ดูเป็น Header หลัก
          ),
        ),
        Consumer<NotificationManager>(
          builder: (context, notificationManager, child) {
            final unreadCount = notificationManager.unreadCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.redAccent,
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomePageContent() {
    final housekeeper = _currentHousekeeperUser;
    final isEnglish = widget.isEnglish;
    final int jobsDoneCount = housekeeper.jobsCompleted ?? 0;
    final displayRatingForStars = _getDisplayRatingForStars(housekeeper.rating);
    ImageProvider profileImage;
    if (housekeeper.person?.pictureUrl != null &&
        housekeeper.person!.pictureUrl!.isNotEmpty) {
      profileImage = NetworkImage(housekeeper.person!.pictureUrl!);
    } else {
      profileImage = const AssetImage('assets/profile.jpg');
    }
    return RefreshIndicator(
      onRefresh: _fetchHousekeeperData,
      color: Colors.red,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header (แทน AppBar) ---
            _buildHomeHeader(isEnglish),
            const SizedBox(height: 16),
            // --- 1. ส่วนข้อมูลโปรไฟล์ ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: profileImage,
                      backgroundColor: Colors.grey[200],
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
                                  '${housekeeper.person?.firstName ?? (isEnglish ? 'Housekeeper' : 'แม่บ้าน')} ${housekeeper.person?.lastName ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (housekeeper.statusVerify == 'verified')
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStarRating(
                                displayRatingForStars,
                                iconSize: 18.0,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                housekeeper.rating?.toStringAsFixed(1) ?? "0.0",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "($jobsDoneCount ${isEnglish ? 'jobs done' : 'งานที่เสร็จ'})",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            housekeeper.person?.address ??
                                (isEnglish
                                    ? 'Address not available'
                                    : 'ที่อยู่ไม่ระบุ'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // --- 2. ส่วนแสดงทักษะ (Chips) ---
            Text(
              isEnglish ? 'My Skills' : 'ทักษะของฉัน',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (housekeeper.housekeeperSkills != null &&
                      housekeeper.housekeeperSkills!.isNotEmpty)
                    ...housekeeper.housekeeperSkills!.map((skill) {
                      if (skill.skillType != null) {
                        final skillDisplayInfo = _getSkillDisplayInfo(
                          skill.skillType!.skillTypeName,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildServiceChip(
                            skillDisplayInfo['name'],
                            Colors.blue,
                            skillDisplayInfo['icon'],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  if (housekeeper.housekeeperSkills == null ||
                      housekeeper.housekeeperSkills!.isEmpty)
                    _buildServiceChip(
                      isEnglish ? 'No skills available' : 'ไม่มีทักษะ',
                      Colors.grey,
                      Icons.settings_outlined,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // --- 3. ส่วนเมนูหลัก (Grid View) ---
            Text(
              isEnglish ? 'Quick Access' : 'เข้าถึงด่วน',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _buildMenuButton(
                  Icons.assignment_turned_in_rounded,
                  isEnglish ? "Job Requests" : "งานที่รับ",
                  Colors.purple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => JobRequestsPage(
                              housekeeper: _currentHousekeeperUser,
                              isEnglish: widget.isEnglish,
                            ),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  Icons.history_rounded,
                  isEnglish ? "Job History" : "ประวัติงาน",
                  Colors.blue,
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                ),
                _buildMenuButton(
                  Icons.account_balance_wallet_rounded,
                  isEnglish ? "Withdrawal" : "ถอนเงิน",
                  Colors.green,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RequestWithdrawalScreen(
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
                  Icons.list_alt_rounded,
                  isEnglish ? "Withdrawal List" : "รายการถอนเงิน",
                  Colors.orange,
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontSize: 14)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color, width: 1),
      ),
      backgroundColor: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildMenuButton(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // จัดให้ชิดซ้าย
            crossAxisAlignment:
                CrossAxisAlignment.center, // จัดให้อยู่ตรงกลางแนวตั้ง
            children: [
              // 1. ไอคอน
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 11), // เพิ่มระยะห่างแนวนอน
              // 2. ข้อความ (ห่อด้วย Expanded เพื่อให้ข้อความขึ้นบรรทัดใหม่ได้)
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2, // กำหนดให้มีสูงสุด 2 บรรทัด
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // สร้าง Widget สำหรับปุ่มแจ้งเตือน
  Widget _buildNotificationAction() {
    return Consumer<NotificationManager>(
      builder: (context, notificationManager, child) {
        final unreadCount = notificationManager.unreadCount;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.red,
                size: 28,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  // สร้าง Widget สำหรับปุ่มออกจากระบบ
  Widget _buildLogoutAction() {
    return IconButton(
      icon: Icon(
        Icons.logout_rounded,
        color: AppColors.primaryRed,
        size: 28,
      ),
      onPressed: _handleLogout,
      tooltip: widget.isEnglish ? 'Logout' : 'ออกจากระบบ',
    );
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = widget.isEnglish ? 'Home' : 'หน้าหลัก';
    if (_currentIndex == 1) {
      pageTitle = widget.isEnglish ? 'Job History' : 'ประวัติงาน';
    } else if (_currentIndex == 2) {
      pageTitle = widget.isEnglish ? 'Withdrawal List' : 'รายการถอนเงิน';
    } else if (_currentIndex == 3) {
      pageTitle = widget.isEnglish ? 'Profile' : 'โปรไฟล์';
    }
    // กำหนดให้หน้า Home (index 0) ไม่มี AppBar
    final bool showAppBar = _currentIndex != 0;

    List<Widget>? appBarActions;
    if (showAppBar) {
      if (_currentIndex == 3) {
        // หน้า Profile: แสดงปุ่มออกจากระบบ
        appBarActions = [
          _buildLogoutAction(),
          const SizedBox(width: 8),
        ];
      } else {
        // หน้าอื่น ๆ ที่มี AppBar (index 1 และ 2): แสดงปุ่มแจ้งเตือน
        appBarActions = [
          _buildNotificationAction(),
          const SizedBox(width: 8),
        ];
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      // แสดง AppBar เมื่อไม่ใช่หน้า Home (index 0)
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Text(
                pageTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryRed,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              // **********************************************
              actions: appBarActions, // ใช้ actions ที่กำหนดตามเงื่อนไข
              // **********************************************
            )
          : null, // ถ้าเป็นหน้า Home ให้ AppBar เป็น null
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
            icon: const Icon(Icons.home_rounded),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_toggle_off_rounded),
            label: widget.isEnglish ? 'History' : 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
      ),
      endDrawer: Drawer(child: NotificationScreen(isEnglish: widget.isEnglish)),
    );
  }
}