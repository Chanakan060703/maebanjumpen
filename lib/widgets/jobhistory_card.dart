import 'package:flutter/material.dart';
// ไม่จำเป็นต้อง import model/hire.dart, hirer.dart, person.dart ใน widget นี้
// เพราะข้อมูลถูกส่งมาเป็น String/Color แล้ว

class JobCardHistory extends StatelessWidget {
  final String name;
  final String date;
  final String time;
  final String address;
  final String status;
  final String price;
  final String? imageUrl;
  final String details;
  final Color statusColor;
  final bool isEnglish;
  final bool showReportButton; // เพิ่มพารามิเตอร์
  final bool showViewReviewButton; // เพิ่มพารามิเตอร์

  // Callbacks สำหรับปุ่มต่างๆ
  final VoidCallback? onReportPressed;
  final VoidCallback? onViewReviewPressed;

  const JobCardHistory({
    super.key,
    required this.name,
    required this.date,
    required this.time,
    required this.address,
    required this.status,
    required this.price,
    this.imageUrl,
    required this.details,
    required this.statusColor,
    required this.isEnglish,
    this.showReportButton = false, // กำหนดค่าเริ่มต้นเป็น false
    this.showViewReviewButton = false, // กำหนดค่าเริ่มต้นเป็น false
    this.onReportPressed,
    this.onViewReviewPressed,
  });

  // Helper function เพื่อดึง ImageProvider ที่ถูกต้อง
  ImageProvider _getProfileImage(String? url) {
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/profile.jpg'); // ตรวจสอบว่ามีไฟล์นี้ใน assets/ ของคุณ
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _getProfileImage(imageUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading image for $name: $exception');
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // ปุ่มต่างๆ จะแสดงเมื่อ showReportButton หรือ showViewReviewButton เป็น true
            if (showReportButton || showViewReviewButton)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showReportButton) // แสดงปุ่ม Report เมื่อ showReportButton เป็น true
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onReportPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                          child: Text(
                            isEnglish ? 'Report' : 'รายงาน',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    if (showReportButton && showViewReviewButton) // เพิ่มระยะห่างเมื่อมีทั้งสองปุ่ม
                      const SizedBox(width: 8),
                    if (showViewReviewButton) // แสดงปุ่ม View Review เมื่อ showViewReviewButton เป็น true
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onViewReviewPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                          child: Text(
                            isEnglish ? 'View Review' : 'ดูรีวิว',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}