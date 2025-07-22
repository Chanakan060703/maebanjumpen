import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart'; // สำคัญมาก: ต้อง Import ไฟล์ Styles/Localizations
import 'package:maebanjumpen/widgets/verifyJob_member_dialog.dart'; // สำคัญมาก: ต้อง Import Dialog

class VerifyJobPage extends StatefulWidget {
  final bool isEnglish;
  final Hire hire;
  final Hirer? user;

  const VerifyJobPage({
    super.key,
    required this.isEnglish,
    required this.hire,
    this.user,
  });

  @override
  State<VerifyJobPage> createState() => _VerifyJobPageState();
}

class _VerifyJobPageState extends State<VerifyJobPage> {
  int _currentIndex = 2; // ตั้งค่าเริ่มต้นให้เป็น Index ของ 'การจ้าง' (Bookings)

  final Hirecontroller _hireController = Hirecontroller();

  // Helper function to calculate duration
  // เปลี่ยน parameter เป็น String? เพื่อจัดการ null อย่างปลอดภัยก่อน parse
  double _calculateHoursDuration(String? startTime, String? endTime) {
    try {
      final List<DateFormat> formatters = [
        DateFormat('hh:mm a', 'en_US'),
        DateFormat('HH:mm'),
        DateFormat('h:mm a', 'en_US'),
        DateFormat('H:mm'),
      ];

      DateTime? startDateTime;
      DateTime? endDateTime;

      // ตรวจสอบ null ก่อนพยายาม parse
      if (startTime != null && startTime.isNotEmpty) {
        for (final formatter in formatters) {
          try {
            startDateTime = formatter.parse(startTime);
            break;
          } catch (_) {
            // Continue to try other formats
          }
        }
      }

      if (endTime != null && endTime.isNotEmpty) {
        for (final formatter in formatters) {
          try {
            endDateTime = formatter.parse(endTime);
            break;
          } catch (_) {
            // Continue to try other formats
          }
        }
      }

      if (startDateTime == null || endDateTime == null) {
        debugPrint(
            'Error: Could not parse one or both time strings. Start: "$startTime", End: "$endTime".');
        return 0.0;
      }

      // Handle case where end time is on the next day
      if (endDateTime.isBefore(startDateTime)) {
        return endDateTime
                .add(const Duration(days: 1))
                .difference(startDateTime)
                .inMinutes /
            60.0;
      }

      return endDateTime.difference(startDateTime).inMinutes / 60.0;
    } catch (e) {
      debugPrint('An unexpected error occurred during time duration calculation: $e');
      return 0.0;
    }
  }

  // Function to show confirmation dialog
  void _showConfirmFinishJobAlert(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ConfirmFinishJobAlert(
          localizations: localizations,
          onConfirm: (alertButtonContext) async {
            if (widget.hire.hireId == null) {
              debugPrint(
                  "Error: Cannot update job status because hireId is null.");
              Navigator.of(alertButtonContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${localizations.getJobStatusUpdateFailed()} (${localizations.getTryAgainLater()})',
                  ),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
              return;
            }

            final updatedHireForServer = Hire(
              hireId: widget.hire.hireId,
              hireName: widget.hire.hireName,
              hireDetail: widget.hire.hireDetail,
              paymentAmount: widget.hire.paymentAmount,
              hireDate: widget.hire.hireDate,
              startDate: widget.hire.startDate,
              startTime: widget.hire.startTime,
              endTime: widget.hire.endTime,
              location: widget.hire.location,
              // Keep progressionImageUrl as is, as it's already set by housekeeper
              progressionImageUrl: widget.hire.progressionImageUrl,
              jobStatus: 'Completed', // Set status to Completed
              hirer: widget.hire.hirer != null
                  ? Hirer(
                      id: widget.hire.hirer!.id,
                      type: widget.hire.hirer!.type,
                    )
                  : null,
              housekeeper: widget.hire.housekeeper != null
                  ? Housekeeper(
                      id: widget.hire.housekeeper!.id,
                      type: widget.hire.housekeeper!.type,
                    )
                  : null,
              review: widget.hire.review, // May not have review yet
            );

            final responseHire = await _hireController.updateHire(
              widget.hire.hireId!,
              updatedHireForServer,
            );

            // บล็อกโค้ดจัดการผลลัพธ์ ถูกรวมให้เหลือแค่บล็อกเดียว
            if (responseHire != null) {
              // สำเร็จ
              Navigator.of(alertButtonContext).pop(); // Pop the dialog
              Navigator.of(context).pop(); // Pop current VerifyJobPage
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.getJobStatusUpdatedSuccess()),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
              // คุณอาจจะส่งค่ากลับไปหน้า HireListPage เพื่อให้รีเฟรชข้อมูล
              // หรือใช้ package state management เช่น provider/bloc เพื่ออัปเดตสถานะ
              // เช่น: Navigator.of(context).pop(true);
            } else {
              // ล้มเหลว (อาจเป็นเพราะเงินไม่พอ, ไม่พบผู้จ้าง/แม่บ้าน ฯลฯ)
              Navigator.of(alertButtonContext).pop(); // Pop the dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${localizations.getJobStatusUpdateFailed()} ${localizations.getTryAgainLater()}',
                  ),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            }
          },
        );
      },
    );
  }

  // Helper function to get the appropriate image provider for housekeeper profile
  ImageProvider _getHousekeeperProfileImage(String? pictureUrl) {
    if (pictureUrl != null &&
        pictureUrl.isNotEmpty &&
        (pictureUrl.startsWith('http://') ||
            pictureUrl.startsWith('https://'))) {
      return NetworkImage(pictureUrl);
    }
    // Fallback to local asset if URL is invalid or empty
    return const AssetImage(
      'assets/placeholder_housekeeper.png',
    ); // Ensure this asset exists and is declared in pubspec.yaml
  }

  // Helper function to get the appropriate image provider for progression image
  ImageProvider _getProgressionImage(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return NetworkImage(imageUrl);
    }
    // Fallback to a placeholder for progression images if URL is invalid or empty
    return const AssetImage(
      'assets/no_image_available.png',
    ); // You might want a specific placeholder for "no progress image"
  }

  @override
  void initState() {
    super.initState();
    debugPrint('VerifyJobPage: User object received is: ${widget.user}');
    if (widget.user?.person != null) {
      debugPrint(
          'VerifyJobPage: User Name: ${widget.user!.person!.firstName} ${widget.user!.person!.lastName}');
    } else {
      debugPrint('VerifyJobPage: User object or User Person is NULL.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(widget.isEnglish);

    final String housekeeperName =
        (widget.hire.housekeeper?.person?.firstName != null &&
                widget.hire.housekeeper?.person?.lastName != null)
            ? '${widget.hire.housekeeper!.person!.firstName} ${widget.hire.housekeeper!.person!.lastName}'
            : localizations.getUnknownHousekeeper();

    final String? housekeeperImageUrl =
        widget.hire.housekeeper?.person?.pictureUrl;

    final String jobDate = (widget.hire.startDate != null)
        ? '${widget.hire.startDate!.day} ${localizations.getMonthName(widget.hire.startDate!.month)}, ${widget.hire.startDate!.year}'
        : '';

    // ส่งค่า String? ให้ _calculateHoursDuration โดยใช้ ?? '' เพื่อป้องกัน null
    final double calculatedHours = _calculateHoursDuration(
      widget.hire.startTime, // ไม่ต้อง cast เป็น String แล้ว
      widget.hire.endTime, // ไม่ต้อง cast เป็น String แล้ว
    );
    final String jobTimeAndHours =
        '${widget.hire.startTime ?? ''} - ${widget.hire.endTime ?? ''} (${localizations.getHoursText(calculatedHours)})';

    final bool isJobCompleted = widget.hire.jobStatus == 'Completed';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          localizations.getAppBarTitle(),
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacings.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: AppSpacings.avatarRadius,
                  backgroundImage: _getHousekeeperProfileImage(
                    housekeeperImageUrl,
                  ),
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint(
                      'Error displaying housekeeper image: $exception',
                    );
                  },
                ),
                const SizedBox(width: AppSpacings.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        housekeeperName,
                        style: AppTextStyles.housekeeperName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(jobDate, style: AppTextStyles.jobDetails),
                      Text(jobTimeAndHours, style: AppTextStyles.jobDetails),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacings.medium),
            // Service Details Card
            Container(
              padding: const EdgeInsets.all(AppSpacings.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  AppSpacings.buttonBorderRadius,
                ),
                border: Border.all(color: AppColors.lightGreyBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.getServiceDetailsTitle(),
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacings.small),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.greyText,
                      ),
                      const SizedBox(width: AppSpacings.small),
                      Expanded(
                        child: Text(
                          widget.hire.location ??
                              (widget.isEnglish ? 'N/A' : 'ไม่ระบุ'),
                          style: AppTextStyles.jobDetails,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacings.small),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.greyText,
                      ),
                      const SizedBox(width: AppSpacings.small),
                      Text(
                        localizations.getHoursText(calculatedHours),
                        style: AppTextStyles.jobDetails,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacings.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '฿${widget.hire.paymentAmount?.toStringAsFixed(0) ?? '0'}', // Changed to 0 decimal places as per previous context
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacings.medium),
            // Service Includes Card (now showing hireName and hireDetail)
            Container(
              padding: const EdgeInsets.all(AppSpacings.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  AppSpacings.buttonBorderRadius,
                ),
                border: Border.all(color: AppColors.lightGreyBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations
                        .getServiceIncludesTitle(), // "Service Includes"
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacings.small),
                  // Display hireName
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isEnglish
                              ? 'Service Name: ${widget.hire.hireName ?? 'N/A'}'
                              : 'ชื่องานบริการ: ${widget.hire.hireName ?? 'ไม่ระบุ'}',
                          style: AppTextStyles.jobDetails,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 4), // Small spacing between name and detail
                  // Display hireDetail
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isEnglish
                              ? 'Details: ${widget.hire.hireDetail ?? 'N/A'}'
                              : 'รายละเอียด: ${widget.hire.hireDetail ?? 'ไม่ระบุ'}',
                          style: AppTextStyles.jobDetails,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacings.large),

            // Work Progress Photos Section
            if (widget.hire.progressionImageUrl != null &&
                widget.hire.progressionImageUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacings.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppSpacings.buttonBorderRadius,
                  ),
                  border: Border.all(color: AppColors.lightGreyBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations
                          .getWorkProgressPhotosTitle(), // "Work Progress Photos"
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacings.small),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacings.borderRadius,
                      ),
                      child: Image(
                        image: _getProgressionImage(
                          widget.hire.progressionImageUrl,
                        ),
                        width: double.infinity,
                        height: 200, // Fixed height for consistency
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading progress image: $error');
                          return Container(
                            height: 200,
                            color: AppColors.lightGreyBackground,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: AppColors.greyText,
                                    size: 50,
                                  ),
                                  Text(
                                    widget.isEnglish
                                        ? 'Image failed to load'
                                        : 'ไม่สามารถโหลดรูปภาพได้',
                                    style: AppTextStyles.jobDetails.copyWith(
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                // Display a message if no progression image
                padding: const EdgeInsets.all(AppSpacings.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppSpacings.buttonBorderRadius,
                  ),
                  border: Border.all(color: AppColors.lightGreyBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.getWorkProgressPhotosTitle(),
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacings.small),
                    Text(
                      widget.isEnglish
                          ? 'No work progress photos uploaded.'
                          : 'ยังไม่มีรูปภาพความคืบหน้าของงาน',
                      style: AppTextStyles.jobDetails.copyWith(
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacings.large),

            // Confirm Finish Job Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJobCompleted
                    ? null // Disable button if job is completed
                    : () => _showConfirmFinishJobAlert(context, localizations),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJobCompleted
                      ? AppColors.greyText
                      : AppColors.primaryGreen, // Grey out if completed
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacings.medium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacings.buttonBorderRadius,
                    ),
                  ),
                  foregroundColor:
                      Colors.white, // Text color is always white for readability
                ),
                child: Text(
                  isJobCompleted
                      ? localizations.getJobCompletedButton()
                      : localizations.getConfirmFinishJobButton(),
                  style: AppTextStyles.buttonTextWhite,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.greyText,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update currentIndex when tapped
          });

          if (index != 2 && widget.user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.getPleaseLoginMessage()),
                backgroundColor: AppColors.primaryRed,
              ),
            );
            return;
          }

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  isEnglish: widget.isEnglish,
                  user: widget.user!,
                ),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CardpageMember(
                  user: widget.user!,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 2) {
            // Do nothing, already on this page (Bookings) or navigate to HireListPage
            // Given the context of this page, if it's accessed from a list,
            // going back to the list might be more appropriate than doing nothing.
            // For simplicity, staying on this page if already here.
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileMemberPage(
                  user: widget.user!,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: localizations.getHomeLabel(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card_outlined),
            label: localizations.getCardsLabel(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: localizations.getBookingsLabel(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: localizations.getProfileLabel(),
          ),
        ],
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final String text;
  final bool
      isEnglish; // isEnglish is not directly used here but kept for consistency

  const ServiceItem({super.key, required this.text, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink(); // Don't show if text is empty

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.jobDetails)),
        ],
      ),
    );
  }
}