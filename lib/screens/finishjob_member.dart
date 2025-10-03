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
import 'package:maebanjumpen/styles/finishJobStyles.dart';
import 'package:maebanjumpen/widgets/verifyJob_member_dialog.dart';

// 假设ว่า AppLocalizations, AppColors, AppTextStyles, AppSpacings ถูกกำหนดไว้ในไฟล์อื่น
// เนื่องจากไม่ได้ให้โค้ดของไฟล์เหล่านั้นมา จึงสันนิษฐานว่าโค้ดที่เกี่ยวข้องกับการแปลภาษา สไตล์ และระยะห่างใช้งานได้
// class AppLocalizations...
// class AppColors...
// class AppTextStyles...
// class AppSpacings...

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
  int _currentIndex =
      2; // ตั้งค่าเริ่มต้นให้เป็น Index ของ 'การจ้าง' (Bookings)
  final Hirecontroller _hireController = Hirecontroller();

  // แก้ไข: เปลี่ยนจาก final Hire _currentHire;
  late Hire _currentHire; // เก็บเป็น late และกำหนดค่าใน initState

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นให้ _currentHire เป็น widget.hire ที่รับเข้ามาทันที
    _currentHire = widget.hire;
    // จากนั้นค่อยโหลดข้อมูลล่าสุดจาก API
    _fetchJobDetails();
  }

  // Helper function to calculate duration
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

      if (startTime != null && startTime.isNotEmpty) {
        for (final formatter in formatters) {
          try {
            startDateTime = formatter.parse(startTime);
            break;
          } catch (_) {}
        }
      }

      if (endTime != null && endTime.isNotEmpty) {
        for (final formatter in formatters) {
          try {
            endDateTime = formatter.parse(endTime);
            break;
          } catch (_) {}
        }
      }

      if (startDateTime == null || endDateTime == null) {
        debugPrint(
          'Error: Could not parse one or both time strings. Start: "$startTime", End: "$endTime".',
        );
        return 0.0;
      }

      if (endDateTime.isBefore(startDateTime)) {
        return endDateTime
                .add(const Duration(days: 1))
                .difference(startDateTime)
                .inMinutes /
            60.0;
      }

      return endDateTime.difference(startDateTime).inMinutes / 60.0;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred during time duration calculation: $e',
      );
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
            if (_currentHire.hireId == null) {
              debugPrint(
                "Error: Cannot update job status because hireId is null.",
              );
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
              hireId: _currentHire.hireId,
              hireName: _currentHire.hireName,
              hireDetail: _currentHire.hireDetail,
              paymentAmount: _currentHire.paymentAmount,
              hireDate: _currentHire.hireDate,
              startDate: _currentHire.startDate,
              startTime: _currentHire.startTime,
              endTime: _currentHire.endTime,
              location: _currentHire.location,
              progressionImageUrls: _currentHire.progressionImageUrls,
              jobStatus: 'Completed',
              hirer:
                  _currentHire.hirer != null
                      ? Hirer(
                        id: _currentHire.hirer!.id,
                        type: _currentHire.hirer!.type,
                      )
                      : null,
              housekeeper:
                  _currentHire.housekeeper != null
                      ? Housekeeper(
                        id: _currentHire.housekeeper!.id,
                        type: _currentHire.housekeeper!.type,
                      )
                      : null,
              review: _currentHire.review,
            );

            final responseHire = await _hireController.updateHire(
              _currentHire.hireId!,
              updatedHireForServer,
            );
            
            // ใช้ canPop() เพื่อตรวจสอบและป้องกัน Error ก่อนปิด Dialog
            if (Navigator.of(alertButtonContext).canPop()) {
              Navigator.of(alertButtonContext).pop(); // ปิด Dialog
            }
            if (responseHire != null) {
              // 1. อัปเดตสำเร็จ
              // ปิดหน้าจอ VerifyJobPage
              Navigator.of(context).pop();
              // แสดง SnackBar แจ้งความสำเร็จ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.getJobStatusUpdatedSuccess()),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            } else {
              // 2. อัปเดตไม่สำเร็จ
              // ไม่ต้องเรียก pop() ของหน้าจอหลัก (context) เพราะยังอยู่หน้าเดิม
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
    return const AssetImage('assets/placeholder_housekeeper.png');
  }

  // Helper function to get the appropriate image provider for progression image
  ImageProvider _getProgressionImage(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage('assets/no_image_available.png');
  }

  // เพิ่มฟังก์ชันสำหรับโหลดข้อมูลงาน
  Future<void> _fetchJobDetails() async {
    try {
      if (widget.hire.hireId != null) {
        final updatedHire = await _hireController.getHireById(
          widget.hire.hireId!,
        );
        if (updatedHire != null) {
          // ใช้ mounted เพื่อตรวจสอบว่า widget ยังอยู่ใน widget tree หรือไม่ก่อนเรียก setState
          if (mounted) {
            setState(() {
              _currentHire = updatedHire;
              debugPrint('Job details reloaded successfully.');
              if (_currentHire.progressionImageUrls != null) {
                debugPrint(
                  'Progression Image URLs: ${_currentHire.progressionImageUrls}',
                );
              }
            });
          }
        } else {
          debugPrint('Failed to get updated job details from API.');
        }
      }
    } catch (e) {
      debugPrint('Error fetching job details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(widget.isEnglish);

    // *******************************************************************
    // ** แก้ไข Null Check Operator Error ที่อาจเกิดขึ้นที่นี่ **
    // *******************************************************************
    // ใช้ Null-aware access operator (?.) และ Null-aware coalescing operator (??)
    // เพื่อจัดการกับกรณีที่ housekeeper หรือ person เป็น null อย่างปลอดภัย
    final String housekeeperFirstName =
        _currentHire.housekeeper?.person?.firstName ?? '';
    final String housekeeperLastName =
        _currentHire.housekeeper?.person?.lastName ?? '';

    final String housekeeperName =
        (housekeeperFirstName.isNotEmpty || housekeeperLastName.isNotEmpty)
            ? '$housekeeperFirstName $housekeeperLastName'
            : localizations.getUnknownHousekeeper();
    // *******************************************************************

    final String? housekeeperImageUrl =
        _currentHire.housekeeper?.person?.pictureUrl;

    final String jobDate =
        (_currentHire.startDate != null)
            ? '${_currentHire.startDate!.day} ${localizations.getMonthName(_currentHire.startDate!.month)}, ${_currentHire.startDate!.year}'
            : '';

    final double calculatedHours = _calculateHoursDuration(
      _currentHire.startTime,
      _currentHire.endTime,
    );
    final String jobTimeAndHours =
        '${_currentHire.startTime ?? ''} - ${_currentHire.endTime ?? ''} (${localizations.getHoursText(calculatedHours)})';

    final bool isJobCompleted = _currentHire.jobStatus == 'Completed';

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
      body: RefreshIndicator(
        onRefresh: _fetchJobDetails,
        child: SingleChildScrollView(
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
                            _currentHire.location ??
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
                          '฿${_currentHire.paymentAmount?.toStringAsFixed(0) ?? '0'}',
                          style: AppTextStyles.price,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacings.medium),
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
                      localizations.getServiceIncludesTitle(),
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacings.small),
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
                                ? 'Service Name: ${_currentHire.hireName ?? 'N/A'}'
                                : 'ชื่องานบริการ: ${_currentHire.hireName ?? 'ไม่ระบุ'}',
                            style: AppTextStyles.jobDetails,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                                ? 'Details: ${_currentHire.hireDetail ?? 'N/A'}'
                                : 'รายละเอียด: ${_currentHire.hireDetail ?? 'ไม่ระบุ'}',
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
                      localizations.getWorkProgressPhotosTitle(),
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacings.small),
                    if (_currentHire.progressionImageUrls != null &&
                        _currentHire.progressionImageUrls!.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentHire.progressionImageUrls!.length,
                          itemBuilder: (context, index) {
                            final imageUrl =
                                _currentHire.progressionImageUrls![index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacings.borderRadius,
                                ),
                                child: Image(
                                  image: _getProgressionImage(imageUrl),
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'Error loading progress image from URL: $imageUrl. Error: $error',
                                    );
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: AppColors.lightGreyBackground,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.broken_image,
                                              color: AppColors.greyText,
                                              size: 50,
                                            ),
                                            Text(
                                              widget.isEnglish
                                                  ? 'Image failed to load'
                                                  : 'ไม่สามารถโหลดรูปภาพได้',
                                              style: AppTextStyles.jobDetails
                                                  .copyWith(
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
                            );
                          },
                        ),
                      )
                    else
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
                  onPressed:
                      isJobCompleted
                          ? null
                          : () => _showConfirmFinishJobAlert(
                            context,
                            localizations,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isJobCompleted
                            ? AppColors.greyText
                            : AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacings.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacings.buttonBorderRadius,
                      ),
                    ),
                    foregroundColor: Colors.white,
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ... (โค้ด bottomNavigationBar เหมือนเดิม)
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.greyText,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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
                builder:
                    (context) => HomePage(
                      isEnglish: widget.isEnglish,
                      user: widget.user!,
                    ),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DepositMemberPage(
                      user: widget.user!,
                      isEnglish: widget.isEnglish,
                    ),
              ),
            );
          } else if (index == 2) {
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProfileMemberPage(
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
