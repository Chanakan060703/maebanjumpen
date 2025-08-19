import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/deposit_qr_code_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/controller/memberController.dart'; 

class CardpageMember extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const CardpageMember({
    super.key,
    required this.isEnglish,
    required this.user,
  });

  @override
  State<CardpageMember> createState() => _CardpageMemberState();
}

class _CardpageMemberState extends State<CardpageMember> {

  final TextEditingController _customAmountController = TextEditingController();
  double? _selectedAmount; // เก็บจำนวนเงินที่ถูกเลือกจากปุ่ม Quick Top Up

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


  void _updateBalanceDisplay() {
    _displayBalance = NumberFormat('#,##0.00').format(_currentUser.balance ?? 0.0);
  }

  // *** เพิ่ม Method นี้เพื่อดึง Balance ล่าสุดจาก Backend ***
  Future<void> _fetchLatestBalance() async {
    if (_isFetchingBalance) return; // ป้องกันการเรียกซ้ำซ้อน

    setState(() {
      _isFetchingBalance = true;
    });

    try {
      final MemberController memberController = MemberController();
      // สมมติว่า memberController มี method สำหรับดึงข้อมูล Hirer ล่าสุด
      // และคุณมี ID ของ Hirer อยู่ใน widget.user.id
      // คุณอาจจะต้องส่ง token หรือ session ID ไปด้วย
      final Hirer? latestHirerData = await memberController.getHirerById(widget.user.id!.toString()); // *** เปลี่ยนตาม method ใน MemberController ของคุณ ***

      if (latestHirerData != null) {
        setState(() {
          _currentUser = latestHirerData; // อัปเดต user object ทั้งหมด
          _updateBalanceDisplay(); // อัปเดตการแสดงผล balance
        });
        print('Balance updated successfully to: ${_currentUser.balance}');
      } else {
        print('Failed to fetch latest hirer data.');
      }
    } catch (e) {
      print('Error fetching latest balance: $e');
      // อาจจะแสดง Snackbar บอกผู้ใช้ว่าโหลดข้อมูลไม่สำเร็จ
    } finally {
      setState(() {
        _isFetchingBalance = false;
      });
    }
  }

  void _handleTopUp() async { // *** เพิ่ม async ตรงนี้ ***
    double? amount;
    if (_selectedAmount != null) {
      amount = _selectedAmount;
    } else if (_customAmountController.text.isNotEmpty) {
      amount = double.tryParse(_customAmountController.text);
    }

    if (amount != null && amount > 0) {
      // Navigate to QR Code page with the selected amount
      // *** ใช้ await เพื่อรอจนกว่า DepositQrCodePage จะ pop กลับมา ***
      await Navigator.push( // เพิ่ม await ตรงนี้
        context,
        MaterialPageRoute(
          builder: (context) => DepositQrCodePage(
            amount: amount!,
            isEnglish: widget.isEnglish,
            user: widget.user,
          ),
        ),
      );

      // *** เมื่อ DepositQrCodePage pop กลับมา (ไม่ว่าจะเป็นจาก PaymentSuccessfulPage
      // หรือกดปุ่ม back ใน DepositQrCodePage เอง) ให้เรียกโหลด balance ใหม่
      print('Returned from DepositQrCodePage. Fetching latest balance...');
      _fetchLatestBalance(); // เรียกโหลด balance ล่าสุดอีกครั้ง

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'Please enter a valid amount.' : 'กรุณาป้อนจำนวนเงินที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
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
                  // *** แสดง loading indicator หรือ balance ***
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
              spacing: 10.0, // horizontal space between buttons
              runSpacing: 10.0, // vertical space between lines of buttons
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
                // Clear selected amount when user types in custom amount field
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
                  backgroundColor: Colors.red, // Background color
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
            _customAmountController.clear(); // Clear custom amount when quick top up is selected
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