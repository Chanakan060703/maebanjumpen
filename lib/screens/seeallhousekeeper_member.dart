// lib/screens/seeallhousekeeper_member.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/screens/viewhousekeeper_member.dart';

class SeeAllHousekeeperPage extends StatefulWidget {
  final bool isEnglish;
  final Hirer user;

  const SeeAllHousekeeperPage({
    super.key,
    required this.isEnglish,
    required this.user,
  });

  @override
  _SeeAllHousekeeperPageState createState() => _SeeAllHousekeeperPageState();
}

class _SeeAllHousekeeperPageState extends State<SeeAllHousekeeperPage> {
  // เพิ่ม _skillDetails map เข้ามาใน class นี้
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

  // เพิ่ม TextEditingController สำหรับช่องค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // ตัวแปรสำหรับเก็บคำค้นหา

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // เมธอดสำหรับจัดการการเปลี่ยนแปลงของคำค้นหา
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }


  // --- ปรับปรุง _buildImageProvider ให้รองรับเฉพาะ URL หรือ Placeholder ---
  ImageProvider _buildImageProvider(String? pictureUrl) {
    // ถ้า pictureUrl เป็น null หรือว่างเปล่า ให้ใช้ placeholder
    if (pictureUrl == null || pictureUrl.isEmpty) {
      return const AssetImage(
        'assets/profile.jpg',
      ); // ใช้รูปภาพเริ่มต้นจาก assets
    }

    // ถ้า pictureUrl เป็น URL จริงๆ (http หรือ https) ให้ใช้ NetworkImage
    if (pictureUrl.startsWith('http://') || pictureUrl.startsWith('https://')) {
      return NetworkImage(pictureUrl);
    }

    // กรณีอื่นๆ ให้กลับไปใช้ placeholder เพื่อความปลอดภัย
    print(
      'Warning: Unexpected picture format. Using placeholder for: $pictureUrl',
    );
    return const AssetImage(
      'assets/profile.jpg',
    ); // ใช้รูปภาพเริ่มต้นจาก assets
  }

  // Function to calculate display rating for stars (Round to nearest 0.5)
  double _getDisplayRatingForStars(double? actualRating) {
    if (actualRating == null) return 0.0;
    return (actualRating * 2).roundToDouble() / 2;
  }

  // Function to build star rating widgets
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

  // เพิ่มฟังก์ชันนี้เพื่อดึงชื่อทักษะตามภาษา
  String _getSkillName(String? skillTypeName) {
    if (skillTypeName == null || skillTypeName.isEmpty) {
      return widget.isEnglish ? 'Unknown Skill' : 'ทักษะไม่ระบุ';
    }
    final detail = _skillDetails[skillTypeName];
    if (detail != null) {
      return widget.isEnglish ? detail['enName']! : detail['thaiName']!;
    } else {
      return skillTypeName; // Fallback to original name if not found in map
    }
  }

  // ฟังก์ชันสำหรับสร้าง Widget แสดง Chip ทักษะ
  Widget _buildServiceChip(
    String label, {
    Color textColor = Colors.red,
    Color borderColor = Colors.red,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // ปรับ padding ให้กระชับ
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1), // สีพื้นหลังจางๆ
        border: Border.all(color: borderColor, width: 0.8), // ขอบ
        borderRadius: BorderRadius.circular(20), // มุมโค้งมน
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12), // ปรับขนาด font
        maxLines: 1, // ป้องกันการขึ้นบรรทัดใหม่ใน Chip เดียว
        overflow: TextOverflow.ellipsis, // หากข้อความยาวเกินไปให้แสดง ...
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          // ปุ่มย้อนกลับ
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.red,
          ), // เปลี่ยน icon และสีตามที่ร้องขอ
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: const AssetImage('assets/images/logo.png'),
              radius: 20,
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading logo image: $exception');
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController, // กำหนด Controller
                decoration: InputDecoration(
                  hintText:
                      widget.isEnglish
                          ? 'Search...'
                          : 'ค้นหา...', // เพิ่ม hintText ตามภาษา
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Housekeeper>>(
        future: HousekeeperController().getListHousekeeper().then(
          (value) => value ?? [],
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            List<Housekeeper> housekeepers = snapshot.data!;

            // กรองข้อมูลตามคำค้นหาและสถานะ verified
            final filteredHousekeepers =
                housekeepers.where((housekeeper) {
                  final fullName =
                      "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}"
                          .toLowerCase();
                  final address =
                      (housekeeper.person?.address ?? '').toLowerCase();
                  final skills = (housekeeper.housekeeperSkills ?? [])
                      .map(
                        (s) =>
                            _getSkillName(
                              s.skillType?.skillTypeName,
                            ).toLowerCase(),
                      )
                      .join(' ');
                  final query = _searchQuery.toLowerCase();

                  // ตรวจสอบสถานะ verified
                  final isVerified =
                      housekeeper.statusVerify == 'verified' ||
                      housekeeper.statusVerify == 'APPROVED';

                  // คืนค่า true ถ้าตรงกับคำค้นหาและสถานะเป็น verified
                  return isVerified &&
                      (fullName.contains(query) ||
                          address.contains(query) ||
                          skills.contains(query));
                }).toList();

            if (filteredHousekeepers.isEmpty) {
              return Center(
                child: Text(
                  widget.isEnglish
                      ? 'No housekeepers found matching your search.'
                      : 'ไม่พบแม่บ้านที่ตรงกับคำค้นหาของคุณ',
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredHousekeepers.length,
              itemBuilder: (context, index) {
                final housekeeper =
                    filteredHousekeepers[index]; // ใช้ข้อมูลที่ถูกกรอง
                final displayRatingForStars = _getDisplayRatingForStars(
                  housekeeper.rating,
                );

                final List<Widget> skillChips =
                    (housekeeper.housekeeperSkills ?? [])
                        .map(
                          (skill) => Padding(
                            padding: const EdgeInsets.only(right: 4, bottom: 4),
                            child: _buildServiceChip(
                              _getSkillName(skill.skillType?.skillTypeName),
                              textColor: Colors.red,
                              borderColor: Colors.red.withOpacity(0.5),
                            ),
                          ),
                        )
                        .toList();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewHousekeeperPage(
                                housekeeper: housekeeper,
                                isEnglish: widget.isEnglish,
                                user: widget.user,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: _buildImageProvider(
                              housekeeper.person?.pictureUrl,
                            ),
                            backgroundColor: Colors.grey.shade200,
                            onBackgroundImageError: (exception, stackTrace) {
                              print(
                                'Error loading image for housekeeper ${housekeeper.person?.firstName}: $exception',
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${housekeeper.person?.firstName ?? ''} ${housekeeper.person?.lastName ?? ''}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (housekeeper.statusVerify ==
                                            'verified' ||
                                        housekeeper.statusVerify == 'APPROVED')
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                      if (housekeeper.rating != null &&
                                          housekeeper.rating! > 0) ...[
                                        _buildStarRating(
                                          displayRatingForStars,
                                          iconSize: 14.0,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          housekeeper.rating!.toStringAsFixed(
                                            1,
                                          ), 
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    
                                  ],
                                ),

                                // --- END RATING & REVIEWS DISPLAY ---
                                const SizedBox(height: 4),

                                // ส่วนของ Skill Chips
                                if (skillChips.isNotEmpty)
                                  Wrap(
                                    spacing: 0,
                                    runSpacing: 0,
                                    children: skillChips,
                                  )
                                else
                                  Text(
                                    widget.isEnglish
                                        ? "No skills"
                                        : "ไม่มีทักษะ",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),

                                const SizedBox(height: 4),

                                // ส่วนของ Location
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${housekeeper.person?.address ?? (widget.isEnglish ? 'Address not available' : 'ที่อยู่ไม่ระบุ')}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ), // เว้นระยะก่อนราคาและปุ่ม
                                // ⭐️ --- ส่วนของ Rate และ Button (ปรับให้ปุ่มอยู่บรรทัดใหม่) ---
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. ราคา (จะอยู่บรรทัดแรกของ Column)
                                    Text(
                                      "${housekeeper.dailyRate != null && housekeeper.dailyRate!.isNotEmpty ? "${housekeeper.dailyRate} ฿" : (widget.isEnglish ? 'Negotiable' : 'สอบถามราคา')}/${widget.isEnglish ? 'day' : 'วัน'}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),

                                    const SizedBox(height: 8), // เพิ่มช่องว่าง
                                    // 2. ปุ่ม View Profile (จะอยู่บรรทัดที่สองของ Column)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    context,
                                                  ) => ViewHousekeeperPage(
                                                    housekeeper: housekeeper,
                                                    isEnglish: widget.isEnglish,
                                                    user: widget.user,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                16, // เพิ่ม padding เพื่อให้ปุ่มใหญ่ขึ้น
                                            vertical: 10,
                                          ),
                                          minimumSize: const Size(
                                            120,
                                            0,
                                          ), // กำหนดความกว้างขั้นต่ำ
                                        ),
                                        child: Text(
                                          widget.isEnglish
                                              ? 'View Profile'
                                              : 'ดูโปรไฟล์',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // --- END Rate และ Button ---
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                widget.isEnglish
                    ? 'No housekeepers found.'
                    : 'ไม่พบข้อมูลแม่บ้าน',
              ),
            );
          }
        },
      ),
    );
  }
}
