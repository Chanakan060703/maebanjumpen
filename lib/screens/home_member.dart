import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart'; // ใช้ DepositMemberPage
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/notificationScreen.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:maebanjumpen/screens/seeallhousekeeper_member.dart';
import 'package:maebanjumpen/screens/viewhousekeeper_member.dart';
import 'package:maebanjumpen/controller/memberController.dart';
import 'package:http/http.dart' as http; // เพิ่ม import นี้
import 'dart:convert'; // เพิ่ม import นี้
import 'package:maebanjumpen/constant/constant_value.dart'; // ตรวจสอบให้แน่ใจว่าไฟล์นี้มี baseURL และ headers ที่ถูกต้อง
import 'package:provider/provider.dart'; // เพิ่ม import นี้สำหรับ Consumer

class HomePage extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const HomePage({super.key, required this.user, required this.isEnglish});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // เพิ่ม GlobalKey สำหรับ Scaffold

  List<Housekeeper> housekeepers = [];
  // เปลี่ยน isLoading เป็น Map เพื่อจัดการสถานะการโหลดแต่ละส่วนแยกกัน
  Map<String, bool> isLoading = {
    'housekeepers': true,
    'balance': true,
    'servicePopularity': true, // เพิ่มสถานะโหลดสำหรับข้อมูลความนิยมบริการ
  };

  late Hirer _currentUser;
  late String _displayBalance;

  // เพิ่ม TextEditingController สำหรับช่องค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // ตัวแปรสำหรับเก็บคำค้นหา

  final Map<String, Map<String, dynamic>> _skillDetails = {
    'General Cleaning': {
      'icon': Icons.cleaning_services,
      'enName': 'General Cleaning',
      'thaiName': 'ทำความสะอาดทั่วไป',
    },
    'Laundry': {
      'icon': Icons.local_laundry_service,
      'enName': 'Laundry',
      'thaiName': 'ซักรีด',
    },
    'Cooking': {
      'icon': Icons.restaurant,
      'enName': 'Cooking',
      'thaiName': 'ทำอาหาร',
    },
    'Garden': {
      'icon': Icons.local_florist,
      'enName': 'Garden',
      'thaiName': 'ดูแลสวน',
    },
    'Pet Care': {
      'icon': Icons.pets,
      'enName': 'Pet Care',
      'thaiName': 'ดูแลสัตว์เลี้ยง',
    },
    'Window Cleaning': {
      'icon': Icons.window,
      'enName': 'Window Cleaning',
      'thaiName': 'ทำความสะอาดหน้าต่าง',
    },
    'Organization': {
      'icon': Icons.category,
      'enName': 'Organization',
      'thaiName': 'จัดระเบียบ',
    },
  };

  // เพิ่ม Map สำหรับ Popular Services
  final Map<String, Map<String, dynamic>> _popularServiceDetails = {
    'General Cleaning': {
      'icon': Icons.cleaning_services,
      'enName': 'House Cleaning',
      'thaiName': 'ทำความสะอาดบ้าน',
    },
    'Cooking': {
      'icon': Icons.restaurant,
      'enName': 'Personal Cooking',
      'thaiName': 'ทำอาหารส่วนตัว',
    },
    'Window Cleaning': {
      'icon': Icons.window, // ตัวอย่างไอคอนสำหรับ AC Maintenance
      'enName': 'Window Cleaning',
      'thaiName': 'ทำความสะอาดหน้าต่าง',
    },
    'Pet Care': {
      'icon': Icons.pets,
      'enName': 'Pet Sitting',
      'thaiName': 'ดูแลสัตว์เลี้ยง',
    },
    'Laundry': {
      'icon': Icons.local_laundry_service,
      'enName': 'Laundry Service',
      'thaiName': 'บริการซักรีด',
    },
    'Garden': {
      'icon': Icons.local_florist,
      'enName': 'Gardening',
      'thaiName': 'ทำสวน',
    },
  };

  // เพิ่ม Map สำหรับเก็บข้อมูลความนิยมของบริการ (Rating และ Review Count)
  // ข้อมูลนี้จะถูกดึงมาจาก Backend
  Map<String, Map<String, dynamic>> _servicePopularityData = {}; // เริ่มต้นเป็น Map ว่างเปล่า

  int _currentIndex = 0;

  List<Widget> get _pages => [
        _buildHomeScreenContent(),
        CardpageMember(user: _currentUser, isEnglish: widget.isEnglish), // ใช้ DepositMemberPage
        HireListPage(user: _currentUser, isEnglish: widget.isEnglish),
        ProfileMemberPage(user: _currentUser, isEnglish: widget.isEnglish),
      ];

  @override
  void initState() {
    super.initState();
    print("HomePage initState: Initializing _pages and fetching data.");
    _currentUser = widget.user; // กำหนดค่าเริ่มต้นจาก widget.user
    _updateBalanceDisplay(); // อัปเดตการแสดงผล Balance ครั้งแรก

    _searchController.addListener(_onSearchChanged); // เพิ่ม listener สำหรับช่องค้นหา

    // เรียก fetch ทั้งหมดใน initState เพื่อให้ข้อมูลพร้อมเมื่อหน้า Home โหลด
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged); // ลบ listener
    _searchController.dispose(); // Dispose controller
    super.dispose();
  }

  // เมธอดสำหรับจัดการการเปลี่ยนแปลงของคำค้นหา
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      // เรียก fetchHousekeepers อีกครั้งเพื่อกรองข้อมูลใหม่ตามคำค้นหา
      fetchHousekeepers();
    });
  }

  // *** Method สำหรับอัปเดตการแสดงผล Balance ***
  void _updateBalanceDisplay() {
    _displayBalance = NumberFormat('#,##0.00').format(_currentUser.balance ?? 0.0);
  }

  // *** Method สำหรับดึง Balance ล่าสุดจาก Backend (เหมือนใน CardpageMember) ***
  Future<void> _fetchLatestBalance() async {
    if (!mounted) return; // ตรวจสอบ mounted ก่อน setState

    setState(() {
      isLoading['balance'] = true;
    });

    try {
      final MemberController memberController = MemberController();
      final Hirer? latestHirerData = await memberController.getHirerById(widget.user.id!.toString());

      if (mounted && latestHirerData != null) {
        setState(() {
          _currentUser = latestHirerData; // อัปเดต user object ทั้งหมด
          _updateBalanceDisplay(); // อัปเดตการแสดงผล balance
        });
        print('HomePage Balance updated successfully to: ${_currentUser.balance}');
      } else if (mounted) {
        print('HomePage: Failed to fetch latest hirer data or widget not mounted.');
      }
    } catch (e) {
      print('HomePage: Error fetching latest balance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? 'Failed to load balance.' : 'ไม่สามารถโหลดข้อมูลยอดเงินได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading['balance'] = false;
        });
      }
    }
  }

  // *** เมธอดสำหรับดึงข้อมูลความนิยมบริการจาก Backend ***
  Future<void> _fetchServicePopularityData() async {
    if (!mounted) return;
    setState(() {
      isLoading['servicePopularity'] = true;
    });
    try {
      // *** เรียก API จาก Backend ที่นี่ ***
      // ตรวจสอบให้แน่ใจว่า baseURL ของคุณถูกตั้งค่าใน constant_value.dart
      // ตัวอย่าง: const String baseURL = "https://your-ngrok-url.ngrok-free.app";
      final response = await http.get(Uri.parse('$baseURL/maeban/services/popularity'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
        setState(() {
          _servicePopularityData = data.map((key, value) => MapEntry(key, value as Map<String, dynamic>));
        });
        print('Service popularity data fetched successfully: $_servicePopularityData');
      } else {
        print('Failed to fetch service popularity data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEnglish ? 'Failed to load service popularity data.' : 'ไม่สามารถโหลดข้อมูลความนิยมบริการได้'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching service popularity data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? 'Network error or unable to connect to service popularity API.' : 'ข้อผิดพลาดเครือข่าย หรือไม่สามารถเชื่อมต่อ API ความนิยมบริการได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading['servicePopularity'] = false;
        });
      }
    }
  }


  Future<void> _fetchInitialData() async {
    // โหลดข้อมูล Housekeepers
    await fetchHousekeepers();
    // โหลดข้อมูล Balance
    await _fetchLatestBalance();
    // โหลดข้อมูลความนิยมของบริการ
    await _fetchServicePopularityData();
  }

  Future<void> fetchHousekeepers() async {
    print("fetchHousekeepers: Attempting to fetch housekeepers...");
    if (housekeepers.isEmpty) {
      // แสดง loading indicator ทันทีถ้าลิสต์ยังว่าง
      if (mounted) {
        setState(() {
          isLoading['housekeepers'] = true;
        });
      }
    }

    try {
      List<Housekeeper>? list =
          await HousekeeperController().getListHousekeeper();
      if (mounted && list != null && list.isNotEmpty) {
        // กรองข้อมูลตามคำค้นหาและสถานะ verified
        final filteredAndVerifiedList = list.where((housekeeper) {
          final fullName = "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}".toLowerCase();
          final address = (housekeeper.person?.address ?? '').toLowerCase();
          final skills = (housekeeper.housekeeperSkills ?? [])
              .map((s) => _getSkillName(s.skillType?.skillTypeName).toLowerCase())
              .join(' ');
          final query = _searchQuery.toLowerCase();

          // ตรวจสอบสถานะ verified
          final isVerified = housekeeper.statusVerify == 'verified';

          // คืนค่า true ถ้าตรงกับคำค้นหาและสถานะเป็น verified
          return isVerified && (fullName.contains(query) ||
              address.contains(query) ||
              skills.contains(query));
        }).toList();

        // Sort the filtered list by rating (descending)
        filteredAndVerifiedList.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));

        // Take top 5 from the filtered and sorted list
        final top5Housekeepers = filteredAndVerifiedList.take(5).toList();

        setState(() {
          housekeepers = top5Housekeepers; // Assign the sorted and limited list
          isLoading['housekeepers'] = false;
          print("fetchHousekeepers: Successfully fetched and filtered ${housekeepers.length} housekeepers.");
        });
      } else if (mounted) {
        setState(() {
          housekeepers = [];
          isLoading['housekeepers'] = false;
        });
        print("fetchHousekeepers: No housekeepers returned from API or list is empty.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading['housekeepers'] = false;
        });
        print("fetchHousekeepers: Error fetching housekeepers: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? 'Failed to load housekeepers.' : 'ไม่สามารถโหลดข้อมูลแม่บ้านได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getDisplayRatingForStars(double? actualRating) {
    if (actualRating == null || actualRating < 0.0) return 0.0;
    return (actualRating * 2).roundToDouble() / 2;
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

  String _getSkillName(String? skillTypeName) {
    if (skillTypeName == null || skillTypeName.isEmpty) {
      return widget.isEnglish ? 'Unknown Skill' : 'ทักษะไม่ระระบุ';
    }
    final detail = _skillDetails[skillTypeName];
    if (detail != null) {
      return widget.isEnglish ? detail['enName']! : detail['thaiName']!;
    } else {
      return skillTypeName;
    }
  }

  // เพิ่มฟังก์ชันสำหรับดึงชื่อบริการยอดนิยมตามภาษา
  String _getPopularServiceName(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty) {
      return widget.isEnglish ? 'Unknown Service' : 'บริการไม่ระบุ';
    }
    final detail = _popularServiceDetails[serviceKey];
    if (detail != null) {
      return widget.isEnglish ? detail['enName']! : detail['thaiName']!;
    } else {
      return serviceKey; // Fallback to original key if not found
    }
  }

  // เพิ่มฟังก์ชันสำหรับดึงไอคอนบริการยอดนิยม
  IconData _getPopularServiceIcon(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty) {
      return Icons.help_outline; // ไอคอนเริ่มต้นถ้าไม่พบ
    }
    final detail = _popularServiceDetails[serviceKey];
    return detail?['icon'] ?? Icons.help_outline;
  }


  @override
  Widget build(BuildContext context) {
    print("HomePage build: Current index is $_currentIndex");
    return Scaffold(
      key: _scaffoldKey, // กำหนด key ให้กับ Scaffold
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // _pages is now a getter
      ),
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
            print("BottomNavigationBar: Tab changed to index $_currentIndex");
          });
          // ไม่ต้องเรียก _fetchInitialData() หรือ _fetchLatestBalance() ที่นี่แล้ว
          // เพราะแต่ละหน้าย่อยควรจัดการการดึงข้อมูลของตัวเองใน initState() หรือเมื่อจำเป็น
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: widget.isEnglish ? 'Cards' : 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: widget.isEnglish ? 'Hire' : 'การจ้าง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
      ),
      endDrawer: Drawer( // เพิ่ม Drawer สำหรับ NotificationScreen
        child: NotificationScreen(isEnglish: widget.isEnglish),
      ),
    );
  }

  Widget _buildHomeScreenContent() {
    print("_buildHomeScreenContent: Building Home screen content.");
    return RefreshIndicator( // เพิ่ม RefreshIndicator ตรงนี้
      onRefresh: _fetchInitialData, // เมื่อดึงลงจะเรียกเมธอดนี้เพื่อรีเฟรชข้อมูลทั้งหมด
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // ทำให้สามารถดึงลงได้เสมอ แม้เนื้อหาจะไม่เต็มหน้า
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 20),
              // *** แก้ไขตรงนี้: เพิ่ม Row สำหรับหัวข้อและปุ่ม "ดูทั้งหมด" ***
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEnglish
                        ? "Popular Housekeeper"
                        : "แม่บ้านที่ได้รับความนิยม",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllHousekeeperPage(
                            isEnglish: widget.isEnglish,
                            user: _currentUser, // ใช้ _currentUser
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red), // ไอคอนลูกศร
                    label: Text(
                      widget.isEnglish ? "See All" : "ดูทั้งหมด",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPopularHousekeepers(),
              const SizedBox(height: 20),
              Text(
                widget.isEnglish
                    ? "Popular Services"
                    : "บริการที่ได้รับความนิยม",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPopularServices(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/images/logo.png'),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController, // กำหนด Controller สำหรับช่องค้นหา
                decoration: InputDecoration(
                  hintText: widget.isEnglish ? "Search..." : "ค้นหา...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<NotificationManager>( // ใช้ Consumer เพื่อเข้าถึง NotificationManager
              builder: (context, notificationManager, child) {
                final unreadCount = notificationManager.unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications, size: 28),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer(); // เปิด Drawer
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
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.monetization_on, color: Colors.amber),
            const SizedBox(width: 4),
            // *** แสดง loading indicator หรือ balance ***
            isLoading['balance']!
                ? const SizedBox(
                    width: 20, // กำหนดขนาดที่เหมาะสม
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : Text(
                    "฿$_displayBalance",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategories() {
    // สร้างรายการคีย์บริการที่เรียงลำดับตาม rating (จากมากไปน้อย)
    List<String> sortedServiceKeys = _popularServiceDetails.keys.toList();
    if (!isLoading['servicePopularity']!) {
      sortedServiceKeys.sort((a, b) {
        double ratingA = _servicePopularityData[a]?['rating'] ?? 0.0;
        double ratingB = _servicePopularityData[b]?['rating'] ?? 0.0;
        return ratingB.compareTo(ratingA); // เรียงจากมากไปน้อย
      });
    }

    // ใช้ 2 รายการแรกที่เรียงแล้ว
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: sortedServiceKeys.take(2).map((serviceKey) {
        // ดึงข้อมูล rating และ reviews จาก _servicePopularityData
        final serviceRating = _servicePopularityData[serviceKey]?['rating']?.toStringAsFixed(1) ?? 'N/A';
        final serviceReviews = _servicePopularityData[serviceKey]?['reviews'] ?? 0;
        final displayRatingText = "$serviceRating (${NumberFormat.compact().format(serviceReviews)}${widget.isEnglish ? ' reviews' : ' รีวิว'})";

        return CategoryCard(
          icon: _getPopularServiceIcon(serviceKey),
          label: _getPopularServiceName(serviceKey),
          rating: isLoading['servicePopularity']! ? (widget.isEnglish ? 'Loading...' : 'กำลังโหลด...') : displayRatingText,
        );
      }).toList(),
    );
  }

  Widget _buildPopularHousekeepers() {
    print("_buildPopularHousekeepers: Number of housekeepers: ${housekeepers.length}, isLoading: ${isLoading['housekeepers']}");

    if (isLoading['housekeepers']!) { // ใช้ ! เพื่อบอกว่ามั่นใจว่าไม่ใช่ null
      print("_buildPopularHousekeepers: Loading, showing CircularProgressIndicator.");
      return SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (housekeepers.isEmpty) {
      print("_buildPopularHousekeepers: Housekeepers list is empty after loading, showing no data message.");
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            widget.isEnglish ? "No housekeepers found." : "ไม่พบข้อมูลแม่บ้าน",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    } else {
      print("_buildPopularHousekeepers: Housekeepers data available, building ListView.");
      return Column(
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: housekeepers.length,
              itemBuilder: (context, index) {
                final hk = housekeepers[index];
                print("Building card for housekeeper: ${hk.person?.firstName ?? 'N/A'} ${hk.person?.lastName ?? 'N/A'}");
                print("    Picture URL: ${hk.person?.pictureUrl ?? 'N/A'}");
                print("    Rating: ${hk.rating ?? 'N/A'}");
                print("    Daily Rate: ${hk.dailyRate ?? 'N/A'}");

                final hasValidImageUrl = hk.person?.pictureUrl != null &&
                    hk.person!.pictureUrl!.isNotEmpty &&
                    (hk.person!.pictureUrl!.startsWith('http://') || hk.person!.pictureUrl!.startsWith('https://'));


                final displayRatingForStars = _getDisplayRatingForStars(hk.rating);

                final List<String> translatedSkills = hk.housekeeperSkills
                        ?.map((skill) => _getSkillName(skill.skillType?.skillTypeName))
                        .toList() ??
                    [];

                final String skillsDisplay = translatedSkills.isNotEmpty
                    ? translatedSkills.join(', ')
                    : (widget.isEnglish ? "No skills" : "ไม่มีทักษะ");

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewHousekeeperPage(
                          housekeeper: hk,
                          isEnglish: widget.isEnglish,
                          user: _currentUser, // ใช้ _currentUser
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (hasValidImageUrl)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  hk.person!.pictureUrl!,
                                ),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  print('Error loading image for ${hk.person?.firstName}: $exception');
                                  // Fallback to Icon if image fails to load
                                  // Note: For a true fallback, you might need a State in this widget
                                  // or use a package like cached_network_image with a placeholder/errorWidget.
                                },
                              ),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "${hk.person?.firstName ?? ''} ${hk.person?.lastName ?? ''}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStarRating(
                              displayRatingForStars,
                              iconSize: 16.0,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hk.rating?.toStringAsFixed(1) ?? '0.0',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skillsDisplay,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${hk.dailyRate != null ? hk.dailyRate!.toStringAsFixed(2) : '0.00'} ฿",
                              style: TextStyle(color: Colors.red),
                            ),
                            Icon(
                              Icons.bookmark_border,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPopularServices() {
    // สร้างรายการคีย์บริการที่เรียงลำดับตาม rating (จากมากไปน้อย)
    List<String> sortedServiceKeys = _popularServiceDetails.keys.toList();
    if (!isLoading['servicePopularity']!) {
      sortedServiceKeys.sort((a, b) {
        double ratingA = _servicePopularityData[a]?['rating'] ?? 0.0;
        double ratingB = _servicePopularityData[b]?['rating'] ?? 0.0;
        return ratingB.compareTo(ratingA); // เรียงจากมากไปน้อย
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: sortedServiceKeys.map((serviceKey) {
          // ดึงข้อมูล rating และ reviews จาก _servicePopularityData
          final serviceRating = _servicePopularityData[serviceKey]?['rating']?.toStringAsFixed(1) ?? 'N/A';
          final serviceReviews = _servicePopularityData[serviceKey]?['reviews'] ?? 0;
          final displayRatingText = "$serviceRating (${NumberFormat.compact().format(serviceReviews)}${widget.isEnglish ? ' reviews' : ' รีวิว'})";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPopularServiceIcon(serviceKey), // ใช้ฟังก์ชันดึงไอคอน
                    size: 40,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPopularServiceName(serviceKey), // ใช้ฟังก์ชันดึงชื่อที่แปลแล้ว
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center, // จัดข้อความให้อยู่ตรงกลาง
                ),
                // แสดง Rating และจำนวนรีวิว
                isLoading['servicePopularity']!
                    ? const SizedBox(
                        width: 20, // กำหนดขนาดที่เหมาะสม
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : Text(
                        displayRatingText,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String rating; // เปลี่ยนเป็น String เพื่อรองรับ "Loading..."

  const CategoryCard({
    required this.icon,
    required this.label,
    required this.rating,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.red),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(rating, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
}
