// lib/screens/verlify_register_screen.dart

import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/screens/view_register_admin.dart'; // Import หน้า Detail

class VerlifyRegisterScreen extends StatefulWidget {
  final bool isEnglish;
  final Admin admin; 

  const VerlifyRegisterScreen({
    super.key,
    required this.isEnglish,
    required this.admin,
  });

  @override
  State<VerlifyRegisterScreen> createState() => _VerlifyRegisterScreenState();
}

class _VerlifyRegisterScreenState extends State<VerlifyRegisterScreen> {
  final HousekeeperController _housekeeperController = HousekeeperController();
  late Future<List<Housekeeper>> _notVerifiedHousekeepersFuture;

  @override
  void initState() {
    super.initState();
    _notVerifiedHousekeepersFuture = _housekeeperController.getNotVerifiedHousekeepers();
  }

  // ฟังก์ชันสำหรับรีเฟรชข้อมูล
  Future<void> _refreshHousekeepers() async {
    setState(() {
      _notVerifiedHousekeepersFuture = _housekeeperController.getNotVerifiedHousekeepers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Housekeeper>>(
        future: _notVerifiedHousekeepersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.isEnglish
                      ? 'Error loading data: ${snapshot.error}'
                      : 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                widget.isEnglish
                    ? 'No unverified housekeepers found.'
                    : 'ไม่พบแม่บ้านที่ยังไม่ได้รับการยืนยัน',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else {
            // แสดงรายการแม่บ้านที่ยังไม่ได้รับการยืนยัน
            return RefreshIndicator(
              onRefresh: _refreshHousekeepers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final housekeeper = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: UserRegistrationCard(
                      imageUrl: housekeeper.person?.pictureUrl ?? 'assets/images/default_profile.png', 
                      name: '${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}',
                      roleId: widget.isEnglish 
                          ? 'Housekeeper\nID: ${housekeeper.id ?? ''}'
                          : 'แม่บ้าน\nID: ${housekeeper.id ?? ''}',
                      username: housekeeper.person?.login?.username ?? '',
                      onView: () async {
                        // *** นำทางไปยังหน้า VerlifyRegisterDetailScreen พร้อมส่งข้อมูล ***
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerifyRegisterDetailScreen(
                              housekeeper: housekeeper,
                              isEnglish: widget.isEnglish,
                            ),
                          ),
                        );
                        // เมื่อกลับมาจากหน้า Detail ให้รีเฟรชข้อมูลในหน้านี้
                        _refreshHousekeepers();
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

// UserRegistrationCard Widget
class UserRegistrationCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String roleId;
  final String username;
  final VoidCallback onView;

  const UserRegistrationCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.roleId,
    required this.username,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = AssetImage(imageUrl);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleId,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Username : $username',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 20),
                    label: const Text(
                      'View',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}