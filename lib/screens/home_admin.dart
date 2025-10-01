import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/person.dart'; // ตรวจสอบให้แน่ใจว่ามีการ import Person model
import 'package:maebanjumpen/screens/listregister_admin.dart';
import 'package:maebanjumpen/screens/listreport_admin.dart'; // ตรวจสอบว่าชื่อไฟล์และคลาสตรงกัน
import 'package:maebanjumpen/screens/profile_admin.dart';
import 'package:maebanjumpen/screens/login.dart'; // Import หน้า Login

class HomeAdminPage extends StatefulWidget {
  final Admin user;
  final bool isEnglish;

  const HomeAdminPage({
    super.key,
    required this.user,
    this.isEnglish = false, // ค่าเริ่มต้นเป็นภาษาไทย
  });

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  int _selectedIndex = 0; // Tracks the currently selected tab index
  late List<Widget> _pages; // List of widgets for each tab's content

  @override
  void initState() {
    super.initState();
    // Initialize _pages here, so widget.user and widget.isEnglish are available

    // ตรวจสอบ user.person ก่อนส่งไปให้ ListReportScreen เพื่อป้องกัน null reference
    final Person defaultPerson = Person(
      personId: 0, // ควรเป็น ID ที่เหมาะสม หรือ 0 ถ้าไม่มีผลต่อ logic อื่น
      firstName: widget.isEnglish ? 'Default' : 'ผู้ใช้งาน',
      lastName: widget.isEnglish ? 'User' : 'เริ่มต้น',
      email: '', // Provide default values for required fields
      phoneNumber: '', // เพิ่มฟิลด์ที่จำเป็น
      address: '', // เพิ่มฟิลด์ที่จำเป็น
      idCardNumber: '', // เพิ่มฟิลด์ที่จำเป็น
      pictureUrl: '', // เพิ่มฟิลด์ที่จำเป็น
      accountStatus: 'active', // เพิ่มฟิลด์ที่จำเป็น
    );

    _pages = [
      // Index 0: Home/Dashboard - จะถูกสร้างโดย _buildHomePageContent()
      _buildHomePageContent(),
      // Index 1: Verify Page (ตอนนี้เป็น VerlifyRegisterScreen)
      VerlifyRegisterScreen(
        isEnglish: widget.isEnglish,
        admin: widget.user, // ส่ง Admin object ไปด้วย
      ),
      // Index 2: Penalty (Now points to ListReportScreen)
      ListReportScreen(
        user: widget.user.person ?? defaultPerson, // ส่งค่าเริ่มต้นถ้า widget.user.person เป็น null
        admin: widget.user,
        isEnglish: widget.isEnglish,
      ),
      // Index 3: Profile
      ProfileAdminPage(user: widget.user, isEnglish: widget.isEnglish),
    ];
  }

  // ฟังก์ชันสำหรับจัดการการออกจากระบบ (ย้ายมาที่ HomeAdminPage)
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(), // กลับไปหน้า Login
      ),
      (Route<dynamic> route) => false, // ลบทุก Route ที่มีอยู่ก่อนหน้า
    );
  }

  // ฟังก์ชันช่วยในการสร้าง ImageProvider สำหรับรูปโปรไฟล์
  ImageProvider _buildImageProvider(String? url) {
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        // ตรวจสอบทั้ง isAbsolute และ scheme เพื่อให้แน่ใจว่าเป็น URL ที่ถูกต้อง
        if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
          return NetworkImage(url);
        } else {
          debugPrint('DEBUG(AdminHome): URL ไม่ถูกต้องหรือไม่ใช่ absolute: $url');
        }
      } catch (e) {
        debugPrint('DEBUG(AdminHome): เกิดข้อผิดพลาดในการแยกวิเคราะห์ URL: $url, Exception: $e');
      }
    }
    debugPrint('DEBUG(AdminHome): ใช้รูปภาพเริ่มต้น เนื่องจาก URL ไม่ถูกต้องหรือว่างเปล่า');
    // ต้องแน่ใจว่า 'assets/images/default_profile.png' มีอยู่จริงและอยู่ใน pubspec.yaml
    return const AssetImage('assets/images/default_profile.png');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    debugPrint('Tapped item: $index'); // สำหรับการดีบัก
  }

  // Widget Helper to create action cards (e.g., Verify Register, Penalty)
  Widget _buildActionCard({
    required IconData icon,
    required String text,
    required int targetIndex, // Parameter to specify which tab to navigate to
  }) {
    return Expanded( // ทำให้ Card ขยายเต็มพื้นที่ที่เหลือใน Row
      child: GestureDetector(
        onTap: () {
          _onItemTapped(targetIndex); // Switch to the specified tab index
          debugPrint('$text ถูกกด, กำลังนำทางไปยัง index $targetIndex');
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the content for the Admin Home (Dashboard) page
  Widget _buildHomePageContent() {
    // Safely get user details, providing fallbacks
    final String firstName = widget.user.person?.firstName ?? (widget.isEnglish ? 'Admin' : 'ผู้ดูแล');
    final String lastName = widget.user.person?.lastName ?? (widget.isEnglish ? 'User' : 'ระบบ');
    final String fullName = '$firstName $lastName';
    final String? profilePictureUrl = widget.user.person?.pictureUrl;

    debugPrint('DEBUG(AdminHome): profilePictureUrl ที่ได้รับ: $profilePictureUrl');

    return SingleChildScrollView(
      child: SafeArea( // ใช้ SafeArea เพื่อให้เนื้อหาไม่ทับกับ status bar
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section: Profile picture and name (part of the content, not AppBar)
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _buildImageProvider(profilePictureUrl),
                    backgroundColor: Colors.grey.shade300,
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint('DEBUG(AdminHome): เกิดข้อผิดพลาดในการโหลดรูปภาพสำหรับ Admin: $exception');
                    },
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // *** แก้ไขตรงนี้: ลดระยะห่างระหว่างชื่อกับไอคอน ***
                  const SizedBox(width: 4), // ลดจาก 8 เป็น 4
                  const Icon(Icons.check_circle, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(height: 30),

              // Action buttons for Admin (Verify Register and Penalty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionCard(
                    icon: Icons.person_outline,
                    text: widget.isEnglish ? 'Verify Register' : 'ยืนยันการลงทะเบียน',
                    targetIndex: 1, // Index for Verify Page
                  ),
                  const SizedBox(width: 15),
                  _buildActionCard(
                    icon: Icons.gavel, // Icon for Penalty
                    text: widget.isEnglish ? 'Penalty' : 'ลงโทษ', // Label is 'Penalty'
                    targetIndex: 2, // Index for Penalty (ListReportScreen)
                  ),
                ],
              ),
              // สามารถเพิ่มเนื้อหาอื่นๆ ในหน้า Home ได้ที่นี่
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    List<Widget> appBarActions = []; // List เพื่อเก็บ Action buttons ใน AppBar

    // กำหนดชื่อ AppBar และปุ่ม Action ตาม Tab ที่เลือก
    switch (_selectedIndex) {
      case 0:
        // หน้าแรก (Home) จะไม่มี AppBar
        appBarTitle = ''; // ไม่ถูกใช้เมื่อ appBar: null
        break;
      case 1:
        appBarTitle = widget.isEnglish ? 'Verify Accounts' : 'ยืนยันบัญชี';
        break;
      case 2:
        appBarTitle = widget.isEnglish ? 'Report' : 'ผู้ใช้ที่ถูกรายงาน';
        break;
      case 3:
        appBarTitle = widget.isEnglish ? 'Admin Profile' : 'โปรไฟล์ผู้ดูแล';
        // เพิ่มปุ่ม Logout เมื่ออยู่บน Tab Profile
        appBarActions.add(
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout, // เรียกฟังก์ชัน logout
          ),
        );
        break;
      default:
        appBarTitle = widget.isEnglish ? 'Admin Panel' : 'แผงควบคุมผู้ดูแล';
    }

    return Scaffold(
      // *** การเปลี่ยนแปลงสำคัญตรงนี้: กำหนด AppBar เป็น null เมื่อ _selectedIndex เป็น 0 ***
      appBar: _selectedIndex == 0
          ? null // ถ้าเป็นหน้า Home (index 0) จะไม่มี AppBar
          : AppBar(
              title: Text(
                appBarTitle,
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5, // เพิ่มเงาเล็กน้อยให้กับ AppBar
              centerTitle: false,
              // ปุ่มย้อนกลับ (leading icon)
              leading: IconButton( // ปุ่มย้อนกลับจะแสดงเสมอเมื่อมี AppBar (ยกเว้นหน้า Home ที่ไม่มี AppBar)
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () {
                  // เมื่อกดปุ่มย้อนกลับ ให้กลับไปที่ Tab Home (index 0)
                  _onItemTapped(0);
                },
              ),
              actions: appBarActions, // แสดง Action buttons ตาม Tab ที่เลือก
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedItemColor: Colors.red, // Color for the selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        currentIndex: _selectedIndex, // The currently active tab
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user), // Icon for Verify
            label: widget.isEnglish ? 'Verify' : 'ยืนยันตัวตน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.gavel), // Icon for Penalty
            label: widget.isEnglish ? 'Penalty' : 'ลงโทษ', // Label is 'Penalty'
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        onTap: _onItemTapped, // Callback when a tab is tapped
      ),
    );
  }
}
