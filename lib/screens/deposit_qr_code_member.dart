import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:maebanjumpen/screens/payment_failed_member.dart';
import 'package:provider/provider.dart';
import 'package:maebanjumpen/screens/payment_successful_member.dart';

class DepositQrCodePage extends StatefulWidget {
  final double amount;
  final bool isEnglish;
  final Hirer user;

  const DepositQrCodePage({
    super.key,
    required this.amount,
    required this.isEnglish,
    required this.user,
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
  int? _currentTransactionId;

  @override
  void initState() {
    super.initState();
    _displayAmount = NumberFormat('#,##0.00').format(widget.amount);
    _generateQrCode();
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
      _currentTransactionId = null;
    });

    try {
      final TransactionController transactionController =
          TransactionController();
      final Map<String, dynamic>? response = await transactionController
          .createDepositQrCode(
            memberId: widget.user.id!,
            amount: widget.amount,
          );

      if (response != null && response['qrCodeImageBase64'] != null) {
        String base64String = response['qrCodeImageBase64'];

        if (base64String.startsWith('data:image/svg+xml;base64,')) {
          base64String = base64String.substring(
            'data:image/svg+xml;base64,'.length,
          );
        }

        _qrCodeImageBase64 = base64String;
        _currentTransactionId = response['transactionId'] as int?;

        if (_currentTransactionId != null) {
          _startPollingTransactionStatus();
        } else {
          _errorMessage =
              widget.isEnglish
                  ? 'Failed to get transaction ID from backend.'
                  : 'ไม่สามารถรับรหัสธุรกรรมจากระบบหลังบ้านได้';
        }
      } else {
        _errorMessage =
            widget.isEnglish
                ? 'Failed to generate QR Code. Please try again.'
                : 'ไม่สามารถสร้าง QR Code ได้ กรุณาลองอีกครั้ง';
      }
    } catch (e) {
      _errorMessage = widget.isEnglish ? 'Error: $e' : 'เกิดข้อผิดพลาด: $e';
    } finally {
      setState(() {
        _isLoading = false;
        if (_qrCodeImageBase64 == null && _errorMessage == null) {
          _errorMessage =
              widget.isEnglish
                  ? 'Unknown error.'
                  : 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
        }
      });
    }
  }

  void _startPollingTransactionStatus() {
    if (_currentTransactionId == null) {
      return;
    }
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_paymentConfirmed) {
        timer.cancel();
        return;
      }
      try {
        final TransactionController transactionController =
            TransactionController();
        final Map<String, dynamic>? transactionData =
            await transactionController.getTransactionStatus(
          _currentTransactionId!,
        );

        if (transactionData != null) {
          final String status = transactionData['transactionStatus'];
          if (status == 'SUCCESS') {
            setState(() {
              _paymentConfirmed = true;
            });
            _pollingTimer?.cancel();
            final notificationManager = Provider.of<NotificationManager>(
              context,
              listen: false,
            );
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
                  isEnglish: widget.isEnglish,
                  user: widget.user,
                ),
              ),
            );
          } else if (status == 'FAILED') {
            _pollingTimer?.cancel();
            // เมื่อสถานะเป็น FAILED, ให้แสดงหน้าจอ PaymentFailedPage
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PaymentFailedPage(
                  isEnglish: widget.isEnglish,
                  user: widget.user,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error polling transaction status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            _pollingTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'QR Code' : 'คิวอาร์โค้ด',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _generateQrCode,
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
                          widget.isEnglish
                              ? 'Please scan to deposit'
                              : 'กรุณาสแกนเพื่อเติมเงิน',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                          child:
                              _qrCodeImageBase64 != null && _qrCodeImageBase64!.isNotEmpty
                                  ? SizedBox(
                                      width: 250.0,
                                      height: 250.0,
                                      child: SvgPicture.memory(
                                          Base64Decoder().convert(_qrCodeImageBase64!),
                                      ),
                                    )
                                  : Container(
                                      width: 250.0,
                                      height: 250.0,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: Text(
                                          widget.isEnglish
                                              ? 'No QR code data.'
                                              : 'ไม่มีข้อมูล QR Code',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
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
                          widget.isEnglish
                              ? 'After payment, your balance will be updated automatically within a few minutes.'
                              : 'หลังจากการชำระเงิน ยอดเงินคงเหลือของคุณจะได้รับการอัปเดตอัตโนมัติภายในไม่กี่นาที',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            _pollingTimer?.cancel();
                            Navigator.pop(context);
                          },
                          child: Text(
                            widget.isEnglish
                                ? 'Back to Wallet'
                                : 'กลับสู่หน้ากระเป๋าเงิน',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
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