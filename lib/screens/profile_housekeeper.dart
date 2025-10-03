import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/editprofile_housekeeper.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart';
import 'package:maebanjumpen/screens/login.dart';

class ProfilePage extends StatefulWidget {
  final Housekeeper user;
  final bool isEnglish;

  const ProfilePage({super.key, required this.user, required this.isEnglish});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showFullAddress = false;
  final int _maxAddressLength = 40;
  late Housekeeper _currentUser;
  bool _isLoading = false;

  // รายละเอียดของแต่ละประเภททักษะ (SkillType)
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

  // เปลี่ยน Map เป็น List เพื่อแก้ไขข้อผิดพลาด
  final List<Map<String, dynamic>> _skillLevels = [
    {
      'id': 1,
      'en': 'Beginner',
      'th': 'มือใหม่',
      'minHiresForLevel': 0,
      'color': Colors.blueAccent
    },
    {
      'id': 2,
      'en': 'Intermediate',
      'th': 'ฝึกหัด',
      'minHiresForLevel': 5,
      'color': Colors.green
    },
    {
      'id': 3,
      'en': 'Advanced',
      'th': 'ชำนาญ',
      'minHiresForLevel': 20,
      'color': Colors.orange
    },
    {
      'id': 4,
      'en': 'Expert',
      'th': 'เชี่ยวชาญ',
      'minHiresForLevel': 50,
      'color': Colors.red
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // เรียกใช้เมธอดโหลดข้อมูลเมื่อเริ่มต้น
    _fetchUserProfile();
  }
  
  // 🟢 เมธอดสำหรับโหลดและรีเฟรชข้อมูลโปรไฟล์
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⏳ จำลองการรอโหลดข้อมูลจาก API (1.5 วินาที)
      // **ในโค้ดจริง คุณต้องเพิ่มการเรียก API เพื่อดึงข้อมูล Housekeeper ล่าสุดที่นี่**
      await Future.delayed(const Duration(milliseconds: 1500)); 
      
      // ตัวอย่าง: Housekeeper latestUser = await ApiService.fetchHousekeeperProfile(_currentUser.id);
      final updatedUser = widget.user; // ใช้ข้อมูลเดิมเนื่องจากเป็นตัวอย่าง
      
      setState(() {
        _currentUser = updatedUser; 
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? 'Failed to refresh profile.' : 'โหลดข้อมูลโปรไฟล์ไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateToEditProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileHousekeeperPage(
          user: _currentUser,
          isEnglish: widget.isEnglish,
        ),
      ),
    );

    if (updatedUser != null && updatedUser is Housekeeper) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  Map<String, dynamic> _getSkillLevel(int totalHiresCompleted) {
    // ใช้ for loop เพื่อค้นหาจาก List ที่แก้ไขแล้ว
    for (var level in _skillLevels.reversed) {
      if (totalHiresCompleted >= level['minHiresForLevel']) {
        return level;
      }
    }
    return _skillLevels.first;
  }

  @override
  Widget build(BuildContext context) {
    final housekeeper = _currentUser;
    final isEnglish = widget.isEnglish;

    String fullName =
        '${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}'
            .trim();
    if (fullName.isEmpty)
      fullName = isEnglish ? 'Unknown User' : 'ผู้ใช้ไม่ระบุชื่อ';

    String email =
        housekeeper.person?.email ?? (isEnglish ? 'No email' : 'ไม่มีอีเมล');
    String phone =
        housekeeper.person?.phoneNumber ?? (isEnglish ? 'No phone' : 'ไม่มีเบอร์โทรศัพท์');
    String address =
        housekeeper.person?.address ?? (isEnglish ? 'No address provided' : 'ไม่มีที่อยู่');
    String dailyRate = (housekeeper.dailyRate is num)
        ? (housekeeper.dailyRate as num).toStringAsFixed(2)
        : '0.00';

    Widget profileImageWidget;
    if (housekeeper.person?.pictureUrl != null &&
        housekeeper.person!.pictureUrl!.isNotEmpty) {
      profileImageWidget = Image.network(
        housekeeper.person!.pictureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/profile.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 100,
                color: Colors.grey,
              );
            },
          );
        },
      );
    } else {
      profileImageWidget = Image.asset(
        'assets/profile.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 100,
            color: Colors.grey,
          );
        },
      );
    }

    String displayedAddress = address;
    bool showReadMoreButton = false;
    String readMoreButtonText = isEnglish ? 'Read More' : 'ดูเพิ่มเติม';

    if (address.length > _maxAddressLength) {
      if (!_showFullAddress) {
        displayedAddress = '${address.substring(0, _maxAddressLength)}...';
        showReadMoreButton = true;
        readMoreButtonText = isEnglish ? 'Read More' : 'ดูเพิ่มเติม';
      } else {
        displayedAddress = address;
        showReadMoreButton = true;
        readMoreButtonText = isEnglish ? 'Read Less' : 'ดูน้อยลง';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // 🟢 เริ่มต้น RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile, // 🟢 กำหนดให้เรียกฟังก์ชันโหลดข้อมูลเมื่อดึงลง
        color: Colors.red, // สีของวงกลมโหลด
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // physics: const AlwaysScrollableScrollPhysics(), // เป็นตัวเลือกเสริมเพื่อให้ดึงลงได้แม้เนื้อหาสั้น
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60.0,
                    child: ClipOval(
                      child: SizedBox(
                        width: 120, // 2 * radius
                        height: 120, // 2 * radius
                        child: profileImageWidget,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _navigateToEditProfile,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit, color: Colors.red),
                label: Text(
                  isEnglish ? 'Edit Profile' : 'แก้ไขโปรไฟล์',
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Text(
                    isEnglish ? 'Housekeeper Skills' : 'ทักษะแม่บ้าน',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (_currentUser.housekeeperSkills != null &&
                        _currentUser.housekeeperSkills!.isNotEmpty)
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _currentUser.housekeeperSkills!.map((skill) {
                          final String backendSkillName =
                              skill.skillType?.skillTypeName ?? '';
                          final int totalHiresCompleted =
                              skill.totalHiresCompleted ?? 0;

                          final Map<String, dynamic>? skillTypeDetails =
                              _skillDetails[backendSkillName];
                          final IconData icon =
                              skillTypeDetails?['icon'] ?? Icons.build;
                          final String skillTypeNameDisplay = isEnglish
                              ? (skillTypeDetails?['enName'] ?? backendSkillName)
                              : (skillTypeDetails?['thaiName'] ?? backendSkillName);

                          final Map<String, dynamic> skillLevel =
                              _getSkillLevel(totalHiresCompleted);
                          final String skillLevelDisplay =
                              isEnglish ? skillLevel['en'] : skillLevel['th'];
                          final Color levelColor = skillLevel['color'];

                          return _buildSkillCardWithDetails(
                            skillTypeNameDisplay,
                            icon,
                            skillLevelDisplay,
                            levelColor,
                            totalHiresCompleted,
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        widget.isEnglish ? "No skills listed" : "ไม่มีความสามารถระบุ",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(color: Colors.grey[200]!, width: 1.0),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Personal Information' : 'ข้อมูลส่วนตัว',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildInfoRow(
                        Icons.person_outline,
                        isEnglish ? 'Full Name' : 'ชื่อ-นามสกุล',
                        fullName,
                      ),
                      Divider(height: 24, color: Colors.grey[300]),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                      Divider(height: 24, color: Colors.grey[300]),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                        phone,
                      ),
                      Divider(height: 24, color: Colors.grey[300]),
                      _buildInfoRow(
                        Icons.payments_outlined,
                        isEnglish ? 'Daily Rate' : 'ค่าจ้างต่อวัน',
                        '$dailyRate ${isEnglish ? 'THB' : 'บาท'}',
                      ),
                      Divider(height: 24, color: Colors.grey[300]),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnglish ? 'Address' : 'ที่อยู่',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  displayedAddress,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (showReadMoreButton)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showFullAddress = !_showFullAddress;
                                      });
                                    },
                                    child: Text(
                                      readMoreButtonText,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 15.0,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  isEnglish ? 'Logout' : 'ออกจากระบบ',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCardWithDetails(
    String skillTypeNameDisplay,
    IconData iconData,
    String skillLevelDisplay,
    Color levelColor,
    int totalHiresCompleted,
  ) {
    return Container(
      width:
          (MediaQuery.of(context).size.width - 32 - 12) / 2, // แบ่ง 2 คอลัมน์
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skillTypeNameDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                widget.isEnglish ? 'Level: ' : 'ระดับ: ',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  skillLevelDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.isEnglish ? 'Completed Hires: ' : 'งานที่ทำสำเร็จ: ',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  '$totalHiresCompleted',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}