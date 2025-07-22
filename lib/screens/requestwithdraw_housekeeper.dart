import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:maebanjumpen/model/member.dart'; // เพิ่มการนำเข้า Member
import 'package:provider/provider.dart'; // เพิ่มการนำเข้า Provider

class RequestWithdrawalScreen extends StatefulWidget {
  final Housekeeper user; // Add Housekeeper user to get memberId and balance
  final bool isEnglish;

  const RequestWithdrawalScreen({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  State<RequestWithdrawalScreen> createState() =>
      _RequestWithdrawalScreenState();
}

class _RequestWithdrawalScreenState extends State<RequestWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>(); // Key สำหรับ Form Validation

  final TextEditingController _withdrawalAmountController =
      TextEditingController();
  final TextEditingController _prompayNumberController =
      TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController(); // เพิ่มสำหรับเลขที่บัญชี
  final TextEditingController _bankAccountNameController =
      TextEditingController(); // เพิ่มสำหรับชื่อบัญชี
  final TransactionController _transactionController = TransactionController();
  double _currentBalance = 0.0;
  bool _isSubmitting = false; // สถานะการส่งข้อมูล
  // final Uuid _uuid = Uuid(); // ไม่จำเป็นต้องใช้ Uuid ที่นี่แล้ว NotificationManager จัดการเอง

  @override
  void initState() {
    super.initState();
    // Initialize _currentBalance from the passed user object
    _currentBalance = widget.user.balance ?? 0.0;
    // Pre-fill PromPay number if user has a phone number
    _usePhoneNumberAsPromPay();
    // Initialize bank account name/number if available from user profile (assuming they are stored there)
    // You might need to adjust this based on how your Housekeeper model stores bank info
  }

  @override
  void dispose() {
    _withdrawalAmountController.dispose();
    _prompayNumberController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  /// Function to handle withdrawal request
  Future<void> _requestWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return; // ถ้า Form ไม่ผ่านการ Validation ให้หยุด
    }

    setState(() {
      _isSubmitting = true; // เริ่มต้นสถานะการส่งข้อมูล
    });

    final String amountText = _withdrawalAmountController.text.trim();
    final String prompayNumber = _prompayNumberController.text.trim();
    final String bankAccountNumber =
        _bankAccountNumberController.text.trim(); // Get bank account number
    final String bankAccountName =
        _bankAccountNameController.text.trim(); // Get bank account name

    final double withdrawalAmount = double.tryParse(amountText) ?? 0.0;

    final Member memberForTransaction = Member(id: widget.user.id);

    final newTransaction = Transaction(
      transactionType: 'Withdrawal', // Backend expects 'Withdrawal'
      transactionAmount: withdrawalAmount,
      transactionDate: DateTime.now(), // Current date/time for the request
      transactionStatus: 'Pending Approve', // Initial status
      member: memberForTransaction,
      prompayNumber: prompayNumber.isNotEmpty ? prompayNumber : null,
      bankAccountNumber: bankAccountNumber.isNotEmpty ? bankAccountNumber : null,
      bankAccountName: bankAccountName.isNotEmpty ? bankAccountName : null,
    );

    try {
      _showMessage(widget.isEnglish ? 'Submitting withdrawal request...' : 'กำลังส่งคำขอถอนเงิน...');
      await _transactionController.createTransaction(newTransaction);

      // เพิ่มการแจ้งเตือนลงใน NotificationManager
      final notificationManager = Provider.of<NotificationManager>(context, listen: false);
      // แก้ไขตรงนี้: เรียกใช้ addNotification โดยส่งค่า title และ body โดยตรง
      notificationManager.addNotification(
        title: widget.isEnglish ? 'Withdrawal Request Sent' : 'ส่งคำขอถอนเงินแล้ว',
        body: widget.isEnglish
            ? 'Your withdrawal request for ฿${withdrawalAmount.toStringAsFixed(2)} has been submitted and is pending approval.'
            : 'คำขอถอนเงินจำนวน ฿${withdrawalAmount.toStringAsFixed(2)} ของคุณถูกส่งแล้วและกำลังรอการอนุมัติ',
        payload: 'withdrawal_request_id_${newTransaction.transactionId}', // สามารถเพิ่ม payload เพื่อระบุ transaction
      );

      _showMessage(widget.isEnglish ? 'Withdrawal request submitted successfully!' : 'ส่งคำขอถอนเงินสำเร็จ!');

      // Indicate success and trigger refresh on the previous page (HousekeeperPage)
      Navigator.pop(context, true);
    } catch (e) {
      print('Error requesting withdrawal: $e'); // Log the actual error for debugging
      _showMessage(widget.isEnglish ? 'Failed to submit withdrawal request. Please try again.' : 'ส่งคำขอถอนเงินไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false; // สิ้นสุดสถานะการส่งข้อมูล
        });
      }
    }
  }

  /// Displays a SnackBar message to the user.
  void _showMessage(String message) {
    if (mounted) {
      // Check if the widget is still mounted before showing SnackBar
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Populates the PromPay number field with the user's phone number.
  void _usePhoneNumberAsPromPay() {
    final phoneNumber = widget.user.person?.phoneNumber;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _prompayNumberController.text = phoneNumber;
    } else {
      _showMessage(widget.isEnglish
          ? 'Phone number not available in your profile.'
          : 'ไม่พบเบอร์โทรศัพท์ในข้อมูลโปรไฟล์ของคุณ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () {
            // When pressing back, simply pop. The HousekeeperPage will handle refresh
            // if it was expecting a result (though not strictly necessary for simple back)
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Request Withdrawal' : 'ร้องขอถอนเงิน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // กำหนด key ให้กับ Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish ? 'Available Balance' : 'ยอดเงินคงเหลือ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on,
                              color: Colors.amber, size: 30),
                          const SizedBox(width: 10),
                          Text(
                            '${_currentBalance.toStringAsFixed(2)} ฿', // Display dynamic balance
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Withdrawal Amount Input
              Text(
                widget.isEnglish ? 'Withdrawal Amount' : 'จำนวนเงินที่ต้องการถอน',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField( // เปลี่ยนเป็น TextFormField
                controller: _withdrawalAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')), // Allow digits and up to 2 decimal places
                ],
                decoration: InputDecoration(
                  hintText: widget.isEnglish ? 'Enter amount' : 'กรอกจำนวนเงิน',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isEnglish ? 'Please enter withdrawal amount.' : 'กรุณากรอกจำนวนเงินที่ต้องการถอน';
                  }
                  final double? amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return widget.isEnglish ? 'Amount must be greater than 0.' : 'จำนวนเงินต้องมากกว่า 0';
                  }
                  if (amount > _currentBalance) {
                    return widget.isEnglish ? 'Insufficient balance.' : 'ยอดเงินในบัญชีไม่เพียงพอ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // PromPay Number Input
              Text(
                widget.isEnglish ? 'PromPay Number' : 'เบอร์ PromPay',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField( // เปลี่ยนเป็น TextFormField
                      controller: _prompayNumberController,
                      keyboardType: TextInputType.phone, // Use phone keyboard for phone numbers
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Allow only digits
                      decoration: InputDecoration(
                        hintText: widget.isEnglish
                            ? 'Optional: Enter your PromPay Number'
                            : 'ไม่บังคับ: กรอกเบอร์ PromPay ของท่าน',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                      ),
                      validator: (value) {
                        // ถ้า PromPay ว่าง และ Bank Account ว่าง ให้แจ้งเตือน
                        if ((value == null || value.isEmpty) && _bankAccountNumberController.text.isEmpty) {
                          return widget.isEnglish ? 'Enter PromPay or Bank Account.' : 'กรุณากรอก PromPay หรือเลขที่บัญชีธนาคาร';
                        }
                        // ถ้า PromPay ไม่ว่าง แต่ไม่ใช่ตัวเลข
                        if (value != null && value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return widget.isEnglish ? 'Please enter numbers only.' : 'กรุณากรอกเฉพาะตัวเลข';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10), // Space between TextField and Button
                  ElevatedButton(
                    onPressed: _usePhoneNumberAsPromPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blueAccent, // Choose a suitable color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                    ),
                    child: Text(
                      widget.isEnglish ? 'Use Phone Number' : 'ใช้เบอร์โทรศัพท์',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bank Account Number Input
              Text(
                widget.isEnglish ? 'Bank Account Number' : 'เลขที่บัญชีธนาคาร',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField( // เปลี่ยนเป็น TextFormField
                controller: _bankAccountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ], // Allow only digits
                decoration: InputDecoration(
                  hintText: widget.isEnglish
                      ? 'Optional: Enter your bank account number'
                      : 'ไม่บังคับ: กรอกเลขที่บัญชีธนาคารของท่าน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                validator: (value) {
                  // ถ้า Bank Account ว่าง และ PromPay ว่าง ให้แจ้งเตือน
                  if ((value == null || value.isEmpty) && _prompayNumberController.text.isEmpty) {
                    return widget.isEnglish ? 'Enter PromPay or Bank Account.' : 'กรุณากรอก PromPay หรือเลขที่บัญชีธนาคาร';
                  }
                  // ถ้า Bank Account ไม่ว่าง แต่ไม่ใช่ตัวเลข
                  if (value != null && value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return widget.isEnglish ? 'Please enter numbers only.' : 'กรุณากรอกเฉพาะตัวเลข';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bank Account Name Input
              Text(
                widget.isEnglish ? 'Bank Account Name' : 'ชื่อบัญชีธนาคาร',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField( // เปลี่ยนเป็น TextFormField
                controller: _bankAccountNameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words, // Capitalize words
                decoration: InputDecoration(
                  hintText: widget.isEnglish
                      ? 'Optional: Enter your bank account name'
                      : 'ไม่บังคับ: กรอกชื่อบัญชีธนาคารของท่าน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                validator: (value) {
                  // ถ้าเลขที่บัญชีธนาคารถูกกรอก แต่ชื่อบัญชีว่างเปล่า
                  if (_bankAccountNumberController.text.isNotEmpty && (value == null || value.isEmpty)) {
                    return widget.isEnglish ? 'Please enter bank account name.' : 'กรุณากรอกชื่อบัญชีธนาคาร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Request Withdrawal Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _requestWithdrawal, // Call the withdrawal function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isEnglish ? 'Request Withdrawal' : 'ร้องขอถอนเงิน',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
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
