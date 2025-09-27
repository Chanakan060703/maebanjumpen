import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/deposit_qr_code_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/controller/memberController.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class DepositMemberPage extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const DepositMemberPage({
    super.key,
    required this.isEnglish,
    required this.user,
  });

  @override
  State<DepositMemberPage> createState() => _DepositMemberPageState();
}

class _DepositMemberPageState extends State<DepositMemberPage> {
  final TextEditingController _customAmountController = TextEditingController();
  double? _selectedAmount;
  late Hirer _currentUser;
  late String _displayBalance;
  bool _isFetchingBalance = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _updateBalanceDisplay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchLatestBalance();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _updateBalanceDisplay() {
    _displayBalance = NumberFormat('#,##0.00').format(_currentUser.balance ?? 0.0);
  }

  Future<void> _fetchLatestBalance() async {
  if (_isFetchingBalance) return;

  // setState() แรกนี้ปลอดภัยเพราะถูกเรียกทันที
  setState(() {
    _isFetchingBalance = true;
  });

  try {
    final MemberController memberController = MemberController();
    final Hirer? latestHirerData = await memberController.getHirerById(widget.user.id!.toString());

    // ✅ เพิ่มการตรวจสอบ `mounted` ที่นี่
    // ถ้า widget ไม่ได้อยู่ใน tree แล้ว จะไม่ทำต่อ
    if (!mounted) return;

    if (latestHirerData != null) {
      setState(() {
        _currentUser = latestHirerData;
        _updateBalanceDisplay();
      });
      print('Balance updated successfully to: ${_currentUser.balance}');
    } else {
      print('Failed to fetch latest hirer data.');
    }
  } catch (e) {
    print('Error fetching latest balance: $e');
    // ✅ เพิ่มการตรวจสอบ `mounted` ที่นี่
    if (!mounted) return;
  } finally {
    // ✅ เพิ่มการตรวจสอบ `mounted` ที่นี่
    if (!mounted) return;
    setState(() {
      _isFetchingBalance = false;
    });
  }
}

  // ฟังก์ชันสำหรับแสดง AwesomeDialog
  void _showErrorDialog({String? title, String? desc}) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      customHeader: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        radius: 40,
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 40),
      ),
      title: title ?? (widget.isEnglish ? 'Oops!' : 'เกิดข้อผิดพลาด'),
      desc: desc ?? (widget.isEnglish ? 'An unexpected error occurred.' : 'เกิดข้อผิดพลาดที่ไม่คาดคิด'),
      btnOkText: widget.isEnglish ? 'OK' : 'ตกลง',
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      descTextStyle: const TextStyle(fontSize: 16),
      buttonsTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ).show();
  }


  void _handleTopUp() async {
    double? amount;
    if (_selectedAmount != null) {
      amount = _selectedAmount;
    } else if (_customAmountController.text.isNotEmpty) {
      amount = double.tryParse(_customAmountController.text);
    }

    if (amount != null && amount > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepositQrCodePage(
            amount: amount!,
            isEnglish: widget.isEnglish,
            user: widget.user,
          ),
        ),
      );
      print('Returned from DepositQrCodePage. Fetching latest balance...');
      _fetchLatestBalance();
    } else {
      _showErrorDialog(
        title: widget.isEnglish ? 'Invalid Amount' : 'จำนวนเงินไม่ถูกต้อง',
        desc: widget.isEnglish ? 'Please enter a valid amount.' : 'กรุณาป้อนจำนวนเงินที่ถูกต้อง',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
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
          widget.isEnglish ? 'Deposit' : 'เติมเงิน',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? 'Available Balance' : 'ยอดเงินคงเหลือ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _isFetchingBalance
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          '฿$_displayBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Quick Top Up
            Text(
              widget.isEnglish ? 'Quick Top Up' : 'เติมเงินด่วน',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                _buildAmountButton(20.0),
                _buildAmountButton(50.0),
                _buildAmountButton(100.0),
                _buildAmountButton(200.0),
                _buildAmountButton(500.0),
                _buildAmountButton(1000.0),
              ],
            ),
            const SizedBox(height: 30),

            // Enter Custom Amount
            Text(
              widget.isEnglish ? 'Enter Custom Amount' : 'ระบุจำนวนเงินเอง',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Enter amount' : 'ป้อนจำนวนเงิน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: const Icon(Icons.attach_money),
              ),
              onChanged: (text) {
                setState(() {
                  _selectedAmount = null;
                });
              },
            ),
            const SizedBox(height: 30),

            // Top Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isEnglish ? 'Top Up' : 'เติมเงิน',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButton(double amount) {
    bool isSelected = _selectedAmount == amount;
    return ChoiceChip(
      label: Text(
        '฿${NumberFormat('#,##0').format(amount)}',
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.red,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.red, width: 1.5),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedAmount = amount;
            _customAmountController.clear();
          } else {
            _selectedAmount = null;
          }
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    );
  }
}