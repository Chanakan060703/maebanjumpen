import 'package:flutter/material.dart';
import 'package:maebanjumpen/boxs/MemberProvider%20.dart';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/controller/memberController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/notificationScreen.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:maebanjumpen/screens/seeallhousekeeper_member.dart';
import 'package:maebanjumpen/screens/viewhousekeeper_member.dart';
import 'package:maebanjumpen/widgets/category_card_homeMember.dart';

import 'package:provider/provider.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final Hirer? user;
  final bool isEnglish;

  const HomePage({super.key, this.user, required this.isEnglish});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Housekeeper> housekeepers = [];
  Map<String, bool> isLoading = {
    'housekeepers': true,
    'balance': true,
    'servicePopularity': true,
  };
  Hirer? _currentUser;
  String _displayBalance = '0.00';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
      'icon': Icons.window,
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
  Map<String, Map<String, dynamic>> _servicePopularityData = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    _currentUser = memberProvider.currentUser as Hirer?;
    _updateBalanceDisplay();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      fetchHousekeepers();
    });
  }

  void _updateBalanceDisplay() {
    _displayBalance = NumberFormat(
      '#,##0.00',
    ).format(_currentUser?.balance ?? 0.0);
  }

  Future<void> _fetchLatestBalance() async {
    if (!mounted || _currentUser == null || _currentUser!.id == null) return;
    setState(() {
      isLoading['balance'] = true;
    });
    try {
      final MemberController memberController = MemberController();
      final Hirer? latestHirerData = await memberController.getHirerById(
        _currentUser!.id!.toString(),
      );
      if (mounted && latestHirerData != null) {
        setState(() {
          _currentUser = latestHirerData;
          _updateBalanceDisplay();
        });
        print(
          'HomePage Balance updated successfully to: ${_currentUser!.balance}',
        );
      } else if (mounted) {
        print(
          'HomePage: Failed to fetch latest hirer data or widget not mounted.',
        );
      }
    } catch (e) {
      print('HomePage: Error fetching latest balance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to load balance.'
                  : 'ไม่สามารถโหลดข้อมูลยอดเงินได้',
            ),
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

  Future<void> _fetchServicePopularityData() async {
    if (!mounted) return;
    setState(() {
      isLoading['servicePopularity'] = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseURL/maeban/services/popularity'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _servicePopularityData = data.map(
            (key, value) => MapEntry(key, value as Map<String, dynamic>),
          );
        });
        print(
          'Service popularity data fetched successfully: $_servicePopularityData',
        );
      } else {
        print(
          'Failed to fetch service popularity data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching service popularity data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Network error.' : 'ข้อผิดพลาดเครือข่าย',
            ),
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
    await fetchHousekeepers();
    await _fetchLatestBalance();
    await _fetchServicePopularityData();
  }

  Future<void> fetchHousekeepers() async {
    print("fetchHousekeepers: Attempting to fetch housekeepers...");
    if (housekeepers.isEmpty) {
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
        final filteredAndVerifiedList =
            list.where((housekeeper) {
              final fullName =
                  "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}"
                      .toLowerCase();
              final address = (housekeeper.person?.address ?? '').toLowerCase();
              final skills = (housekeeper.housekeeperSkills ?? [])
                  .map(
                    (s) =>
                        _getSkillName(s.skillType?.skillTypeName).toLowerCase(),
                  )
                  .join(' ');
              final query = _searchQuery.toLowerCase();
              final isVerified = housekeeper.statusVerify == 'verified';
              return isVerified &&
                  (fullName.contains(query) ||
                      address.contains(query) ||
                      skills.contains(query));
            }).toList();
        filteredAndVerifiedList.sort(
          (a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0),
        );
        final top5Housekeepers = filteredAndVerifiedList.take(5).toList();
        setState(() {
          housekeepers = top5Housekeepers;
          isLoading['housekeepers'] = false;
        });
      } else if (mounted) {
        setState(() {
          housekeepers = [];
          isLoading['housekeepers'] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading['housekeepers'] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to load housekeepers.'
                  : 'ไม่สามารถโหลดข้อมูลแม่บ้านได้',
            ),
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
    if (skillTypeName == null || skillTypeName.isEmpty)
      return widget.isEnglish ? 'Unknown Skill' : 'ทักษะไม่ระระบุ';
    final detail = _skillDetails[skillTypeName];
    return detail != null
        ? (widget.isEnglish ? detail['enName']! : detail['thaiName']!)
        : skillTypeName;
  }

  String _getPopularServiceName(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty)
      return widget.isEnglish ? 'Unknown Service' : 'บริการไม่ระบุ';
    final detail = _popularServiceDetails[serviceKey];
    return detail != null
        ? (widget.isEnglish ? detail['enName']! : detail['thaiName']!)
        : serviceKey;
  }

  IconData _getPopularServiceIcon(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty) return Icons.help_outline;
    final detail = _popularServiceDetails[serviceKey];
    return detail?['icon'] ?? Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MemberProvider>(
      builder: (context, memberProvider, child) {
        final loggedInUser = memberProvider.currentUser as Hirer?;
        final bool isLoggedIn = loggedInUser != null && loggedInUser.id != null;
        final pages =
            isLoggedIn
                ? [
                  _buildHomeScreenContent(),
                  CardpageMember(
                    user: loggedInUser,
                    isEnglish: widget.isEnglish,
                  ),
                  HireListPage(user: loggedInUser, isEnglish: widget.isEnglish),
                  ProfileMemberPage(
                    user: loggedInUser,
                    isEnglish: widget.isEnglish,
                  ),
                ]
                : [
                  _buildHomeScreenContent(),
                  const Center(child: Text("Please login to view this page")),
                  const Center(child: Text("Please login to view this page")),
                  const Center(child: Text("Please login to view this page")),
                ];

        return Scaffold(
          key: _scaffoldKey,
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            selectedFontSize: 14,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.red,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              final user =
                  Provider.of<MemberProvider>(
                    context,
                    listen: false,
                  ).currentUser;
              final isUserLoggedIn = user != null && user.id != null;

              if (index != 0 && !isUserLoggedIn) {
                // หากไม่ได้ล็อกอินและพยายามไปหน้าอื่นที่ไม่ใช่หน้าหลัก
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              } else {
                // หากล็อกอินแล้ว หรือยังอยู่หน้าหลัก
                setState(() {
                  _currentIndex = index;
                });
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
          endDrawer: Drawer(
            child: NotificationScreen(isEnglish: widget.isEnglish),
          ),
        );
      },
    );
  }

  Widget _buildHomeScreenContent() {
    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEnglish
                        ? "Popular Housekeeper"
                        : "แม่บ้านที่ได้รับความนิยม",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SeeAllHousekeeperPage(
                                isEnglish: widget.isEnglish,
                                user:
                                    _currentUser ??
                                    Hirer(), // Provide a default Hirer if null
                              ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: Text(
                      widget.isEnglish ? "See All" : "ดูทั้งหมด",
                      style: const TextStyle(
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
    final isLoggedIn =
        Provider.of<MemberProvider>(context, listen: false).currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.isEnglish ? "Search..." : "ค้นหา...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<NotificationManager>(
              builder: (context, notificationManager, child) {
                final unreadCount = notificationManager.unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, size: 28),
                      onPressed: () {
                        final loggedInUser =
                            Provider.of<MemberProvider>(
                              context,
                              listen: false,
                            ).currentUser;
                        if (loggedInUser == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        } else {
                          _scaffoldKey.currentState?.openEndDrawer();
                        }
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
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
        if (isLoggedIn)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 4),
              isLoading['balance']!
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                  : Text(
                    "฿$_displayBalance",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
            ],
          ),
      ],
    );
  }

  Widget _buildCategories() {
    List<String> sortedServiceKeys = _popularServiceDetails.keys.toList();
    if (!isLoading['servicePopularity']!) {
      sortedServiceKeys.sort((a, b) {
        double ratingA = _servicePopularityData[a]?['rating'] ?? 0.0;
        double ratingB = _servicePopularityData[b]?['rating'] ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          sortedServiceKeys.take(2).map((serviceKey) {
            final serviceRating =
                _servicePopularityData[serviceKey]?['rating']?.toStringAsFixed(
                  1,
                ) ??
                'N/A';
            final serviceReviews =
                _servicePopularityData[serviceKey]?['reviews'] ?? 0;
            final displayRatingText =
                "$serviceRating (${NumberFormat.compact().format(serviceReviews)}${widget.isEnglish ? ' reviews' : ' รีวิว'})";

            return CategoryCard(
              icon: _getPopularServiceIcon(serviceKey),
              label: _getPopularServiceName(serviceKey),
              rating:
                  isLoading['servicePopularity']!
                      ? (widget.isEnglish ? 'Loading...' : 'กำลังโหลด...')
                      : displayRatingText,
            );
          }).toList(),
    );
  }

  Widget _buildPopularHousekeepers() {
    if (isLoading['housekeepers']!) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (housekeepers.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            widget.isEnglish ? "No housekeepers found." : "ไม่พบข้อมูลแม่บ้าน",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: housekeepers.length,
              itemBuilder: (context, index) {
                final hk = housekeepers[index];
                final hasValidImageUrl =
                    hk.person?.pictureUrl != null &&
                    hk.person!.pictureUrl!.isNotEmpty &&
                    (hk.person!.pictureUrl!.startsWith('http://') ||
                        hk.person!.pictureUrl!.startsWith('https://'));
                final displayRatingForStars = _getDisplayRatingForStars(
                  hk.rating,
                );
                final List<String> translatedSkills =
                    hk.housekeeperSkills
                        ?.map(
                          (skill) =>
                              _getSkillName(skill.skillType?.skillTypeName),
                        )
                        .toList() ??
                    [];
                final String skillsDisplay =
                    translatedSkills.isNotEmpty
                        ? translatedSkills.join(', ')
                        : (widget.isEnglish ? "No skills" : "ไม่มีทักษะ");

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ViewHousekeeperPage(
                              housekeeper: hk,
                              isEnglish: widget.isEnglish,
                              user: _currentUser ?? Hirer(),
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
                                image: NetworkImage(hk.person!.pictureUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "${hk.person?.firstName ?? ''} ${hk.person?.lastName ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                              style: const TextStyle(color: Colors.red),
                            ),
                            const Icon(
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
    List<String> sortedServiceKeys = _popularServiceDetails.keys.toList();
    if (!isLoading['servicePopularity']!) {
      sortedServiceKeys.sort((a, b) {
        double ratingA = _servicePopularityData[a]?['rating'] ?? 0.0;
        double ratingB = _servicePopularityData[b]?['rating'] ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            sortedServiceKeys.map((serviceKey) {
              final serviceRating =
                  _servicePopularityData[serviceKey]?['rating']
                      ?.toStringAsFixed(1) ??
                  'N/A';
              final serviceReviews =
                  _servicePopularityData[serviceKey]?['reviews'] ?? 0;
              final displayRatingText =
                  "$serviceRating (${NumberFormat.compact().format(serviceReviews)}${widget.isEnglish ? ' reviews' : ' รีวิว'})";

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
                        _getPopularServiceIcon(serviceKey),
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPopularServiceName(serviceKey),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    isLoading['servicePopularity']!
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                        : Text(
                          displayRatingText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
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
