import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:maebanjumpen/screens/payment_successful_member.dart';
import 'package:provider/provider.dart'; // Import Provider

class DepositQrCodePage extends StatefulWidget {
  final double amount;
  final bool isEnglish;
  final Hirer user;
  // final int transactionId; // *** ลบหรือเปลี่ยนบรรทัดนี้ ***

  const DepositQrCodePage({
    super.key,
    required this.amount,
    required this.isEnglish,
    required this.user,
    // this.transactionId, // *** ไม่จำเป็นต้องรับตรงนี้ ถ้าเราจะรอให้ backend สร้าง ID ให้ ***
  });

  @override
  State<DepositQrCodePage> createState() => _DepositQrCodePageState();
}

class _DepositQrCodePageState extends State<DepositQrCodePage> {
  String? _qrCodeImageBase64;
  bool _isLoading = true;
  String? _errorMessage;
  late String _displayAmount;
  Timer? _pollingTimer;
  bool _paymentConfirmed = false;
  int? _currentTransactionId; // *** เพิ่มตัวแปรนี้เพื่อเก็บ transactionId ที่ได้รับจาก backend ***

  @override
  void initState() {
    super.initState();
    _displayAmount = NumberFormat('#,##0.00').format(widget.amount);
    _generateQrCode();
    // *** _startPollingTransactionStatus จะถูกเรียกใน _generateQrCode() หลังจากได้รับ ID แล้ว ***
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrCodeImageBase64 = null;
      _currentTransactionId = null; // Reset ID when regenerating
    });

    try {
      final TransactionController transactionController = TransactionController();
      print('Sending QR Code Request Body: {"memberId":${widget.user.id},"amount":${widget.amount}}');

      final Map<String, dynamic>? response = await transactionController.createDepositQrCode(
        memberId: widget.user.id!,
        amount: widget.amount,
      );

      print('QR Code API Response Status from TransactionController: ${response != null ? 'OK' : 'null response'}');

      if (response != null && response['qrCodeImageBase64'] != null) {
        _qrCodeImageBase64 = response['qrCodeImageBase64'];
        _currentTransactionId = response['transactionId'] as int?; // *** ดึง transactionId จาก response ของ backend ***
        
        print('Successfully received QR Code Base64 Data. Length: ${_qrCodeImageBase64?.length ?? 0} chars. Transaction ID: $_currentTransactionId');

        if (_qrCodeImageBase64!.length < 100) {
          _errorMessage = widget.isEnglish ? 'Received incomplete QR Code Base64 data.' : 'ได้รับข้อมูล QR Code Base64 ไม่สมบูรณ์';
          print('Warning: Received short Base64 string. Length: ${_qrCodeImageBase64!.length}');
        }

        // *** เริ่ม Polling หลังจากได้รับ transactionId ที่ถูกต้องแล้วเท่านั้น ***
        if (_currentTransactionId != null) {
          _startPollingTransactionStatus();
        } else {
          _errorMessage = widget.isEnglish ? 'Failed to get transaction ID from backend.' : 'ไม่สามารถรับรหัสธุรกรรมจากระบบหลังบ้านได้';
          print('Error: transactionId is null in response from createDepositQrCode.');
        }

      } else {
        _errorMessage = widget.isEnglish ? 'Failed to generate QR Code. Please try again. (No QR Base64 data or transactionId received from backend)' : 'ไม่สามารถสร้าง QR Code ได้ กรุณาลองอีกครั้ง (ไม่ได้รับข้อมูล QR แบบ Base64 หรือรหัสธุรกรรมจาก Backend)';
        print('Error: No QR Code Base64 or transactionId in response from TransactionController: $response');
      }
    } catch (e) {
      _errorMessage = widget.isEnglish ? 'Error: $e' : 'เกิดข้อผิดพลาด: $e';
      print("Error generating QR Code in DepositQrCodePage: $e");
    } finally {
      setState(() {
        _isLoading = false;
        if (_qrCodeImageBase64 == null && _errorMessage == null) {
            _errorMessage = widget.isEnglish ? 'Unknown error during QR Code generation process.' : 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุในระหว่างการสร้าง QR Code';
            print('Fallback Error: _qrCodeImageBase64 is null but no specific error was caught in finally block.');
        }
      });
    }
  }

  void _startPollingTransactionStatus() {
    if (_currentTransactionId == null) { // ป้องกันไม่ให้ polling ถ้าไม่มี transaction ID
      print('Cannot start polling: _currentTransactionId is null. Aborting.');
      return;
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_paymentConfirmed) {
        timer.cancel();
        return;
      }

      try {
        final TransactionController transactionController = TransactionController();
        // ใช้ _currentTransactionId ในการเรียก API
        final Map<String, dynamic>? transactionData = await transactionController.getTransactionStatus(_currentTransactionId!);

        if (transactionData != null && transactionData['transactionStatus'] == 'SUCCESS') {
          setState(() {
            _paymentConfirmed = true;
          });
          _pollingTimer?.cancel();

          // Add notification for successful payment
          final notificationManager = Provider.of<NotificationManager>(context, listen: false);
          notificationManager.addNotification(
            title: widget.isEnglish ? 'Deposit Successful!' : 'เติมเงินสำเร็จ!',
            body: widget.isEnglish
                ? 'Your deposit of ฿${widget.amount.toStringAsFixed(2)} has been successfully processed.'
                : 'คุณได้เติมเงินจำนวน ฿${widget.amount.toStringAsFixed(2)} สำเร็จแล้ว',
            payload: 'deposit_success_${_currentTransactionId}',
            showNow: true,
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentSuccessfulPage(
                amount: widget.amount,
                isEnglish: widget.isEnglish, user: widget.user,
              ),
            ),
          );
        } else if (transactionData != null && transactionData['transactionStatus'] == 'FAILED') {
          _pollingTimer?.cancel();
          setState(() {
            _errorMessage = widget.isEnglish
                ? 'Payment failed. Please try again.'
                : 'การชำระเงินล้มเหลว กรุณาลองใหม่อีกครั้ง';
          });
        } else {
          // Log สถานะปัจจุบันที่ได้รับมา (เช่น PENDING, QR Generated) เพื่อ Debug
          print('Polling: Transaction ID $_currentTransactionId status: ${transactionData?['transactionStatus'] ?? 'Unknown/Null'}');
        }
      } catch (e) {
        print('Error polling transaction status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your existing build method)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            _pollingTimer?.cancel(); // ยกเลิก Timer ก่อนกลับ
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'QR Code' : 'คิวอาร์โค้ด',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _generateQrCode, // ถ้ามี error จะ retry สร้าง QR
                              child: Text(widget.isEnglish ? 'Retry' : 'ลองอีกครั้ง'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isEnglish ? 'Please scan to deposit' : 'กรุณาสแกนเพื่อเติมเงิน',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _qrCodeImageBase64 != null && _qrCodeImageBase64!.isNotEmpty
                                    ? SvgPicture.memory(
                                        base64Decode(_qrCodeImageBase64!),
                                        width: 250.0,
                                        height: 250.0,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (BuildContext context) => Container(
                                              padding: const EdgeInsets.all(20.0),
                                              child: const CircularProgressIndicator(),
                                            ),
                                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                          print('SVG Render Error: $error');
                                          print('SVG Stack Trace: $stackTrace');
                                          print('Problematic Base64 (first 100 chars): ${_qrCodeImageBase64!.substring(0, _qrCodeImageBase64!.length > 100 ? 100 : _qrCodeImageBase64!.length)}');

                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.broken_image, color: Colors.red, size: 50),
                                              const SizedBox(height: 10),
                                              Text(
                                                widget.isEnglish ? 'Error loading QR Code. Please retry.' : 'เกิดข้อผิดพลาดในการโหลด QR Code กรุณาลองใหม่.',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.red, fontSize: 14),
                                              ),
                                              Text(
                                                'Error details: ${error.toString().split('\n').first}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.red, fontSize: 12),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 250.0,
                                        height: 250.0,
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Text(
                                            widget.isEnglish ? 'No QR code data.' : 'ไม่มีข้อมูล QR Code',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 30),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '฿$_displayAmount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.isEnglish ? 'After payment, your balance will be updated automatically within a few minutes.' : 'หลังจากการชำระเงิน ยอดเงินคงเหลือของคุณจะได้รับการอัปเดตอัตโนมัติภายในไม่กี่นาที',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  _pollingTimer?.cancel(); // ยกเลิก Timer ก่อนกลับ
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  widget.isEnglish ? 'Back to Wallet' : 'กลับสู่หน้ากระเป๋าเงิน',
                                  style: const TextStyle(color: Colors.red, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
