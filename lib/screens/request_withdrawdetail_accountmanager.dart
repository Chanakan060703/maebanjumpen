import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:intl/intl.dart'; // สำหรับการจัดรูปแบบวันที่

class RequestWithdrawDetailAccountManager extends StatefulWidget {
  final Transaction transaction;
  final bool isEnglish;
  final TransactionController transactionController; // ส่ง controller มาเพื่ออัปเดตสถานะ

  const RequestWithdrawDetailAccountManager({
    super.key,
    required this.transaction,
    required this.isEnglish,
    required this.transactionController,
  });

  @override
  State<RequestWithdrawDetailAccountManager> createState() =>
      _RequestWithdrawDetailAccountManagerState();
}

class _RequestWithdrawDetailAccountManagerState
    extends State<RequestWithdrawDetailAccountManager> {
  // ใช้ตัวแปร local เพื่อสะท้อนสถานะที่อาจมีการเปลี่ยนแปลง
  late Transaction _currentTransaction;

  // *** เพิ่มตัวแปรสำหรับ Account Manager ID ***
  // คุณต้องนำค่า accountManagerId ที่ถูกต้องมาจากระบบ (เช่น จากการ Login)
  // นี่คือตัวอย่าง สมมติว่า ID คือ 123
  final int _accountManagerId = 1; // *** โปรดเปลี่ยนค่านี้เป็น ID ของ Account Manager จริงๆ ที่เข้าสู่ระบบอยู่ ***

  // State variables to control visibility of full numbers
  bool _showFullPromPay = false;
  bool _showFullBankAccount = false;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  /// Helper เพื่อรับสตริงสถานะที่แปลแล้ว
  String _getLocalizedStatus(String? status, bool isEnglish) {
    if (status == null) return isEnglish ? 'Unknown' : 'ไม่ทราบสถานะ';
    if (isEnglish) {
      return status;
    } else {
      switch (status.toLowerCase()) {
        case 'pending approve':
          return 'กำลังรอตรวจสอบ';
        case 'approved':
          return 'อนุมัติแล้ว';
        case 'rejected':
          return 'ถูกปฏิเสธ';
        case 'completed':
          return 'เสร็จสิ้น';
        default:
          return 'ไม่ทราบสถานะ';
      }
    }
  }

  /// Helper เพื่อรับสีของสถานะ
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.toLowerCase() == 'pending approve' ||
        status.toLowerCase() == 'กำลังรอตรวจสอบ') {
      return Colors.orange;
    } else if (status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'เสร็จสิ้น' ||
        status.toLowerCase() == 'completed') {
      return Colors.green;
    } else if (status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'ถูกปฏิเสธ') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  Future<void> _updateTransactionStatus(String newStatus) async {
    if (_currentTransaction.transactionId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Transaction ID is missing.'
                  : 'ไม่พบรหัสธุรกรรม.')),
        );
      }
      return;
    }

    try {
      // *** เปลี่ยนมาเรียกใช้เมธอด updateTransactionStatus ของ controller ***
      // โดยส่ง transactionId, newStatus, และ accountManagerId ไปด้วย
      bool success = await widget.transactionController.updateTransactionStatus(
        _currentTransaction.transactionId!,
        newStatus,
        _accountManagerId, // ส่ง accountManagerId ที่ได้มาจากที่อื่น
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isEnglish
                    ? 'Transaction status updated to ${_getLocalizedStatus(newStatus, widget.isEnglish)}!'
                    : 'อัปเดตสถานะธุรกรรมเป็น ${_getLocalizedStatus(newStatus, widget.isEnglish)} แล้ว!')),
          );
          // อัปเดตสถานะธุรกรรมใน local และสร้าง UI ใหม่
          setState(() {
            _currentTransaction = _currentTransaction.copyWith(
              transactionStatus: newStatus,
              // Backend จะตั้งค่า transactionApprovalDate เองเมื่อสถานะเปลี่ยนเป็น Approved
              // แต่เราอัปเดตใน UI ด้วย เพื่อให้ UI แสดงผลทันที
              transactionApprovalDate: newStatus == 'Approved' ? DateTime.now() : _currentTransaction.transactionApprovalDate,
            );
          });
          // กลับไปยังหน้าก่อนหน้าพร้อมสัญญาณว่ามีการอัปเดตสำเร็จ
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isEnglish
                    ? 'Failed to update transaction status.'
                    : 'อัปเดตสถานะธุรกรรมไม่สำเร็จ.')),
          );
        }
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'An error occurred: $e'
                  : 'เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดค่า requestType ให้เป็น "Withdrawal" หรือ "ถอนเงิน" เท่านั้น
    // เนื่องจาก UI นี้ใช้สำหรับ "Withdrawal" request เท่านั้น
    final String requestType = widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน';

    final String memberName =
        '${_currentTransaction.member?.person?.firstName ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')} ${_currentTransaction.member?.person?.lastName ?? ''}';
    final int? memberId = _currentTransaction.member?.id;

    // ดึงข้อมูล PromPay, Account Number, Account Name จาก transaction ที่ถูกต้อง
    final String prompayNumber = _currentTransaction.prompayNumber ?? '';
    final String bankAccountNumber = _currentTransaction.bankAccountNumber ?? '';
    final String bankAccountName = _currentTransaction.bankAccountName ?? '';

    // ปรับการซ่อนบางส่วนของ PromPay และ Account Number ให้สอดคล้องกัน
    String maskedPromPay = prompayNumber;
    if (prompayNumber.isNotEmpty && prompayNumber.length > 4) {
      maskedPromPay = '****${prompayNumber.substring(prompayNumber.length - 4)}'; // ซ่อน 4 ตัวแรก
    } else if (prompayNumber.isEmpty) {
      maskedPromPay = widget.isEnglish ? 'N/A' : 'ไม่มี';
    }

    String maskedAccountNumber = bankAccountNumber;
    if (bankAccountNumber.isNotEmpty && bankAccountNumber.length > 4) {
      maskedAccountNumber = '****${bankAccountNumber.substring(bankAccountNumber.length - 4)}'; // ซ่อน 4 ตัวแรก
    } else if (bankAccountNumber.isEmpty) {
      maskedAccountNumber = widget.isEnglish ? 'N/A' : 'ไม่มี';
    }

    final String requestTime = _currentTransaction.transactionDate != null
        ? DateFormat(
            widget.isEnglish ? 'd MMM y, HH:mm' : 'd MMM y, HH:mm',
            widget.isEnglish ? 'en_US' : 'th_TH',
          ).format(_currentTransaction.transactionDate!.toLocal())
        : (widget.isEnglish ? 'N/A' : 'ไม่มี');


    final bool isPendingApprove =
        _currentTransaction.transactionStatus?.toLowerCase() == 'pending approve' ||
        _currentTransaction.transactionStatus == 'กำลังรอตรวจสอบ';

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Withdrawal Request Details' : 'รายละเอียดคำขอถอนเงิน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Details Card
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          // Use a fallback if transaction.member.person.pictureUrl is null or empty
                          backgroundImage: (_currentTransaction.member?.person?.pictureUrl != null && _currentTransaction.member!.person!.pictureUrl!.isNotEmpty)
                              ? NetworkImage(_currentTransaction.member!.person!.pictureUrl!)
                              : const AssetImage('assets/placeholder_avatar.png') as ImageProvider, // รูปภาพ placeholder
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memberName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isEnglish ? 'Housekeeper' : 'แม่บ้าน',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              // แสดง Member ID
                              Text(
                                '${widget.isEnglish ? 'ID' : 'รหัส'}: ${memberId ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Display amount prominently
                              Text(
                                '${_currentTransaction.transactionAmount?.toStringAsFixed(2) ?? '0.00'} ฿',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1, color: Colors.grey),
                    _buildDetailRow(
                        widget.isEnglish ? 'Request Type' : 'ประเภทคำขอ',
                        requestType),
                    // PromPay Number with View/Hide button
                    _buildSensitiveDetailRow(
                      widget.isEnglish ? 'PromPay' : 'พร้อมเพย์',
                      prompayNumber,
                      maskedPromPay,
                      _showFullPromPay,
                      () {
                        setState(() {
                          _showFullPromPay = !_showFullPromPay;
                        });
                      },
                    ),
                    // Bank Account Number with View/Hide button
                    _buildSensitiveDetailRow(
                      widget.isEnglish ? 'Account Number' : 'เลขบัญชี',
                      bankAccountNumber,
                      maskedAccountNumber,
                      _showFullBankAccount,
                      () {
                        setState(() {
                          _showFullBankAccount = !_showFullBankAccount;
                        });
                      },
                    ),
                    _buildDetailRow(
                        widget.isEnglish ? 'Account Name' : 'ชื่อบัญชี',
                        bankAccountName.isEmpty ? (widget.isEnglish ? 'N/A' : 'ไม่มี') : bankAccountName),
                    _buildDetailRow(
                        widget.isEnglish ? 'Request Time' : 'เวลาที่ร้องขอ',
                        requestTime),
                    _buildDetailRow(
                        widget.isEnglish ? 'Processing Time' : 'เวลาดำเนินการ',
                        widget.isEnglish
                            ? '1-2 business days'
                            : '1-2 วันทำการ'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isEnglish ? 'Status' : 'สถานะ',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentTransaction.transactionStatus)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getLocalizedStatus(_currentTransaction.transactionStatus, widget.isEnglish),
                            style: TextStyle(
                              color: _getStatusColor(_currentTransaction.transactionStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons: Reject and Approve (แสดงเฉพาะเมื่อสถานะเป็น "Pending Approve")
            if (isPendingApprove)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateTransactionStatus('Rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        widget.isEnglish ? 'Reject' : 'ปฏิเสธ',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateTransactionStatus('Approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        widget.isEnglish ? 'Approve' : 'อนุมัติ',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างแถวแสดงรายละเอียด (หัวข้อ: ค่า)
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          Expanded(
            // ใช้ expanded เพื่อให้ค่าสามารถขึ้นบรรทัดใหม่ได้
            child: Text(
              value,
              textAlign: TextAlign.right, // จัดค่าให้อยู่ทางขวา
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // อนุญาตให้ค่าขึ้นบรรทัดใหม่ได้ 2 บรรทัด
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับสร้างแถวแสดงรายละเอียดที่มีปุ่ม View/Hide
  Widget _buildSensitiveDetailRow(String title, String fullValue, String maskedValue, bool isShowingFull, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    isShowingFull ? fullValue : maskedValue,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (fullValue.isNotEmpty) // แสดงปุ่มเฉพาะเมื่อมีข้อมูล
                  IconButton(
                    icon: Icon(
                      isShowingFull ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: onToggle,
                    tooltip: isShowingFull ? (widget.isEnglish ? 'Hide' : 'ซ่อน') : (widget.isEnglish ? 'View' : 'ดู'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
