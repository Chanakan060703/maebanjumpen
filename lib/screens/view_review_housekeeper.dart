import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hire.dart'; 
import 'package:intl/intl.dart'; 

class ViewReviewScreen extends StatelessWidget {
  final Hire hire;
  final bool isEnglish;

  const ViewReviewScreen({
    super.key,
    required this.hire,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบว่ามีรีวิวหรือไม่
    if (hire.review == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEnglish ? 'Review Details' : 'รายละเอียดรีวิว',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          child: Text(
            isEnglish ? 'No review found for this job.' : 'ไม่พบรีวิวสำหรับงานนี้',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // ดึงข้อมูลรีวิวจาก hire object
    final review = hire.review!;
    final hirerName = hire.hirer?.person?.firstName != null &&
            hire.hirer?.person?.lastName != null
        ? '${hire.hirer!.person!.firstName!} ${hire.hirer!.person!.lastName!}'
        : (isEnglish ? 'Unknown Hirer' : 'ผู้ว่าจ้างไม่ระบุ');

    final profileImageUrl = hire.hirer?.person?.pictureUrl ??
        'https://via.placeholder.com/50/CCCCCC/FFFFFF?Text=User'; // Fallback for profile image

    final jobDate = hire.startDate != null
        ? DateFormat(isEnglish ? 'd MMM y' : 'd MMM y', isEnglish ? 'en_US' : 'th_TH')
            .format(hire.startDate!)
        : (isEnglish ? 'N/A Date' : 'ไม่มีวันที่');
    final jobTime = '${hire.startTime ?? ''} - ${hire.endTime ?? ''}';
    final serviceDescription = hire.hireDetail ?? (isEnglish ? 'No description' : 'ไม่มีรายละเอียด');

    // คำนวณ 'timeAgo' (ตัวอย่าง)
    String timeAgoText = '';
    if (review.reviewDate != null) {
      final duration = DateTime.now().difference(review.reviewDate!);
      if (duration.inDays > 30) {
        timeAgoText = isEnglish ? '${duration.inDays ~/ 30} months ago' : '${duration.inDays ~/ 30} เดือนที่แล้ว';
      } else if (duration.inDays > 0) {
        timeAgoText = isEnglish ? '${duration.inDays} days ago' : '${duration.inDays} วันที่แล้ว';
      } else if (duration.inHours > 0) {
        timeAgoText = isEnglish ? '${duration.inHours} hours ago' : '${duration.inHours} ชั่วโมงที่แล้ว';
      } else if (duration.inMinutes > 0) {
        timeAgoText = isEnglish ? '${duration.inMinutes} minutes ago' : '${duration.inMinutes} นาทีที่แล้ว';
      } else {
        timeAgoText = isEnglish ? 'Just now' : 'เมื่อสักครู่';
      }
    }


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Pop the current screen
          },
        ),
        title: Text(
          isEnglish ? 'Review Details' : 'รายละเอียดรีวิว',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black), // เปลี่ยน icon เป็น share แทน upload
            onPressed: () {
              // Handle share action
              print('Share button pressed');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEnglish ? 'Share review clicked' : 'คลิกแชร์รีวิว')),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ReviewCard(
              // ส่งข้อมูลจริงจาก hire object
              imageUrl: profileImageUrl,
              name: hirerName,
              rating: (review.score ?? 0).toInt(),
              date: jobDate,
              time: jobTime,
              serviceDescription: serviceDescription,
              reviewText: review.reviewMessage ?? (isEnglish ? 'No comment provided.' : 'ไม่มีความคิดเห็น'),
              timeAgo: timeAgoText,
              isEnglish: isEnglish,
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int rating;
  final String date;
  final String time;
  final String serviceDescription;
  final String reviewText;
  final String timeAgo;
  final bool isEnglish; // เพิ่ม isEnglish

  const ReviewCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.rating,
    required this.date,
    required this.time,
    required this.serviceDescription,
    required this.reviewText,
    required this.timeAgo,
    required this.isEnglish, 
  });

  @override
  Widget build(BuildContext context) {
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
              children: [
                CircleAvatar(
                  radius: 30,
                  // ใช้ NetworkImage ถ้าเป็น URL หรือ AssetImage ถ้าเป็น asset
                  backgroundImage: imageUrl.startsWith('http')
                      ? NetworkImage(imageUrl) as ImageProvider
                      : AssetImage(imageUrl) as ImageProvider,
                  backgroundColor: Colors.grey[200],
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading review image: $exception');
                    // Fallback to a default asset if network image fails
                    (context as Element).markNeedsBuild(); // Rebuild to apply fallback
                  },
                ),
                const SizedBox(width: 15),
                Column(
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
                    _buildStarRating(rating),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              '${isEnglish ? 'Job Date' : 'วันที่จ้างงาน'}: $date', // เพิ่ม Label
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isEnglish ? 'Job Time' : 'เวลาจ้างงาน'}: $time', // เพิ่ม Label
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isEnglish ? 'Service' : 'บริการ'}: $serviceDescription', // เพิ่ม Label
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              reviewText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}