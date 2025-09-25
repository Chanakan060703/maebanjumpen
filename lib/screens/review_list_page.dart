// lib/screens/review_list_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/housekeeper.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

class ReviewListPage extends StatelessWidget {
  final String housekeeperName;
  final List<Hire> reviews; // ใช้ List<Hire> เพราะ review อยู่ใน Hire object
  final bool isEnglish;

  const ReviewListPage({
    super.key,
    required this.housekeeperName,
    required this.reviews,
    required this.isEnglish,
  });

  // ฟังก์ชันสำหรับแปลง String เป็น ImageProvider
  ImageProvider _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/image/icon_user.png');
    }
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return NetworkImage(imageData);
    }
    // กรณีเป็น Base64 String
    if (imageData.contains('data:image/') || imageData.length > 100) {
      try {
        String base64Stripped =
            imageData.contains(',') ? imageData.split(',')[1] : imageData;
        final decodedBytes = base64Decode(base64Stripped);
        return MemoryImage(decodedBytes);
      } catch (e) {
        debugPrint('Error decoding Base64 image in ReviewListPage: $e');
        return const AssetImage('assets/image/icon_user.png');
      }
    }
    return const AssetImage('assets/image/icon_user.png');
  }

  // ฟังก์ชันสำหรับคำนวณคะแนนที่ใช้แสดงผลดาว
  double _getDisplayScore(double? actualScore) {
    if (actualScore == null) return 0.0;
    double scoreAsDouble = actualScore.toDouble();
    if (scoreAsDouble % 1 == 0) {
      return scoreAsDouble;
    } else {
      return scoreAsDouble.floorToDouble() + 0.5;
    }
  }

  // ฟังก์ชันสำหรับสร้าง Widget แสดงผลดาว
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'All Reviews' : 'รีวิวทั้งหมด'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: reviews.isEmpty
          ? Center(
              child: Text(
                isEnglish
                    ? 'No reviews found for this housekeeper.'
                    : 'ไม่พบรีวิวสำหรับแม่บ้านคนนี้',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final hire = reviews[index];
                final review = hire.review;
                final hirer = hire.hirer;
                
                if (review == null || hirer == null || hirer.person == null) {
                  return const SizedBox.shrink(); // ข้ามไปถ้ารีวิวหรือข้อมูลผู้จ้างหายไป
                }

                String formattedDate = '';
                if (review.reviewDate != null) {
                  formattedDate = DateFormat(
                    'MMM dd, yyyy',
                    isEnglish ? 'en_US' : 'th_TH',
                  ).format(review.reviewDate!.toLocal());
                }

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _getImageProvider(hirer.person?.pictureUrl),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint(
                            'Error loading reviewer avatar image: $exception');
                      },
                    ),
                    title: Text(
                      "${hirer.person?.firstName ?? ''} ${hirer.person?.lastName ?? ''}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStarRating(_getDisplayScore(review.score)),
                        const SizedBox(height: 4),
                        Text(review.reviewMessage ?? ''),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}