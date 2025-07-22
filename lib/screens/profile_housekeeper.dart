import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/editprofile_housekeeper.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart';
import 'package:maebanjumpen/screens/login.dart';

class ProfilePage extends StatefulWidget {
  final Housekeeper user;
  final bool isEnglish;

  const ProfilePage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showFullAddress = false;
  final int _maxAddressLength = 40;

  late Housekeeper _currentUser;

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
    _currentUser = widget.user;
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

  @override
  Widget build(BuildContext context) {
    final housekeeper = _currentUser;
    final isEnglish = widget.isEnglish;

    String fullName =
        '${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}'
            .trim();
    if (fullName.isEmpty) fullName = isEnglish ? 'Unknown User' : 'ผู้ใช้ไม่ระบุชื่อ';

    String email = housekeeper.person?.email ?? (isEnglish ? 'No email' : 'ไม่มีอีเมล');
    String phone = housekeeper.person?.phoneNumber ?? (isEnglish ? 'No phone' : 'ไม่มีเบอร์โทรศัพท์');
    String address = housekeeper.person?.address ?? (isEnglish ? 'No address provided' : 'ไม่มีที่อยู่');
    // เพิ่ม Daily Rate
    String dailyRate = housekeeper.dailyRate?.toStringAsFixed(2) ?? '0.00'; // แสดงเป็นทศนิยม 2 ตำแหน่ง, ค่าเริ่มต้น 0.00

    // --- ส่วนนี้คือการปรับปรุงการจัดการรูปโปรไฟล์ ---
    Widget profileImageWidget;
    if (housekeeper.person?.pictureUrl != null && housekeeper.person!.pictureUrl!.isNotEmpty) {
      // พยายามโหลดจาก Network
      profileImageWidget = Image.network(
        housekeeper.person!.pictureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // ถ้า NetworkImage โหลดไม่ได้ ให้ fallback ไปที่ AssetImage
          print('Error loading network image: $error');
          return Image.asset(
            'assets/profile.jpg', // Path ไปยังรูป fallback ใน assets
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // ถ้า AssetImage ก็โหลดไม่ได้ ให้แสดงไอคอน default
              print('Error loading asset image (fallback): $error');
              return const Icon(Icons.person, size: 100, color: Colors.grey); // ไอคอนคนสีเทา
            },
          );
        },
      );
    } else {
      // ถ้าไม่มี URL รูปโปรไฟล์ ให้ใช้ AssetImage เป็น fallback ตั้งแต่แรก
      profileImageWidget = Image.asset(
        'assets/profile.jpg', // Path ไปยังรูป fallback ใน assets
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // ถ้า AssetImage ก็โหลดไม่ได้ ให้แสดงไอคอน default
          print('Error loading asset image (initial fallback): $error');
          return const Icon(Icons.person, size: 100, color: Colors.grey); // ไอคอนคนสีเทา
        },
      );
    }
    // ---------------------------------------------


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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HousekeeperPage(
                user: _currentUser,
                isEnglish: widget.isEnglish,
              ),
            ),
          ),
        ),
        title: Center(
          child: Text(
            isEnglish ? 'Profile' : 'โปรไฟล์',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60.0,
                  // --- ใช้ Widget ที่สร้างไว้ด้านบน ---
                  child: ClipOval( // ใช้ ClipOval เพื่อตัดรูปให้เป็นวงกลม
                    child: SizedBox(
                      width: 120, // 2 * radius
                      height: 120, // 2 * radius
                      child: profileImageWidget,
                    ),
                  ),
                  // -----------------------------------
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
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              ),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  isEnglish ? 'Housekeeper Skills' : 'ทักษะแม่บ้าน',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
                      children: _currentUser.housekeeperSkills!
                          .map(
                            (skill) {
                              final String backendSkillName = skill.skillType?.skillTypeName ?? '';
                              final Map<String, dynamic>? details = _skillDetails[backendSkillName];

                              final IconData icon = details?['icon'] ?? Icons.build;
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
                                  mainAxisSize: MainAxisSize.min,
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
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    _buildInfoRow(
                        Icons.person_outline, isEnglish ? 'Full Name' : 'ชื่อ-นามสกุล', fullName),
                    Divider(height: 24, color: Colors.grey[300]),
                    _buildInfoRow(Icons.email_outlined, 'Email', email),
                    Divider(height: 24, color: Colors.grey[300]),
                    _buildInfoRow(
                        Icons.phone_outlined, isEnglish ? 'Phone' : 'เบอร์โทรศัพท์', phone),
                    Divider(height: 24, color: Colors.grey[300]),
                    // *** เพิ่ม Daily Rate ตรงนี้ ***
                    _buildInfoRow(
                        Icons.payments_outlined, // หรือไอคอนที่เหมาะสม
                        isEnglish ? 'Daily Rate' : 'ค่าจ้างต่อวัน',
                        '$dailyRate ${isEnglish ? 'THB' : 'บาท'}'),
                    Divider(height: 24, color: Colors.grey[300]),
                    // *** สิ้นสุดการเพิ่ม Daily Rate ***
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.red),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEnglish ? 'Address' : 'ที่อยู่',
                                style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                              ),
                              Text(
                                displayedAddress,
                                style:
                                    const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
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
                                        color: Colors.red, fontWeight: FontWeight.bold),
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
                      isEnglish ? 'Social Media' : 'โซเชียลมีเดีย',
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
                    _buildSocialMediaRow(
                      'Facebook',
                      _currentUser.facebookLink ?? (isEnglish ? 'Not provided' : 'ไม่ได้ระบุ'),
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/800px-2021_Facebook_icon.svg.png',
                      backgroundColor: Colors.transparent,
                    ),
                    Divider(height: 24, color: Colors.grey[300]),
                    _buildSocialMediaRow(
                      'Line',
                      _currentUser.lineId ?? (isEnglish ? 'Not provided' : 'ไม่ได้ระบุ'),
                      'https://upload.wikimedia.org/wikipedia/commons/2/2e/LINE_New_App_Icon_%282020-12%29.png',
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                isEnglish ? 'Logout' : 'ออกจากระบบ',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างการ์ด Skill ให้เหมือน ViewHousekeeperPage
  Widget _buildSkillCard(String text, IconData iconData) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialMediaRow(String platform, String handle, String iconUrl,
      {Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Image.network(
              iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return Container(
                  width: 30.0,
                  height: 30.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                ),
                Text(
                  handle,
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16.0),
          const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}