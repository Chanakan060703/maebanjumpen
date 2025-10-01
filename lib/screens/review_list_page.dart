import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/review.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

class ReviewListPage extends StatelessWidget {
  final String housekeeperName;
  final List<Review> reviews;
  final bool isEnglish;

  const ReviewListPage({
    super.key,
    required this.housekeeperName,
    required this.reviews,
    required this.isEnglish,
  });

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

  // ฟังก์ชันสำหรับคำนวณคะแนนที่ใช้แสดงผลดาว (โค้ดเดิม)
  double _getDisplayScore(double? actualScore) {
    if (actualScore == null || actualScore <= 0.0) return 0.0;
    // ปัดเศษให้ใกล้เคียง 0.5 ที่สุด: 4.2 -> 4.0, 4.3 -> 4.5
    return (actualScore * 2).round() / 2.0;
  }

  // ฟังก์ชันสำหรับสร้าง Widget แสดงผลดาว (โค้ดเดิม)
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
        title: Text(isEnglish ? 'All Reviews' : 'รีวิวทั้งหมด',
        style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryRed,
        elevation: 0,
      ),

      body:
          reviews.isEmpty
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
                  final review = reviews[index];

                  if (review.reviewMessage == null || review.score == null) {
                    return const SizedBox.shrink();
                  }

                  final String reviewerFirstName = review.hirerFirstName ?? '';
                  final String reviewerLastName = review.hirerLastName ?? '';
                  final String reviewerName =
                      (reviewerFirstName.isEmpty && reviewerLastName.isEmpty)
                          ? (isEnglish ? 'Anonymous User' : 'ผู้ใช้ไม่ระบุชื่อ')
                          : "$reviewerFirstName $reviewerLastName";

                  String formattedDate = '';
                  if (review.reviewDate != null) {
                    formattedDate = DateFormat(
                      isEnglish ? 'MMM dd, yyyy' : 'd MMMM yyyy',
                      isEnglish ? 'en_US' : 'th_TH',
                    ).format(review.reviewDate!.toLocal());
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        // 🛑 แก้ไข: ดึงรูปภาพจากฟิลด์ใหม่ hirerPictureUrl
                        backgroundImage: _getImageProvider(
                          review.hirerPictureUrl,
                        ),
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint(
                            'Error loading reviewer avatar image: $exception',
                          );
                        },
                      ),
                      title: Text(
                        reviewerName, // ✅ ใช้ชื่อที่ดึงมาจากฟิลด์ใหม่
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStarRating(_getDisplayScore(review.score)),
                          const SizedBox(height: 4),
                          Text(
                            review.reviewMessage ??
                                (isEnglish
                                    ? 'No comment provided.'
                                    : 'ไม่มีข้อความรีวิว'),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
