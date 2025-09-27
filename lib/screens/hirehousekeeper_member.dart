import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _detailWorkController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  String? _selectedHireName;
  final Map<HousekeeperSkill, bool> _selectedAdditionalServices = {};
  double _totalPaymentAmount = 0.0;
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
    if (widget.housekeeper.housekeeperSkills != null &&
        widget.housekeeper.housekeeperSkills!.isNotEmpty) {
      for (var skill in widget.housekeeper.housekeeperSkills!) {
        _selectedAdditionalServices[skill] = false;
      }
      final mainSkill = widget.housekeeper.housekeeperSkills!.first;
      _selectedHireName = mainSkill.skillType?.skillTypeName;
      _selectedAdditionalServices[mainSkill] = true;
    }
    _isDefaultAddress =
        widget.user.person?.address != null &&
        (widget.user.person?.address?.isNotEmpty ?? false) &&
        (widget.user.person?.phoneNumber?.isNotEmpty ?? false);
    if (_isDefaultAddress) {
      _fillDefaultAddress();
    }
    _calculateTotalPayment();
  }

  void _fillDefaultAddress() {
    _phoneController.text = widget.user.person?.phoneNumber ?? '';
    List<String> addressParts =
        (widget.user.person?.address ?? '')
            .split(' ')
            .map((e) => e.trim())
            .toList();
    _houseNumberController.text =
        addressParts.isNotEmpty ? addressParts[0] : '';
    _villageController.text = addressParts.length > 1 ? addressParts[1] : '';
    _subdistrictController.text =
        addressParts.length > 2 ? addressParts[2] : '';
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        _selectedStartTime = null;
        _startTimeController.clear();
        _calculateTotalPayment();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_selectedStartDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Please select a date first.'
                  : 'กรุณาเลือกวันที่ก่อน',
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      if (selectedDateTime.isBefore(now)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEnglish
                    ? 'Start time cannot be in the past.'
                    : 'เวลาเริ่มต้นไม่สามารถย้อนหลังได้',
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

  void _onSkillChanged(bool? isSelected, HousekeeperSkill skill) {
    setState(() {
      if (_selectedHireName == skill.skillType?.skillTypeName &&
          isSelected == false) {
        return;
      }
      _selectedAdditionalServices[skill] = isSelected ?? false;
      _calculateTotalPayment();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _subdistrictController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _houseNumberController.dispose();
    _detailWorkController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();

    _phoneFocusNode.removeListener(_handleFocusChange);
    _provinceFocusNode.removeListener(_handleFocusChange);
    _subdistrictFocusNode.removeListener(_handleFocusChange);
    _districtFocusNode.removeListener(_handleFocusChange);
    _villageFocusNode.removeListener(_handleFocusChange);
    _houseNumberFocusNode.removeListener(_handleFocusChange);
    _detailWorkFocusNode.removeListener(_handleFocusChange);
    _startDateFocusNode.removeListener(_handleFocusChange);
    _startTimeFocusNode.removeListener(_handleFocusChange);

    _phoneFocusNode.dispose();
    _provinceFocusNode.dispose();
    _subdistrictFocusNode.dispose();
    _districtFocusNode.dispose();
    _villageFocusNode.dispose();
    _houseNumberFocusNode.dispose();
    _detailWorkFocusNode.dispose();
    _startDateFocusNode.dispose();
    _startTimeFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  Future<void> _createAndSaveHire() async {
    String? phoneNumber;
    String? location;
    String hireName;
    String hireDetail = _detailWorkController.text;

    phoneNumber =
        _isDefaultAddress
            ? (widget.user.person?.phoneNumber ?? '')
            : _phoneController.text;

    location =
        _isDefaultAddress
            ? (widget.user.person?.address ?? '')
            : '${_houseNumberController.text} ${_villageController.text} ${_subdistrictController.text} ${_districtController.text} ${_provinceController.text}';

    hireName = _selectedHireName ?? '';

    final List<int> additionalSkillTypeIds = [];
    final List<String> additionalServiceNames = [];
    _selectedAdditionalServices.forEach((skill, isSelected) {
      if (isSelected && skill.skillType?.skillTypeName != _selectedHireName) {
        if (skill.skillType?.skillTypeId != null) {
          additionalSkillTypeIds.add(skill.skillType!.skillTypeId!);
          additionalServiceNames.add(
            SkillTranslator.getLocalizedSkillName(
              skill.skillType?.skillTypeName,
              widget.isEnglish,
            ),
          );
        }
      }
    });

    if (hireDetail.isEmpty) {
      final mainServiceName =
          _selectedHireName != null
              ? SkillTranslator.getLocalizedSkillName(
                _selectedHireName,
                widget.isEnglish,
              )
              : '';
      if (additionalServiceNames.isNotEmpty) {
        hireDetail =
            (widget.isEnglish ? 'Hired for ' : 'จ้างงานสำหรับ ') +
            mainServiceName +
            (widget.isEnglish
                ? ' with additional services: '
                : ' พร้อมบริการเสริม: ') +
            additionalServiceNames.join(', ');
      } else {
        hireDetail =
            (widget.isEnglish ? 'Hired for ' : 'จ้างงานสำหรับ ') +
            mainServiceName +
            (widget.isEnglish ? '.' : '.');
      }
    } else {
      if (additionalServiceNames.isNotEmpty) {
        hireDetail +=
            (hireDetail.isNotEmpty ? '\n' : '') +
            (widget.isEnglish ? 'Additional Services: ' : 'บริการเพิ่มเติม: ') +
            additionalServiceNames.join(', ');
      }
    }

    String? formattedStartTime;
    if (_selectedStartTime != null) {
      formattedStartTime =
          '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
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

    final mainSkill = widget.housekeeper.housekeeperSkills?.firstWhere(
      (s) => s.skillType?.skillTypeName == _selectedHireName,
      orElse: () => throw Exception('Main skill not found'),
    );

    if (mainSkill == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Please select a main service.'
                  : 'กรุณาเลือกบริการหลัก',
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
      startTime: formattedStartTime,
      endTime: '',
      location: location,
      jobStatus: 'pending',
      progressionImageUrls: null,
      hirer: widget.user,
      housekeeper: widget.housekeeper,
      skillTypeId: mainSkill.skillType?.skillTypeId,
      additionalSkillTypeIds: additionalSkillTypeIds,
    );

    print('New Hire created: ${newHire.toJson()}');

    try {
      final response = await http.post(
        Uri.parse('$baseURL/maeban/hires'),
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
        if (mounted) {
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

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_totalPaymentAmount > (widget.user.balance ?? 0.0)) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
              widget.isEnglish ? 'Insufficient Balance' : 'ยอดเงินไม่เพียงพอ',
            ),
            content: Text(
              widget.isEnglish
                  ? 'Your balance is not enough to make this payment.'
                  : 'ยอดเงินคงเหลือของคุณไม่เพียงพอ',
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF9800)),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => HomePage(
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
                        );
                    if (mainSkill != null) {
                      _selectedAdditionalServices[mainSkill] = true;
                    }
                    _calculateTotalPayment();
                  });
                },
                onAdditionalServiceChanged: _onSkillChanged,
              ),
              const SizedBox(height: 16.0),
              _PaymentSummary(
                totalPaymentAmount: _totalPaymentAmount,
                isEnglish: widget.isEnglish,
              ),
              const SizedBox(height: 16.0),
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
              HireTextFormField(
                controller: _detailWorkController,
                focusNode: _detailWorkFocusNode,
                labelText: widget.isEnglish ? 'Work Details' : 'รายละเอียดงาน',
                hintText:
                    widget.isEnglish
                        ? 'e.g., specific tasks, special instructions'
                        : 'เช่น รายการงานที่ต้องการ, คำแนะนำพิเศษ',
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              _AddressSection(
                isDefaultAddress: _isDefaultAddress,
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
              Center(
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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

// Separate widget for the address input fields.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        HireTextFormField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          enabled: !isDefaultAddress,
          keyboardType: TextInputType.phone,
          labelText: isEnglish ? 'Phone Number' : 'เบอร์โทรศัพท์',
          hintText:
              isEnglish
                  ? 'Please enter phone number'
                  : 'กรุณากรอกเบอร์โทรศัพท์',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish
                  ? 'Please enter phone number.'
                  : 'กรุณากรอกเบอร์โทรศัพท์';
            }
            if (!isDefaultAddress &&
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
        HireTextFormField(
          controller: houseNumberController,
          focusNode: houseNumberFocusNode,
          enabled: !isDefaultAddress,
          labelText: isEnglish ? 'House Number' : 'เลขที่บ้าน',
          hintText:
              isEnglish ? 'Please enter house number' : 'กรุณากรอกเลขที่บ้าน',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish
                  ? 'Please enter house number.'
                  : 'กรุณากรอกเลขที่บ้าน';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        HireTextFormField(
          controller: villageController,
          focusNode: villageFocusNode,
          enabled: !isDefaultAddress,
          labelText: isEnglish ? 'Village' : 'หมู่บ้าน',
          hintText: isEnglish ? 'Please enter village' : 'กรุณากรอกหมู่บ้าน',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter village.' : 'กรุณากรอกหมู่บ้าน';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        HireTextFormField(
          controller: subdistrictController,
          focusNode: subdistrictFocusNode,
          enabled: !isDefaultAddress,
          labelText: isEnglish ? 'Subdistrict' : 'ตำบล',
          hintText: isEnglish ? 'Please enter subdistrict' : 'กรุณากรอกตำบล',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter subdistrict.' : 'กรุณากรอกตำบล';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        HireTextFormField(
          controller: districtController,
          focusNode: districtFocusNode,
          enabled: !isDefaultAddress,
          labelText: isEnglish ? 'District' : 'อำเภอ',
          hintText: isEnglish ? 'Please enter district' : 'กรุณากรอกอำเภอ',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter district.' : 'กรุณากรอกอำเภอ';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        HireTextFormField(
          controller: provinceController,
          focusNode: provinceFocusNode,
          enabled: !isDefaultAddress,
          labelText: isEnglish ? 'Province' : 'จังหวัด',
          hintText: isEnglish ? 'Please enter province' : 'กรุณากรอกจังหวัด',
          validator: (value) {
            if (!isDefaultAddress && (value == null || value.isEmpty)) {
              return isEnglish ? 'Please enter province.' : 'กรุณากรอกจังหวัด';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// Separate widget for service selection.
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

// Separate widget for the payment summary.
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

// Separate widget for the date and time selection.
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
