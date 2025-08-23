import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
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
  int _currentIndex = 2; // Index สำหรับ BottomNavigationBar

  bool _isDefaultAddress = false;

  // FocusNode สำหรับ TextField
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _villageFocusNode = FocusNode();
  final FocusNode _houseNumberFocusNode = FocusNode();
  final FocusNode _detailWorkFocusNode = FocusNode();
  final FocusNode _startDateFocusNode = FocusNode();
  final FocusNode _startTimeFocusNode = FocusNode();
  final FocusNode _endTimeFocusNode = FocusNode();

  // TextEditingController สำหรับ TextField
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _detailWorkController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // ตัวแปรสำหรับเก็บค่าที่ผู้ใช้เลือก
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  // เพิ่มสำหรับ Hire Name (จาก Dropdown)
  String? _selectedHireName;

  // เพิ่มสำหรับบริการเพิ่มเติม
  final Map<String, bool> _selectedAdditionalServices = {};
  double _totalPaymentAmount = 0.0;
  final double _servicePricePerItem = 100.0; // ราคาบริการเพิ่มเติมต่อรายการ

  final _formKey = GlobalKey<FormState>(); // Key สำหรับ Form Validation

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_handleFocusChange);
    _districtFocusNode.addListener(_handleFocusChange);
    _villageFocusNode.addListener(_handleFocusChange);
    _houseNumberFocusNode.addListener(_handleFocusChange);
    _detailWorkFocusNode.addListener(_handleFocusChange);
    _startDateFocusNode.addListener(_handleFocusChange);
    _startTimeFocusNode.addListener(_handleFocusChange);
    _endTimeFocusNode.addListener(_handleFocusChange);

    // Initialize additional services from housekeeper skills if available
    if (widget.housekeeper.housekeeperSkills != null) {
      for (var skill in widget.housekeeper.housekeeperSkills!) {
        // ใช้ชื่อทักษะภาษาอังกฤษจาก Backend เป็น Key
        _selectedAdditionalServices[skill.skillType?.skillTypeName ?? ""] = false;
      }
    }

    // ตรวจสอบว่ามีที่อยู่เริ่มต้นหรือไม่
    _isDefaultAddress =
        widget.user.person?.address != null &&
        (widget.user.person?.address?.isNotEmpty ?? false) &&
        (widget.user.person?.phoneNumber?.isNotEmpty ?? false); // ตรวจสอบเบอร์โทรด้วย
    if (_isDefaultAddress) {
      _fillDefaultAddress();
    }
    _calculateTotalPayment(); // คำนวณยอดรวมเริ่มต้น
  }

  void _fillDefaultAddress() {
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    // สมมติว่าที่อยู่เริ่มต้นถูกจัดเก็บในรูปแบบ "อำเภอ, หมู่บ้าน, เลขที่บ้าน"
    // คุณอาจต้องปรับ logic ตรงนี้หาก format address จริงๆ ซับซ้อนกว่านี้
    List<String> addressParts =
        (widget.user.person?.address ?? '')
            .split(',')
            .map((e) => e.trim())
            .toList();

    _districtController.text = addressParts.isNotEmpty ? addressParts[0] : '';
    _villageController.text = addressParts.length > 1 ? addressParts[1] : '';
    _houseNumberController.text =
        addressParts.length > 2 ? addressParts[2] : '';
  }

  // ฟังก์ชันสำหรับเลือกวันที่
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
              primary: Colors.red, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // button text color
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
        ).format(picked); // จัดรูปแบบวันที่ให้เป็น dd/MM/yyyy
      });
    }
  }

  // ฟังก์ชันสำหรับเลือกเวลา
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_selectedStartTime ?? TimeOfDay.now())
              : (_selectedEndTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _selectedEndTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  // ฟังก์ชันสำหรับคำนวณยอดรวมการชำระเงิน
  void _calculateTotalPayment() {
    double? basePrice =
        widget.housekeeper.dailyRate; // เริ่มต้นด้วย dailyRate ของแม่บ้าน

    double additionalServiceCost = 0.0;
    _selectedAdditionalServices.forEach((service, isSelected) {
      if (isSelected) {
        additionalServiceCost += _servicePricePerItem;
      }
    });

    setState(() {
      _totalPaymentAmount = ((basePrice ?? 0.0) + additionalServiceCost);
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_handleFocusChange);
    _districtFocusNode.removeListener(_handleFocusChange);
    _villageFocusNode.removeListener(_handleFocusChange);
    _houseNumberFocusNode.removeListener(_handleFocusChange);
    _detailWorkFocusNode.removeListener(_handleFocusChange);
    _startDateFocusNode.removeListener(_handleFocusChange);
    _startTimeFocusNode.removeListener(_handleFocusChange);
    _endTimeFocusNode.removeListener(_handleFocusChange);

    _phoneFocusNode.dispose();
    _districtFocusNode.dispose();
    _villageFocusNode.dispose();
    _houseNumberFocusNode.dispose();
    _detailWorkFocusNode.dispose();
    _startDateFocusNode.dispose();
    _startTimeFocusNode.dispose();
    _endTimeFocusNode.dispose();

    _phoneController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _houseNumberController.dispose();
    _detailWorkController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) {
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
                        builder:
                            (context) => const Center(
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
                            builder:
                                (context) => HireListPage(
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

  Future<void> _createAndSaveHire() async {
    String? phoneNumber;
    String? location;
    String hireName;
    String hireDetail;

    phoneNumber =
        _isDefaultAddress
            ? (widget.user.person?.phoneNumber ?? '')
            : _phoneController.text;

    location =
        _isDefaultAddress
            ? (widget.user.person?.address ?? '')
            : '${_districtController.text}, ${_villageController.text}, ${_houseNumberController.text}';

    hireName = _selectedHireName ?? ''; // ใช้ค่าจาก Dropdown

    // รวมรายละเอียดงานจาก _detailWorkController และบริการเพิ่มเติมที่เลือก
    hireDetail = _detailWorkController.text;
    List<String> additionalServiceNames =
        _selectedAdditionalServices.entries
            .where((entry) => entry.value)
            .map((entry) => SkillTranslator.getLocalizedSkillName(entry.key, widget.isEnglish)) // แปลชื่อบริการเพิ่มเติม
            .toList();

    if (additionalServiceNames.isNotEmpty) {
      hireDetail +=
          (hireDetail.isNotEmpty ? '\n' : '') +
          (widget.isEnglish ? 'Additional Services: ' : 'บริการเพิ่มเติม: ') +
          additionalServiceNames.join(', ');
    }

    String? formattedStartTime;
    if (_selectedStartTime != null) {
      formattedStartTime =
          '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
    }

    String? formattedEndTime;
    if (_selectedEndTime != null) {
      formattedEndTime =
          '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
    }

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
              widget.isEnglish
                  ? 'Please select a start date.'
                  : 'กรุณาเลือกวันที่เริ่มงาน',
            ),
          ),
        );
      }
      return;
    }

    final newHire = Hire(
      hireName: hireName,
      hireDetail: hireDetail,
      paymentAmount: _totalPaymentAmount, // ใช้ยอดรวมที่คำนวณไว้
      hireDate: DateTime.now(),
      startDate: fullStartDate,
      startTime: formattedStartTime ?? '',
      endTime: formattedEndTime ?? '',
      location: location,
      jobStatus:
          'pending', // เปลี่ยนสถานะเริ่มต้นเป็น 'pending' หรือตามที่คุณต้องการ
      progressionImageUrls:
          null, // เปลี่ยนเป็น null หรือค่าเริ่มต้นที่เหมาะสม
      hirer: widget.user,
      housekeeper: widget.housekeeper,
    );

    print('New Hire created: ${newHire.toJson()}');

    try {
      final response = await http.post(
        Uri.parse('$baseURL/maeban/hires'), // <<< แก้ไขตรงนี้: ลบ "/maeban" ซ้ำ
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
              widget.isEnglish
                  ? 'Hire request sent successfully!'
                  : 'ส่งคำขอจ้างสำเร็จ!',
            ),
          ),
        );
      } else {
        print('Failed to save hire. Status code: ${response.statusCode}');
        print('Request body sent: ${jsonEncode(newHire.toJson())}');
        print('Response body: ${response.body}');
        String errorMessage =
            widget.isEnglish
                ? 'Unknown error occurred.'
                : 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ';
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
              widget.isEnglish
                  ? 'Failed to send hire request: $errorMessage'
                  : 'ส่งคำขอจ้างไม่สำเร็จ: $errorMessage',
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
            widget.isEnglish
                ? 'Network error or unable to connect to server.'
                : 'ข้อผิดพลาดเครือข่าย หรือไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
          ),
        ),
      );
    }
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
                          _districtController.clear();
                          _villageController.clear();
                          _houseNumberController.clear();
                          _selectedHireName = null; // เคลียร์ค่าที่เลือกใน Dropdown
                          _startDateController.clear();
                          _startTimeController.clear();
                          _endTimeController.clear();
                          _selectedStartDate = null;
                          _selectedStartTime = null;
                          _selectedEndTime = null;
                          // เคลียร์การเลือกบริการเพิ่มเติมทั้งหมด
                          _selectedAdditionalServices.updateAll(
                            (key, value) => false,
                          );
                        }
                        _calculateTotalPayment(); // คำนวณยอดรวมใหม่
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
              // ใช้ HireDropdownFormField
              HireDropdownFormField<String>(
                value: _selectedHireName,
                labelText: widget.isEnglish ? 'Hire Name/Main Service' : 'ชื่อการจ้างงาน/บริการหลัก',
                hintText: widget.isEnglish ? 'Select main service' : 'เลือกบริการหลัก',
                items: widget.housekeeper.housekeeperSkills?.map((skill) {
                  return DropdownMenuItem<String>(
                    value: skill.skillType?.skillTypeName ?? "",
                    child: Text(SkillTranslator.getLocalizedSkillName(skill.skillType?.skillTypeName, widget.isEnglish)),
                  );
                }).toList() ?? [],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHireName = newValue;
                    _calculateTotalPayment(); // คำนวณยอดรวมใหม่เมื่อเลือกบริการหลัก
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
              // สร้าง CheckboxListTile สำหรับบริการเพิ่มเติม
              if (widget.housekeeper.housekeeperSkills != null &&
                  widget.housekeeper.housekeeperSkills!.isNotEmpty)
                ..._selectedAdditionalServices.keys.map((serviceName) {
                  // กรองไม่ให้บริการหลักที่เลือกไปแล้วมาแสดงซ้ำในบริการเสริม
                  if (serviceName == _selectedHireName) {
                    return const SizedBox.shrink(); // ซ่อนรายการนี้
                  }
                  return HireCheckboxListTile(
                    title: SkillTranslator.getLocalizedSkillName(serviceName, widget.isEnglish),
                    value: _selectedAdditionalServices[serviceName]!,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedAdditionalServices[serviceName] = value!;
                        _calculateTotalPayment(); // คำนวณยอดรวมใหม่เมื่อเลือกบริการเสริม
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
                    ? '(Base rate: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}, Additional service: ฿${_servicePricePerItem.toStringAsFixed(0)}/item)'
                    : '(ค่าบริการพื้นฐาน: ฿${widget.housekeeper.dailyRate?.toStringAsFixed(0)}, บริการเพิ่มเติม: ฿${_servicePricePerItem.toStringAsFixed(0)}/รายการ)',
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
                      NumberFormat.currency(locale: widget.isEnglish ? 'en_US' : 'th_TH', symbol: '฿').format(_totalPaymentAmount),
                      style: HireFormStyles.totalPaymentAmountStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              // ใช้ HireTextFormField สำหรับ Start Date
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
              // ใช้ HireTextFormField สำหรับ Start Time
              HireTextFormField(
                controller: _startTimeController,
                focusNode: _startTimeFocusNode,
                readOnly: true,
                onTap: () => _selectTime(context, true),
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
              const SizedBox(height: 16.0),
              // ใช้ HireTextFormField สำหรับ End Time
              HireTextFormField(
                controller: _endTimeController,
                focusNode: _endTimeFocusNode,
                readOnly: true,
                onTap: () => _selectTime(context, false),
                labelText: widget.isEnglish ? 'End Time' : 'เวลาสิ้นสุดงาน',
                hintText: widget.isEnglish ? 'Select end time' : 'เลือกเวลาสิ้นสุด',
                suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please select an end time.' : 'กรุณาเลือกเวลาสิ้นสุดงาน';
                  }
                  if (_selectedStartTime != null && _selectedEndTime != null) {
                    final startDateTime = DateTime(
                      2000, 1, 1, _selectedStartTime!.hour, _selectedStartTime!.minute,
                    );
                    final endDateTime = DateTime(
                      2000, 1, 1, _selectedEndTime!.hour, _selectedEndTime!.minute,
                    );
                    if (endDateTime.isBefore(startDateTime)) {
                      return widget.isEnglish ? 'End time must be after start time.' : 'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มงาน';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // ใช้ HireTextFormField สำหรับ Phone Number
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
              // ใช้ HireTextFormField สำหรับ District
              HireTextFormField(
                controller: _districtController,
                focusNode: _districtFocusNode,
                enabled: !_isDefaultAddress,
                labelText: widget.isEnglish ? 'District' : 'อำเภอ',
                hintText: widget.isEnglish ? 'Please enter district' : 'กรุณากรอกอำเภอ',
                validator: (value) {
                  if (!_isDefaultAddress && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter district.' : 'กรุณากรอกอำเภอ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // ใช้ HireTextFormField สำหรับ Village
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
              // ใช้ HireTextFormField สำหรับ House Number
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
              // ใช้ HireTextFormField สำหรับ Job Details
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
                builder: (context) => CardpageMember( // เปลี่ยนเป็น DepositMemberPage
                  user: widget.user,
                  isEnglish: widget.isEnglish,
                ),
              ),
            );
          } else if (index == 2) {
            // อยู่ในหน้านี้แล้ว ไม่ต้องทำอะไร
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
