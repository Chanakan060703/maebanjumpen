import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart';
import 'package:maebanjumpen/styles/hire_form_styles.dart';
import 'package:maebanjumpen/widgets/hire_dropdown_form_field.dart';

class HireHousekeeperPage extends StatefulWidget {
  final Hirer user;
  final Housekeeper housekeeper;
  final bool isEnglish;

  const HireHousekeeperPage({
    super.key,
    required this.user,
    required this.housekeeper,
    required this.isEnglish,
  });

  @override
  State<HireHousekeeperPage> createState() => HireHousekeeperPageState();
}

class HireHousekeeperPageState extends State<HireHousekeeperPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedHireName;
  late Map<HousekeeperSkill, bool> _selectedAdditionalServices;
  double _totalPaymentAmount = 0.0;

  final TextEditingController _startDateController = TextEditingController();
  final FocusNode _startDateFocusNode = FocusNode();
  final TextEditingController _startTimeController = TextEditingController();
  final FocusNode _startTimeFocusNode = FocusNode();

  final TextEditingController _detailWorkController = TextEditingController();
  final FocusNode _detailWorkFocusNode = FocusNode();

  bool _isDefaultAddress = true;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final TextEditingController _houseNumberController = TextEditingController();
  final FocusNode _houseNumberFocusNode = FocusNode();
  final TextEditingController _villageController = TextEditingController();
  final FocusNode _villageFocusNode = FocusNode();
  final TextEditingController _subdistrictController = TextEditingController();
  final FocusNode _subdistrictFocusNode = FocusNode();
  final TextEditingController _districtController = TextEditingController();
  final FocusNode _districtFocusNode = FocusNode();
  final TextEditingController _provinceController = TextEditingController();
  final FocusNode _provinceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (_isDefaultAddress) {
      _fillDefaultAddress();
    }
  }

  void _initializeServices() {
    final firstSkill = widget.housekeeper.housekeeperSkills?.firstOrNull;
    _selectedHireName = firstSkill?.skillType?.skillTypeName;

    _selectedAdditionalServices = {};
    if (widget.housekeeper.housekeeperSkills != null) {
      for (var skill in widget.housekeeper.housekeeperSkills!) {
        final isMainService =
            skill.skillType?.skillTypeName == _selectedHireName;
        _selectedAdditionalServices[skill] = isMainService;
      }
    }
    _calculateTotalPayment();
  }

  void _onSkillChanged(bool? value, HousekeeperSkill skill) {
    if (skill.skillType?.skillTypeName == _selectedHireName && value == false) {
      return;
    }
    setState(() {
      _selectedAdditionalServices[skill] = value ?? false;
      _calculateTotalPayment();
    });
  }

  void _calculateTotalPayment() {
    double total = 0.0;
    _selectedAdditionalServices.forEach((skill, isSelected) {
      if (isSelected) {
        total += skill.pricePerDay ?? 0.0;
      }
    });
    setState(() {
      _totalPaymentAmount = total;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary:
                  AppColors
                      .primaryRed, // สีแดงหลักสำหรับวันที่เลือกและหัวปฏิทิน
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    AppColors.primaryRed, // สีแดงหลักสำหรับปุ่มยกเลิก/ตกลง
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // ✅ แก้ไข: ใช้รูปแบบ 'dd-MM-yyyy' ให้ตรงกับที่คุณระบุ
        _startDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
    _startDateFocusNode.unfocus();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              // Primary ควบคุมสีเข็มนาฬิกา และสีวงกลมนาฬิกา
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryRed, // สีปุ่มยกเลิก/ตกลง
              ),
            ),
            // ✅ แก้ไข: ใช้ TimePickerThemeData
            timePickerTheme: TimePickerThemeData(
              // 1. ควบคุมสีพื้นหลังของชั่วโมง/นาทีด้านบน (hour/minute segments)
              hourMinuteColor: MaterialStateColor.resolveWith(
                (Set<MaterialState> states) =>
                    states.contains(MaterialState.selected)
                        ? AppColors.primaryRed.withOpacity(
                          0.12,
                        ) // สีพื้นหลังเมื่อถูกเลือก (อ่อนๆ)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(
                          0.12,
                        ), // สีพื้นหลังเมื่อไม่ได้เลือก
              ),

              // 2. ควบคุมสีตัวอักษรของชั่วโมง/นาทีด้านบน (hour/minute text)
              hourMinuteTextColor: MaterialStateColor.resolveWith(
                (Set<MaterialState> states) =>
                    states.contains(MaterialState.selected)
                        ? AppColors
                            .primaryRed // สีตัวอักษรเมื่อถูกเลือก (สีแดงหลัก)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface, // สีตัวอักษรเมื่อไม่ได้เลือก (สีดำ/เทา)
              ),

              // 3. ควบคุมสีตัวเลขคั่นกลาง (:)
              timeSelectorSeparatorColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) => AppColors.primaryRed,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTimeController.text = picked.format(context);
      });
    }
    _startTimeFocusNode.unfocus();
  }


  void _fillDefaultAddress() {
    final address = widget.user.person?.address ?? '';
    final parts = address.split(' ').map((p) => p.trim()).toList();

    _phoneController.text = widget.user.person?.phoneNumber ?? '';

    _houseNumberController.text = parts.length > 0 ? parts[0] : '';
    _villageController.text = parts.length > 1 ? parts[1] : '';
    _subdistrictController.text = parts.length > 2 ? parts[2] : '';
    _districtController.text = parts.length > 3 ? parts[3] : '';
    _provinceController.text = parts.length > 4 ? parts[4] : '';
  }

  String _getAddressString() {
    return [
      _houseNumberController.text,
      _villageController.text,
      _subdistrictController.text,
      _districtController.text,
      _provinceController.text,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  String _getFormattedAdditionalServices() {
    final selectedSkills =
        _selectedAdditionalServices.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

    if (selectedSkills.isEmpty) return '';

    final serviceNames =
        selectedSkills
            .map((skill) {
              return widget.isEnglish
                  ? skill.skillType?.skillTypeDetail ??
                      skill.skillType?.skillTypeName
                  : skill.skillType?.skillTypeName;
            })
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toList();

    final header =
        widget.isEnglish
            ? '--- Additional Services ---\n'
            : '--- รายการบริการเสริม ---\n';

    return header + serviceNames.map((name) => '• $name').join('\n');
  }

  Future<void> _createHire(Hire hire) async {
    final result = await Hirecontroller().addHire(hire);

    if (!mounted) return;

    if (result != null) {
      // ✅ SUCCESS: API คืนค่า Hire Object กลับมา (201 Created)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Hire created successfully!'
                : 'สร้างรายการจ้างงานสำเร็จ!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // นำทางไปยังหน้าถัดไป (หน้า Hire List)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HireListPage(user: widget.user, isEnglish: widget.isEnglish),
        ),
      );
    } else {
      // ❌ FAILURE: API คืนค่า null (เช่น 400 Bad Request หรือ 500 Internal Server Error)

      // Note: เนื่องจากเราไม่ได้ส่งข้อความ Error จาก Back-end มาตรงๆ (เป็นแค่ null)
      // เราจะแจ้ง Error ทั่วไป แต่ข้อความ Error จริงจะอยู่ใน Log ของ Java
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Failed to create hire. Check server logs.'
                : 'สร้างรายการจ้างงานไม่สำเร็จ! กรุณาตรวจสอบ Log บนเซิร์ฟเวอร์',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    if (_formKey.currentState!.validate()) {
      final servicesString = _getFormattedAdditionalServices();
      final existingDetail = _detailWorkController.text.trim();
      final String finalHireDetail =
          existingDetail.isEmpty
              ? servicesString
              : '$existingDetail\n\n$servicesString';
      final selectedMainSkill = widget.housekeeper.housekeeperSkills
          ?.firstWhere(
            (s) => s.skillType?.skillTypeName == _selectedHireName,
            orElse: () => HousekeeperSkill(),
          );

      // 1. จัดการวันที่ (startDate)
      DateTime? hireStartDate;
      String startDateText = _startDateController.text.trim();
      if (startDateText.isNotEmpty) {
        try {
          // แปลง 'dd-MM-yyyy' ให้เป็น DateTime
          hireStartDate = DateFormat('dd-MM-yyyy').parse(startDateText);
        } catch (e) {
          print('Error parsing startDate: $e');
          // จัดการ Error หรือ return
        }
      }

      // 2. 🏆 จุดที่แก้ไข: จัดการเวลา (startTime และ endTime) ให้เป็น HH:mm:ss
      String? finalStartTime;
      String? finalEndTime;

      DateTime? parsedStartTime;
      String startTimeText = _startTimeController.text.trim();

      if (startTimeText.isNotEmpty) {
        try {
          // ลอง Parse ด้วยรูปแบบ jm (12-hour เช่น 7:00 AM)
          parsedStartTime = DateFormat.jm().parse(startTimeText);
        } catch (e) {
          try {
            // ถ้าไม่ได้ ลอง Parse ด้วยรูปแบบ 24-hour (เช่น 20:35)
            parsedStartTime = DateFormat('HH:mm').parse(startTimeText);
          } catch (e) {
            parsedStartTime = null;
            print("Error parsing time: $e");
          }
        }

        if (parsedStartTime != null) {
          // 🎯 แก้ไข: จัดรูปแบบเวลาเริ่มต้นให้เป็น HH:mm:ss
          finalStartTime = DateFormat('HH:mm:ss').format(parsedStartTime);

          // คำนวณเวลาสิ้นสุด
          DateTime parsedEndTime = parsedStartTime.add(
            const Duration(hours: 1),
          );

          // 🎯 แก้ไข: จัดรูปแบบเวลาสิ้นสุดให้เป็น HH:mm:ss
          finalEndTime = DateFormat('HH:mm:ss').format(parsedEndTime);
        }
      }

      // 3. สร้าง Hire Object ด้วยค่าที่จัดรูปแบบแล้ว
      final newHire = Hire(
        hireName: _selectedHireName,
        hireDetail: finalHireDetail,
        paymentAmount: _totalPaymentAmount,
        startDate: hireStartDate,
        startTime: finalStartTime,
        endTime: finalEndTime,
        skillType: selectedMainSkill?.skillType,
        location: _getAddressString(),
        hirer: widget.user,
        housekeeper: widget.housekeeper,
        jobStatus: 'Pending',
        hireDate: DateTime.now(),
      );

      // แสดง Dialog ยืนยัน... (โค้ดส่วนนี้เหมือนเดิม)
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              widget.isEnglish ? 'Confirm Hire?' : 'ยืนยันการจ้างงาน?',
            ),
            content: Text(
              widget.isEnglish
                  ? 'Total amount: ${NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(_totalPaymentAmount)}'
                  : 'ยอดชำระรวม: ${NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(_totalPaymentAmount)}',
            ),
            actions: <Widget>[
              TextButton(
                // ✅ แก้ไข: ปุ่มยกเลิกใช้ AppColors.primaryRed
                child: Text(
                  widget.isEnglish ? 'Cancel' : 'ยกเลิก',
                  style: TextStyle(color: AppColors.primaryRed),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                // ✅ แก้ไข: ปุ่มยืนยันใช้ AppColors.primaryRed
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                ),
                child: Text(
                  widget.isEnglish ? 'Confirm' : 'ยืนยัน',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _createHire(newHire);
                },
              ),
            ],
          );
        },
      );
    }
  }

  // 6. Build Method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEnglish
              ? 'Hire Details and Address'
              : 'ข้อมูลการจ้างงานและที่อยู่',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------- SERVICE SELECTION SECTION -------------------
              _ServiceSelectionSection(
                housekeeperSkills: widget.housekeeper.housekeeperSkills,
                selectedHireName: _selectedHireName,
                selectedAdditionalServices: _selectedAdditionalServices,
                isEnglish: widget.isEnglish,
                onMainServiceChanged: (String? newValue) {
                  setState(() {
                    _selectedHireName = newValue;
                    _selectedAdditionalServices.updateAll(
                      (key, value) => false,
                    );

                    final mainSkill = widget.housekeeper.housekeeperSkills
                        ?.firstWhere(
                          (s) => s.skillType?.skillTypeName == newValue,
                          orElse: () => HousekeeperSkill(),
                        );
                    if (mainSkill?.skillType != null) {
                      if (mainSkill != null) {
                        _selectedAdditionalServices[mainSkill] = true;
                      }
                    }
                    _calculateTotalPayment();
                  });
                },
                onAdditionalServiceChanged: _onSkillChanged,
              ),
              const SizedBox(height: 16.0),

              // ------------------- PAYMENT SUMMARY -------------------
              _PaymentSummary(
                totalPaymentAmount: _totalPaymentAmount,
                isEnglish: widget.isEnglish,
              ),
              const SizedBox(height: 16.0),

              // ------------------- DATE & TIME SECTION -------------------
              _DateTimeSection(
                startDateController: _startDateController,
                startDateFocusNode: _startDateFocusNode,
                onTapDate: () => _selectDate(context),
                isEnglish: widget.isEnglish,
                startTimeController: _startTimeController,
                startTimeFocusNode: _startTimeFocusNode,
                onTapTime: () => _selectTime(context),
              ),
              const SizedBox(height: 16.0),

              // ------------------- WORK DETAILS -------------------
              HireTextFormField(
                controller: _detailWorkController,
                focusNode: _detailWorkFocusNode,
                labelText:
                    widget.isEnglish
                        ? 'Work Details (Optional)'
                        : 'รายละเอียดงานเพิ่มเติม (ไม่บังคับ)',
                hintText:
                    widget.isEnglish
                        ? 'e.g. special instructions location details (The services list will be automatically appended here)'
                        : 'เช่น รายการงานที่ต้องการ คำแนะนำพิเศษ (รายการบริการที่เลือกจะถูกเพิ่มอัตโนมัติด้านล่างนี้)',
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),

              // ------------------- ADDRESS SECTION -------------------
              _AddressSection(
                isDefaultAddress: _isDefaultAddress,
                onChanged: (bool? value) {
                  setState(() {
                    _isDefaultAddress = value!;
                    if (_isDefaultAddress) {
                      _fillDefaultAddress(); // ✅ เติมข้อมูลเมื่อเลือก Default
                    } else {
                      // ✅ ล้างข้อมูลเมื่อยกเลิก Default เพื่อให้ผู้ใช้กรอกใหม่
                      _phoneController.clear();
                      _provinceController.clear();
                      _subdistrictController.clear();
                      _districtController.clear();
                      _villageController.clear();
                      _houseNumberController.clear();
                    }
                  });
                },
                isEnglish: widget.isEnglish,
                phoneController: _phoneController,
                phoneFocusNode: _phoneFocusNode,
                houseNumberController: _houseNumberController,
                houseNumberFocusNode: _houseNumberFocusNode,
                villageController: _villageController,
                villageFocusNode: _villageFocusNode,
                subdistrictController: _subdistrictController,
                subdistrictFocusNode: _subdistrictFocusNode,
                districtController: _districtController,
                districtFocusNode: _districtFocusNode,
                provinceController: _provinceController,
                provinceFocusNode: _provinceFocusNode,
              ),
              const SizedBox(height: 24.0),

              // ------------------- CONFIRM BUTTON -------------------
              Center(
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                    shadowColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  child: Text(
                    widget.isEnglish ? 'Confirm' : 'ยืนยัน',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSelectionSection extends StatelessWidget {
  final List<HousekeeperSkill>? housekeeperSkills;
  final String? selectedHireName;
  final Map<HousekeeperSkill, bool> selectedAdditionalServices;
  final bool isEnglish;
  final ValueChanged<String?> onMainServiceChanged;
  final Function(bool?, HousekeeperSkill) onAdditionalServiceChanged;

  const _ServiceSelectionSection({
    required this.housekeeperSkills,
    required this.selectedHireName,
    required this.selectedAdditionalServices,
    required this.isEnglish,
    required this.onMainServiceChanged,
    required this.onAdditionalServiceChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HireDropdownFormField<String>(
          value: selectedHireName,
          labelText:
              isEnglish
                  ? 'Hire Name/Main Service'
                  : 'ชื่อการจ้างงาน/บริการหลัก',
          hintText: isEnglish ? 'Select main service' : 'เลือกบริการหลัก',
          items:
              housekeeperSkills?.map((skill) {
                return DropdownMenuItem<String>(
                  value: skill.skillType?.skillTypeName ?? "",
                  child: Text(
                    SkillTranslator.getLocalizedSkillName(
                      skill.skillType?.skillTypeName,
                      isEnglish,
                    ),
                  ),
                );
              }).toList() ??
              [],
          onChanged: onMainServiceChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isEnglish
                  ? 'Please select a main service.'
                  : 'กรุณาเลือกบริการหลัก';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        Text(
          isEnglish
              ? 'Additional Services (Optional)'
              : 'บริการเพิ่มเติม (เลือกได้หลายรายการ)',
          style: HireFormStyles.labelTextStyle(context),
        ),
        const SizedBox(height: 8.0),
        if (housekeeperSkills != null && housekeeperSkills!.isNotEmpty)
          ...housekeeperSkills!.map((skill) {
            final serviceName = skill.skillType?.skillTypeName ?? '';
            // ซ่อนบริการหลักออกจากรายการบริการเสริม
            if (serviceName == selectedHireName) {
              return const SizedBox.shrink();
            }
            return HireCheckboxListTile(
              title: SkillTranslator.getLocalizedSkillName(
                serviceName,
                isEnglish,
              ),
              value: selectedAdditionalServices[skill] ?? false,
              onChanged: (bool? value) {
                onAdditionalServiceChanged(value, skill);
              },
            );
          }).toList()
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              isEnglish
                  ? 'No additional services available.'
                  : 'ไม่มีบริการเพิ่มเติม',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }
}

// ------------------- _PaymentSummary -------------------
class _PaymentSummary extends StatelessWidget {
  final double totalPaymentAmount;
  final bool isEnglish;

  const _PaymentSummary({
    required this.totalPaymentAmount,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Total Payment Amount' : 'ยอดชำระรวม',
          style: HireFormStyles.labelTextStyle(context),
        ),
        const SizedBox(height: 8.0),
        Text(
          isEnglish
              ? '(All prices are calculated per day)'
              : '(ราคาทั้งหมดคำนวณเป็นรายวัน)',
          style: HireFormStyles.priceDetailTextStyle,
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.currency(
                  locale: isEnglish ? 'en_US' : 'th_TH',
                  symbol: '฿',
                ).format(totalPaymentAmount),
                style: HireFormStyles.totalPaymentAmountStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------- _DateTimeSection -------------------
class _DateTimeSection extends StatelessWidget {
  final TextEditingController startDateController;
  final FocusNode startDateFocusNode;
  final VoidCallback onTapDate;
  final bool isEnglish;
  final TextEditingController startTimeController;
  final FocusNode startTimeFocusNode;
  final VoidCallback onTapTime;

  const _DateTimeSection({
    required this.startDateController,
    required this.startDateFocusNode,
    required this.onTapDate,
    required this.isEnglish,
    required this.startTimeController,
    required this.startTimeFocusNode,
    required this.onTapTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HireTextFormField(
          controller: startDateController,
          focusNode: startDateFocusNode,
          readOnly: true,
          onTap: onTapDate,
          labelText: isEnglish ? 'Start Date' : 'วันที่เริ่มงาน',
          hintText: isEnglish ? 'Select date' : 'เลือกวันที่',
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isEnglish
                  ? 'Please select a start date.'
                  : 'กรุณาเลือกวันที่เริ่มงาน';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        HireTextFormField(
          controller: startTimeController,
          focusNode: startTimeFocusNode,
          readOnly: true,
          onTap: onTapTime,
          labelText: isEnglish ? 'Start Time' : 'เวลาเริ่มงาน',
          hintText: isEnglish ? 'Select start time' : 'เลือกเวลาเริ่มต้น',
          suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isEnglish
                  ? 'Please select a start time.'
                  : 'กรุณาเลือกเวลาเริ่มงาน';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// ------------------- _AddressSection (Requested in full) -------------------
class _AddressSection extends StatelessWidget {
  final bool isDefaultAddress;
  final ValueChanged<bool?> onChanged;
  final bool isEnglish;
  final TextEditingController phoneController;
  final FocusNode phoneFocusNode;
  final TextEditingController houseNumberController;
  final FocusNode houseNumberFocusNode;
  final TextEditingController villageController;
  final FocusNode villageFocusNode;
  final TextEditingController subdistrictController;
  final FocusNode subdistrictFocusNode;
  final TextEditingController districtController;
  final FocusNode districtFocusNode;
  final TextEditingController provinceController;
  final FocusNode provinceFocusNode;

  const _AddressSection({
    super.key,
    required this.isDefaultAddress,
    required this.onChanged,
    required this.isEnglish,
    required this.phoneController,
    required this.phoneFocusNode,
    required this.houseNumberController,
    required this.houseNumberFocusNode,
    required this.villageController,
    required this.villageFocusNode,
    required this.subdistrictController,
    required this.subdistrictFocusNode,
    required this.districtController,
    required this.districtFocusNode,
    required this.provinceController,
    required this.provinceFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    // กำหนดว่าฟอร์มควรถูกเปิดใช้งานหรือไม่
    final bool isFormEnabled = !isDefaultAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox: ใช้ที่อยู่เริ่มต้น
        Row(
          children: [
            Checkbox(
              value: isDefaultAddress,
              activeColor: Colors.red,
              onChanged: onChanged,
            ),
            Text(
              isEnglish ? 'Use default address' : 'ใช้ที่อยู่เริ่มต้น',
              style: TextStyle(
                color: isDefaultAddress ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Phone Number
        HireTextFormField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          enabled: isFormEnabled,
          keyboardType: TextInputType.phone,
          labelText: isEnglish ? 'Phone Number' : 'เบอร์โทรศัพท์',
          hintText:
              isEnglish
                  ? 'Please enter phone number'
                  : 'กรุณากรอกเบอร์โทรศัพท์',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish
                  ? 'Please enter phone number.'
                  : 'กรุณากรอกเบอร์โทรศัพท์';
            }
            if (isFormEnabled &&
                value != null &&
                !RegExp(r'^[0-9]+$').hasMatch(value)) {
              return isEnglish
                  ? 'Please enter numbers only for phone number.'
                  : 'กรุณาพิมพ์เฉพาะตัวเลขสำหรับเบอร์โทรศัพท์';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // House Number
        HireTextFormField(
          controller: houseNumberController,
          focusNode: houseNumberFocusNode,
          enabled: isFormEnabled,
          labelText: isEnglish ? 'House Number' : 'เลขที่บ้าน',
          hintText:
              isEnglish ? 'Please enter house number' : 'กรุณากรอกเลขที่บ้าน',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish
                  ? 'Please enter house number.'
                  : 'กรุณากรอกเลขที่บ้าน';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Village
        HireTextFormField(
          controller: villageController,
          focusNode: villageFocusNode,
          enabled: isFormEnabled,
          labelText: isEnglish ? 'Village' : 'หมู่บ้าน',
          hintText: isEnglish ? 'Please enter village' : 'กรุณากรอกหมู่บ้าน',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter village.' : 'กรุณากรอกหมู่บ้าน';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Subdistrict
        HireTextFormField(
          controller: subdistrictController,
          focusNode: subdistrictFocusNode,
          enabled: isFormEnabled,
          labelText: isEnglish ? 'Subdistrict' : 'ตำบล',
          hintText: isEnglish ? 'Please enter subdistrict' : 'กรุณากรอกตำบล',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter subdistrict.' : 'กรุณากรอกตำบล';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // District
        HireTextFormField(
          controller: districtController,
          focusNode: districtFocusNode,
          enabled: isFormEnabled,
          labelText: isEnglish ? 'District' : 'อำเภอ',
          hintText: isEnglish ? 'Please enter district' : 'กรุณากรอกอำเภอ',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter district.' : 'กรุณากรอกอำเภอ';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Province
        HireTextFormField(
          controller: provinceController,
          focusNode: provinceFocusNode,
          enabled: isFormEnabled,
          labelText: isEnglish ? 'Province' : 'จังหวัด',
          hintText: isEnglish ? 'Please enter province' : 'กรุณากรอกจังหวัด',
          validator: (value) {
            if (isFormEnabled && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter province.' : 'กรุณากรอกจังหวัด';
            }
            return null;
          },
        ),
      ],
    );
  }
}
