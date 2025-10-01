import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/screens/finishjob_member.dart';
import 'package:maebanjumpen/screens/report_member.dart';
import 'package:maebanjumpen/screens/reviewhousekeeper_member.dart';

class JobCard extends StatelessWidget {
  final String serviceName;
  final String name;
  final String date;
  final String time;
  final String address;
  final String status;
  final String price;
  final String? imageUrl;
  final String details;
  final Color statusColor;
  final bool showVerifyButton;
  final bool showReportButton;
  final bool showReviewButton;
  final bool showViewReviewButton;
  final bool showCancelButton;
  final bool isEnglish;
  final VoidCallback? onTap;

  final Hire hire;
  final Person? userPerson;
  final Hirer? hirerUser;

  final VoidCallback? onVerifyPressed;
  final VoidCallback? onReportPressed;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onViewReviewPressed;

  const JobCard({
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
    this.showVerifyButton = false,
    this.showReportButton = false,
    this.showReviewButton = false,
    this.showViewReviewButton = false,
    this.showCancelButton = false,
    required this.isEnglish,
    this.onTap,
    required this.hire,
    this.userPerson,
    this.hirerUser,
    this.onVerifyPressed,
    this.onReportPressed,
    this.onReviewPressed,
    this.onCancelPressed,
    this.onViewReviewPressed,
    required this.serviceName,
  });

  ImageProvider _getProfileImage(String? url) {
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/profile.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        if (serviceName.isNotEmpty)
                          Text(
                            isEnglish
                                ? "Service Name: $serviceName"
                                : "ชื่อบริการ: $serviceName",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (details.isNotEmpty)
                          Text(
                            isEnglish
                                ? "Details: $details"
                                : "รายละเอียด: $details",

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
              if (showVerifyButton ||
                  showReportButton ||
                  showReviewButton ||
                  showViewReviewButton ||
                  showCancelButton)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showVerifyButton)
                        ElevatedButton(
                          onPressed: () async {
                            if (hirerUser == null) {
                              debugPrint(
                                'Error: hirerUser is null for VerifyJobPage',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEnglish
                                        ? 'User data missing.'
                                        : 'ข้อมูลผู้ใช้ไม่สมบูรณ์',
                                  ),
                                ),
                              );
                              return;
                            }
                            final updatedHire = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VerifyJobPage(
                                      hire: hire,
                                      isEnglish: isEnglish,
                                      user: hirerUser!,
                                    ),
                              ),
                            );

                            if (updatedHire != null && updatedHire is Hire) {
                              debugPrint(
                                'Hire job status updated to: ${updatedHire.jobStatus}',
                              );
                              onVerifyPressed?.call();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'Verify Job' : 'ยืนยันงาน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (showVerifyButton &&
                          (showReportButton ||
                              showReviewButton ||
                              showViewReviewButton ||
                              showCancelButton))
                        const SizedBox(width: 8),

                      if (showReportButton)
                        ElevatedButton(
                          onPressed: () {
                            if (hirerUser == null) {
                              debugPrint(
                                'Error: hirerUser is null for ReportPage',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEnglish
                                        ? 'User data missing for report.'
                                        : 'ข้อมูลผู้ใช้ไม่สมบูรณ์สำหรับการรายงาน',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ReportHousekeeperPage(
                                      hire: hire,
                                      isEnglish: isEnglish,
                                      hirerUser: hirerUser!,
                                    ),
                              ),
                            );
                            onReportPressed?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'Report' : 'รายงาน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (showReportButton &&
                          (showReviewButton ||
                              showViewReviewButton ||
                              showCancelButton))
                        const SizedBox(width: 8),

                      if (showReviewButton)
                        ElevatedButton(
                          onPressed: () {
                            if (hirerUser == null) {
                              debugPrint(
                                'Error: hirerUser is null for ReviewHousekeeperPage',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEnglish
                                        ? 'User data missing.'
                                        : 'ข้อมูลผู้ใช้ไม่สมบูรณ์',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ReviewHousekeeperPage(
                                      hire: hire,
                                      isEnglish: isEnglish,
                                      user: hirerUser!,
                                    ),
                              ),
                            );
                            onReviewPressed?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'Review' : 'รีวิว',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (showReviewButton &&
                          (showViewReviewButton || showCancelButton))
                        const SizedBox(width: 8),

                      // New: View Review Button
                      if (showViewReviewButton)
                        ElevatedButton(
                          onPressed: onViewReviewPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'View Review' : 'ดูรีวิว',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (showViewReviewButton && showCancelButton)
                        const SizedBox(width: 8),

                      if (showCancelButton)
                        ElevatedButton(
                          onPressed: () {
                            onCancelPressed?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'Cancel Job' : 'ยกเลิกงาน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
