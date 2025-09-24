import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
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
  _HireHousekeeperPageState createState() => _HireHousekeeperPageState();
}

class _HireHousekeeperPageState extends State<HireHousekeeperPage> {
  int _currentIndex = 2; // Index for BottomNavigationBar

  bool _isDefaultAddress = false;

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _subdistrictFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _villageFocusNode = FocusNode();
  final FocusNode _houseNumberFocusNode = FocusNode();
  final FocusNode _detailWorkFocusNode = FocusNode();
  final FocusNode _startDateFocusNode = FocusNode();
  final FocusNode _startTimeFocusNode = FocusNode();
  // final FocusNode _endTimeFocusNode = FocusNode(); // **ลบออก**

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _detailWorkController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  // final TextEditingController _endTimeController = TextEditingController(); // **ลบออก**

  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  // TimeOfDay? _selectedEndTime; // **ลบออก**

  String? _selectedHireName;

  final Map<String, bool> _selectedAdditionalServices = {};
  double _totalPaymentAmount = 0.0;
  // final double _servicePricePerItem = 100.0; // **ลบออก**

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_handleFocusChange);
    _provinceFocusNode.addListener(_handleFocusChange);
    _subdistrictFocusNode.addListener(_handleFocusChange);
    _districtFocusNode.addListener(_handleFocusChange);
    _villageFocusNode.addListener(_handleFocusChange);
    _houseNumberFocusNode.addListener(_handleFocusChange);
    _detailWorkFocusNode.addListener(_handleFocusChange);
    _startDateFocusNode.addListener(_handleFocusChange);
    _startTimeFocusNode.addListener(_handleFocusChange);
    // _endTimeFocusNode.addListener(_handleFocusChange); // **ลบออก**

    if (widget.housekeeper.housekeeperSkills != null) {
      for (var skill in widget.housekeeper.housekeeperSkills!) {
        _selectedAdditionalServices[skill.skillType?.skillTypeName ?? ""] = false;
      }
    }

    _isDefaultAddress = widget.user.person?.address != null &&
        (widget.user.person?.address?.isNotEmpty ?? false) &&
        (widget.user.person?.phoneNumber?.isNotEmpty ?? false);

    if (_isDefaultAddress) {
      _fillDefaultAddress();
    }
    _calculateTotalPayment();
  }

  void _fillDefaultAddress() {
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    List<String> addressParts = (widget.user.person?.address ?? '')
        .split(' ')
        .map((e) => e.trim())
        .toList();

    _houseNumberController.text = addressParts.isNotEmpty ? addressParts[0] : '';
    _villageController.text = addressParts.length > 1 ? addressParts[1] : '';
    _subdistrictController.text = addressParts.length > 2 ? addressParts[2] : '';
    _districtController.text = addressParts.length > 3 ? addressParts[3] : '';
    _provinceController.text = addressParts.length > 4 ? addressParts[4] : '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(picked);

        // รีเซ็ตค่าเวลาเมื่อเลือกวันที่ใหม่
        _selectedStartTime = null;
        _startTimeController.clear();
        // _selectedEndTime = null; // **ลบออก**
        // _endTimeController.clear(); // **ลบออก**
        _calculateTotalPayment();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // เพิ่มการตรวจสอบว่าเลือกวันที่แล้วหรือยัง
    if (_selectedStartDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Please select a date first.' : 'กรุณาเลือกวันที่ก่อน',
            ),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (_selectedStartTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final selectedDateTime = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
        picked.hour,
        picked.minute,
      );

      // ตรวจสอบว่าเวลาที่เลือกย้อนหลังหรือไม่ (เฉพาะเวลาเริ่มต้น)
      if (selectedDateTime.isBefore(now)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEnglish ? 'Start time cannot be in the past.' : 'เวลาเริ่มต้นไม่สามารถย้อนหลังได้',
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = picked.format(context);
        _calculateTotalPayment();
      });
    }
  }

  void _calculateTotalPayment() {
    double? basePrice = widget.housekeeper.dailyRate;
    double additionalServiceCost = 0.0;
    _selectedAdditionalServices.forEach((service, isSelected) {
      if (isSelected) {
        // **แก้ไข: ราคาบริการเสริมเท่ากับ dailyRate**
        additionalServiceCost += (widget.housekeeper.dailyRate ?? 0.0);
      }
    });

    setState(() {
      _totalPaymentAmount = ((basePrice ?? 0.0) + additionalServiceCost);
    });
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _phoneController.dispose();
    _subdistrictController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _houseNumberController.dispose();
    _detailWorkController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    // _endTimeController.dispose(); // **ลบออก**

    _phoneFocusNode.removeListener(_handleFocusChange);
    _provinceFocusNode.removeListener(_handleFocusChange);
    _subdistrictFocusNode.removeListener(_handleFocusChange);
    _districtFocusNode.removeListener(_handleFocusChange);
    _villageFocusNode.removeListener(_handleFocusChange);
    _houseNumberFocusNode.removeListener(_handleFocusChange);
    _detailWorkFocusNode.removeListener(_handleFocusChange);
    _startDateFocusNode.removeListener(_handleFocusChange);
    _startTimeFocusNode.removeListener(_handleFocusChange);
    // _endTimeFocusNode.removeListener(_handleFocusChange); // **ลบออก**

    _phoneFocusNode.dispose();
    _provinceFocusNode.dispose();
    _subdistrictFocusNode.dispose();
    _districtFocusNode.dispose();
    _villageFocusNode.dispose();
    _houseNumberFocusNode.dispose();
    _detailWorkFocusNode.dispose();
    _startDateFocusNode.dispose();
    _startTimeFocusNode.dispose();
    // _endTimeFocusNode.dispose(); // **ลบออก**
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  Future<void> _createAndSaveHire() async {
    String? phoneNumber;
    String? location;
    String hireName;
    String hireDetail;

    phoneNumber = _isDefaultAddress ? (widget.user.person?.phoneNumber ?? '') : _phoneController.text;

    location = _isDefaultAddress
        ? (widget.user.person?.address ?? '')
        : '${_districtController.text}, ${_villageController.text}, ${_houseNumberController.text}';

    hireName = _selectedHireName ?? '';

    hireDetail = _detailWorkController.text;
    List<String> additionalServiceNames = _selectedAdditionalServices.entries
        .where((entry) => entry.value)
        .map((entry) => SkillTranslator.getLocalizedSkillName(entry.key, widget.isEnglish))
        .toList();

    if (additionalServiceNames.isNotEmpty) {
      hireDetail +=
          (hireDetail.isNotEmpty ? '\n' : '') +
              (widget.isEnglish ? 'Additional Services: ' : 'บริการเพิ่มเติม: ') +
              additionalServiceNames.join(', ');
    }

    String? formattedStartTime;
    if (_selectedStartTime != null) {
      formattedStartTime = '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
    }

    // String? formattedEndTime; // **ลบออก**
    // if (_selectedEndTime != null) {
    //   formattedEndTime = '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
    // }

    DateTime? fullStartDate;
    if (_selectedStartDate != null) {
      fullStartDate = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
        _selectedStartTime?.hour ?? 0,
        _selectedStartTime?.minute ?? 0,
      );
    }

    if (fullStartDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Please select a start date.' : 'กรุณาเลือกวันที่เริ่มงาน',
            ),
          ),
        );
      }
      return;
    }

    final newHire = Hire(
      hireName: hireName,
      hireDetail: hireDetail,
      paymentAmount: _totalPaymentAmount,
      hireDate: DateTime.now(),
      startDate: fullStartDate,
      startTime: formattedStartTime ?? '',
      endTime: '', // **แก้ไข: กำหนดเป็นค่าว่างแทน**
      location: location,
      jobStatus: 'pending',
      progressionImageUrls: null,
      hirer: widget.user,
      housekeeper: widget.housekeeper,
    );

    print('New Hire created: ${newHire.toJson()}');

    try {
      final response = await http.post(
        Uri.parse('$baseURL/maeban/hires'), // << แก้ไขตามโค้ดต้นฉบับ
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(newHire.toJson()),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Hire saved successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Hire request sent successfully!' : 'ส่งคำขอจ้างสำเร็จ!',
            ),
          ),
        );
      } else {
        print('Failed to save hire. Status code: ${response.statusCode}');
        print('Request body sent: ${jsonEncode(newHire.toJson())}');
        print('Response body: ${response.body}');
        String errorMessage = widget.isEnglish ? 'Unknown error occurred.' : 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ';
        try {
          if (response.body.isNotEmpty) {
            final responseJson = jsonDecode(response.body);
            if (responseJson is Map && responseJson.containsKey('error')) {
              errorMessage = responseJson['error'];
            } else {
              errorMessage = response.body;
            }
          }
        } catch (e) {
          errorMessage = response.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Failed to send hire request: $errorMessage' : 'ส่งคำขอจ้างไม่สำเร็จ: $errorMessage',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving hire: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish ? 'Network error or unable to connect to server.' : 'ข้อผิดพลาดเครือข่าย หรือไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
          ),
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // **เพิ่ม: ตรวจสอบยอดเงินคงเหลือ**
    if (_totalPaymentAmount > (widget.user.balance ?? 0.0)) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(widget.isEnglish ? 'Insufficient Balance' : 'ยอดเงินไม่เพียงพอ'),
            content: Text(widget.isEnglish ? 'Your balance is not enough to make this payment.' : 'ยอดเงินคงเหลือของคุณไม่เพียงพอ'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(widget.isEnglish ? 'OK' : 'ตกลง'),
              ),
            ],
          );
        },
      );
      return;
    }

    final currentContext = context;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 70.0,
                height: 70.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade100,
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.red, size: 40.0),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                widget.isEnglish ? 'Confirm Hire' : 'ยืนยันการจ้างแม่บ้าน',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.isEnglish
                    ? 'Are you sure you want to send a hire request?'
                    : 'คุณแน่ใจหรือไม่ที่ต้องการส่ง\nคำขอจ้างแม่บ้าน?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: HireFormStyles.cancelButtonDialogStyle,
                    child: Text(
                      widget.isEnglish ? 'Cancel' : 'ยกเลิก',
                      style: HireFormStyles.cancelButtonDialogTextStyle,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();

                      showDialog(
                        context: currentContext,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                          ),
                        ),
                      );

                      await _createAndSaveHire();

                      if (currentContext.mounted) {
                        Navigator.of(currentContext).pop();
                      }

                      if (currentContext.mounted) {
                        Navigator.pushAndRemoveUntil(
                          currentContext,
                          MaterialPageRoute(
                            builder: (context) => HireListPage(
                              isEnglish: widget.isEnglish,
                              user: widget.user,
                            ),
                          ),
                          (Route<dynamic> route) => route.isFirst,
                        );
                      }
                    },
                    style: HireFormStyles.confirmButtonDialogStyle,
                    child: Text(
                      widget.isEnglish ? 'Confirm' : 'ยืนยัน',
                      style: HireFormStyles.confirmButtonDialogTextStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                user: widget.user,
                isEnglish: widget.isEnglish,
              ),
            ),
          ),
        ),
        title: Text(
          widget.isEnglish
              ? 'Hire Details and Address'
              : 'ข้อมูลการจ้างงานและที่อยู่',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isDefaultAddress,
                    activeColor: Colors.red,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDefaultAddress = value!;
                        if (_isDefaultAddress) {
                          _fillDefaultAddress();
                        } else {
                          _phoneController.clear();
                          _provinceController.clear();
                          _subdistrictController.clear();
                          _districtController.clear();
                          _villageController.clear();
                          _houseNumberController.clear();
                          _selectedHireName = null;
                          _startDateController.clear();
                          _startTimeController.clear();
                          // _endTimeController.clear(); // **ลบออก**
                          _selectedStartDate = null;
                          _selectedStartTime = null;
                          // _selectedEndTime = null; // **ลบออก**
                          _selectedAdditionalServices.updateAll(
                            (key, value) => false,
                          );
                        }
                        _calculateTotalPayment();
                      });
                    },
                  ),
                  Text(
                    widget.isEnglish
                        ? 'Use default address'
                        : 'ใช้ที่อยู่เริ่มต้น',
                    style: TextStyle(
                      color: _isDefaultAddress ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              HireDropdownFormField<String>(
                value: _selectedHireName,
                labelText: widget.isEnglish ? 'Hire Name/Main Service' : 'ชื่อการจ้างงาน/บริการหลัก',
                hintText: widget.isEnglish ? 'Select main service' : 'เลือกบริการหลัก',
                items: widget.housekeeper.housekeeperSkills?.map((skill) {
                      return DropdownMenuItem<String>(
                        value: skill.skillType?.skillTypeName ?? "",
                        child: Text(SkillTranslator.getLocalizedSkillName(skill.skillType?.skillTypeName, widget.isEnglish)),
                      );
                    }).toList() ??
                    [],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHireName = newValue;
                    _calculateTotalPayment();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please select a main service.' : 'กรุณาเลือกบริการหลัก';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Text(
                widget.isEnglish
                    ? 'Additional Services (Optional)'
                    : 'บริการเพิ่มเติม (เลือกได้หลายรายการ)',
                style: HireFormStyles.labelTextStyle(context),
              ),
              const SizedBox(height: 8.0),
              if (widget.housekeeper.housekeeperSkills != null &&
                  widget.housekeeper.housekeeperSkills!.isNotEmpty)
                ..._selectedAdditionalServices.keys.map((serviceName) {
                  if (serviceName == _selectedHireName) {
                    return const SizedBox.shrink();
                  }
                  return HireCheckboxListTile(
                    title: SkillTranslator.getLocalizedSkillName(serviceName, widget.isEnglish),
                    value: _selectedAdditionalServices[serviceName]!,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedAdditionalServices[serviceName] = value!;
                        _calculateTotalPayment();
                      });
                    },
                  );
                })
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    widget.isEnglish
                        ? 'No additional services available.'
                        : 'ไม่มีบริการเพิ่มเติม',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              const SizedBox(height: 16.0),
              Text(
                widget.isEnglish ? 'Total Payment Amount' : 'ยอดชำระรวม',
                style: HireFormStyles.labelTextStyle(context),
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.isEnglish
                    ? '(Base rate: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}, Additional service: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}/item)' // **แก้ไข: แสดงราคาตาม dailyRate**
                    : '(ค่าบริการพื้นฐาน: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}, บริการเพิ่มเติม: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}/รายการ)', // **แก้ไข: แสดงราคาตาม dailyRate**
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
                      NumberFormat.currency(locale: widget.isEnglish ? 'en_US' : 'th_TH', symbol: '฿')
                          .format(_totalPaymentAmount),
                      style: HireFormStyles.totalPaymentAmountStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _startDateController,
                focusNode: _startDateFocusNode,
                readOnly: true,
                onTap: () => _selectDate(context),
                labelText: widget.isEnglish ? 'Start Date' : 'วันที่เริ่มงาน',
                hintText: widget.isEnglish ? 'Select date' : 'เลือกวันที่',
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please select a start date.' : 'กรุณาเลือกวันที่เริ่มงาน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _startTimeController,
                focusNode: _startTimeFocusNode,
                readOnly: true,
                onTap: () => _selectTime(context), // **แก้ไข: ลบ `isStartTime`**
                labelText: widget.isEnglish ? 'Start Time' : 'เวลาเริ่มงาน',
                hintText: widget.isEnglish ? 'Select start time' : 'เลือกเวลาเริ่มต้น',
                suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please select a start time.' : 'กรุณาเลือกเวลาเริ่มงาน';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 16.0), // **ลบออก**
              // HireTextFormField( // **ลบออก**
              //   controller: _endTimeController, // **ลบออก**
              //   focusNode: _endTimeFocusNode, // **ลบออก**
              //   readOnly: true, // **ลบออก**
              //   onTap: () => _selectTime(context, false), // **ลบออก**
              //   labelText: widget.isEnglish ? 'End Time' : 'เวลาสิ้นสุดงาน', // **ลบออก**
              //   hintText: widget.isEnglish ? 'Select end time' : 'เลือกเวลาสิ้นสุด', // **ลบออก**
              //   suffixIcon: const Icon(Icons.access_time, color: Colors.grey), // **ลบออก**
              //   validator: (value) { // **ลบออก**
              //     if (value == null || value.isEmpty) { // **ลบออก**
              //       return widget.isEnglish ? 'Please select an end time.' : 'กรุณาเลือกเวลาสิ้นสุดงาน'; // **ลบออก**
              //     } // **ลบออก**
              //     if (_selectedStartTime != null && _selectedEndTime != null) { // **ลบออก**
              //       final startDateTime = DateTime(2000, 1, 1, _selectedStartTime!.hour, _selectedStartTime!.minute); // **ลบออก**
              //       final endDateTime = DateTime(2000, 1, 1, _selectedEndTime!.hour, _selectedEndTime!.minute); // **ลบออก**
              //       if (endDateTime.isBefore(startDateTime)) { // **ลบออก**
              //         return widget.isEnglish ? 'End time must be after start time.' : 'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มงาน'; // **ลบออก**
              //       } // **ลบออก**
              //     } // **ลบออก**
              //     return null; // **ลบออก**
              //   }, // **ลบออก**
              // ), // **ลบออก**
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                enabled: !_isDefaultAddress,
                keyboardType: TextInputType.phone,
                labelText: widget.isEnglish ? 'Phone Number' : 'เบอร์โทรศัพท์',
                hintText: widget.isEnglish ? 'Please enter phone number' : 'กรุณากรอกเบอร์โทรศัพท์',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter phone number.' : 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (!_isDefaultAddress && value != null && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return widget.isEnglish ? 'Please enter numbers only for phone number.' : 'กรุณากรอกเฉพาะตัวเลขสำหรับเบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _houseNumberController,
                focusNode: _houseNumberFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'House Number' : 'เลขที่บ้าน',
                hintText: widget.isEnglish ? 'Please enter house number' : 'กรุณากรอกเลขที่บ้าน',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter house number.' : 'กรุณากรอกเลขที่บ้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _villageController,
                focusNode: _villageFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'Village' : 'หมู่บ้าน',
                hintText: widget.isEnglish ? 'Please enter village' : 'กรุณากรอกหมู่บ้าน',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter village.' : 'กรุณากรอกหมู่บ้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _subdistrictController,
                focusNode: _subdistrictFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'Subdistrict ' : 'ตำบล',
                hintText: widget.isEnglish ? 'Please enter Subdistrict ' : 'กรุณากรอกตำบล',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter Subdistrict .' : 'กรุณากรอกตำบล';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _districtController,
                focusNode: _districtFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'District ' : 'อำเภอ',
                hintText: widget.isEnglish ? 'Please enter District ' : 'กรุณากรอกอำเภอ',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter District .' : 'กรุณากรอกอำเภอ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _provinceController,
                focusNode: _provinceFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'Province ' : 'จังหวัด',
                hintText: widget.isEnglish ? 'Please enter Province ' : 'กรุณากรอกจังหวัด',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter Province .' : 'กรุณากรอกจังหวัด';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              HireTextFormField(
                controller: _detailWorkController,
                focusNode: _detailWorkFocusNode,
                maxLines: 3,
                labelText: widget.isEnglish ? 'Job Details' : 'รายละเอียดงาน',
                hintText: widget.isEnglish ? 'Please enter job details' : 'กรุณากรอกรายละเอียดงาน',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please enter job details.' : 'กรุณากรอกรายละเอียดงาน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: HireFormStyles.confirmButtonStyle,
                  child: Text(
                    widget.isEnglish ? 'Confirm' : 'ยืนยัน',
                    style: HireFormStyles.confirmButtonTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CardpageMember(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 2) {
            // Do nothing, already on this page
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileMemberPage(
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card),
            label: widget.isEnglish ? 'Card' : 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: widget.isEnglish ? 'Hires' : 'การจ้าง',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}