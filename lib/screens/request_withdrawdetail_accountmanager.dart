import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:intl/intl.dart'; // For date formatting (สำหรับการจัดรูปแบบวันที่)

class RequestWithdrawDetailAccountManager extends StatefulWidget {
  final Transaction transaction;
  final bool isEnglish; // ตัวกำหนดภาษา
  final TransactionController transactionController; // ส่ง controller มาเพื่ออัปเดตสถานะ
  final int? accountManagerId; // 🚨 เพิ่ม: พารามิเตอร์สำหรับรับ Account Manager ID

  const RequestWithdrawDetailAccountManager({
    super.key,
    required this.transaction,
    required this.isEnglish,
    required this.transactionController,
    this.accountManagerId, // 🚨 ต้องรับค่านี้มาจาก ListWithdrawalRequestsScreen
  });

  @override
  State<RequestWithdrawDetailAccountManager> createState() =>
      _RequestWithdrawDetailAccountManagerState();
}

class _RequestWithdrawDetailAccountManagerState
    extends State<RequestWithdrawDetailAccountManager> {
  // Use a local variable to reflect the state that might change
  // ใช้ตัวแปร local เพื่อสะท้อนสถานะที่อาจมีการเปลี่ยนแปลง
  late Transaction _currentTransaction;

  // State variables to control visibility of full numbers
  // ตัวแปรสถานะเพื่อควบคุมการแสดง/ซ่อนหมายเลขเต็ม
  bool _showFullPromPay = false;
  bool _showFullBankAccount = false;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  /// Helper to get the localized status string
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

  /// Helper to get the status color
  /// Helper เพื่อรับสีของสถานะ
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus == 'pending approve' || lowerStatus == 'กำลังรอตรวจสอบ') {
      return Colors.orange;
    } else if (lowerStatus == 'approved' ||
        lowerStatus == 'เสร็จสิ้น' ||
        lowerStatus == 'completed') {
      return Colors.green;
    } else if (lowerStatus == 'rejected' || lowerStatus == 'ถูกปฏิเสธ') {
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
    
    // 🚨 Check Account Manager ID first
    // 🚨 ตรวจสอบ Account Manager ID ก่อน
    if (widget.accountManagerId == null) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isEnglish
                  ? 'Account Manager ID is missing. Cannot approve/reject.'
                  : 'ไม่พบรหัสผู้ดูแลบัญชี ไม่สามารถดำเนินการได้.')),
        );
      }
      return;
    }

    try {
      // *** Call the updateTransactionStatus method of the controller ***
      // *** เรียกใช้เมธอด updateTransactionStatus ของ controller ***
      bool success = await widget.transactionController.updateTransactionStatus(
        _currentTransaction.transactionId!,
        newStatus,
        widget.accountManagerId!, // 🚨 Use the passed widget.accountManagerId
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isEnglish
                    ? 'Transaction status updated to ${_getLocalizedStatus(newStatus, widget.isEnglish)}!'
                    : 'อัปเดตสถานะธุรกรรมเป็น ${_getLocalizedStatus(newStatus, widget.isEnglish)} แล้ว!')),
          );
          // Update the local transaction status and rebuild the UI
          // อัปเดตสถานะธุรกรรมใน local และสร้าง UI ใหม่
          setState(() {
            _currentTransaction = _currentTransaction.copyWith(
              transactionStatus: newStatus,
              // Update the approval date when the status changes to Approved
              // อัปเดตวันที่อนุมัติเมื่อสถานะเปลี่ยนเป็น Approved
              transactionApprovalDate: newStatus == 'Approved' 
                ? DateTime.now() 
                : _currentTransaction.transactionApprovalDate,
            );
          });
          // Return to the previous screen with a signal that the update was successful
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
    // Set requestType to "Withdrawal" or "ถอนเงิน" only
    // กำหนดค่า requestType ให้เป็น "Withdrawal" หรือ "ถอนเงิน" เท่านั้น
    final String requestType = widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน';

    final String memberName =
        '${_currentTransaction.member?.person?.firstName ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')} ${_currentTransaction.member?.person?.lastName ?? ''}';
    final int? memberId = _currentTransaction.member?.id;

    // Fetch PromPay, Account Number, Account Name from the transaction
    // ดึงข้อมูล PromPay, Account Number, Account Name จาก transaction
    final String prompayNumber = _currentTransaction.prompayNumber ?? '';
    final String bankAccountNumber = _currentTransaction.bankAccountNumber ?? '';
    final String bankAccountName = _currentTransaction.bankAccountName ?? '';

    // Adjust masking for PromPay and Account Number
    // ปรับการซ่อนบางส่วนของ PromPay และ Account Number
    String maskedPromPay = prompayNumber;
    if (prompayNumber.isNotEmpty && prompayNumber.length > 4) {
      // Hide numbers except for the last 4 digits
      // ซ่อนตัวเลขยกเว้น 4 ตัวสุดท้าย
      maskedPromPay = '****${prompayNumber.substring(prompayNumber.length - 4)}'; 
    } else if (prompayNumber.isEmpty) {
      maskedPromPay = widget.isEnglish ? 'N/A' : 'ไม่มี';
    }

    String maskedAccountNumber = bankAccountNumber;
    if (bankAccountNumber.isNotEmpty && bankAccountNumber.length > 4) {
      // Hide numbers except for the last 4 digits
      // ซ่อนตัวเลขยกเว้น 4 ตัวสุดท้าย
      maskedAccountNumber = '****${bankAccountNumber.substring(bankAccountNumber.length - 4)}'; 
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
            // การ์ดรายละเอียดหลัก
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
                          // ใช้รูปภาพสำรองหาก transaction.member.person.pictureUrl เป็นค่าว่างหรือไม่ถูกต้อง
                          backgroundImage: (_currentTransaction.member?.person?.pictureUrl != null && _currentTransaction.member!.person!.pictureUrl!.isNotEmpty)
                              ? NetworkImage(_currentTransaction.member!.person!.pictureUrl!)
                              : const AssetImage('assets/placeholder_avatar.png') as ImageProvider, // Placeholder image (รูปภาพ placeholder)
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
                              // Display Member ID (แสดง Member ID)
                              Text(
                                '${widget.isEnglish ? 'ID' : 'รหัส'}: ${memberId ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Display amount prominently (แสดงจำนวนเงินเด่นๆ)
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
                    // หมายเลขพร้อมเพย์พร้อมปุ่มดู/ซ่อน
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
                    // หมายเลขบัญชีธนาคารพร้อมปุ่มดู/ซ่อน
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

            // Buttons: Reject and Approve (Show only when status is "Pending Approve")
            // ปุ่ม: ปฏิเสธและอนุมัติ (แสดงเฉพาะเมื่อสถานะเป็น "กำลังรอตรวจสอบ")
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

  // Helper Widget for creating detail rows (Title: Value)
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
            // Use Expanded to allow the value to wrap lines
            // ใช้ expanded เพื่อให้ค่าสามารถขึ้นบรรทัดใหม่ได้
            child: Text(
              value,
              textAlign: TextAlign.right, // Align value to the right (จัดค่าให้อยู่ทางขวา)
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow up to 2 lines for the value (อนุญาตให้ค่าขึ้นบรรทัดใหม่ได้ 2 บรรทัด)
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for creating detail rows with a View/Hide button
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
                if (fullValue.isNotEmpty) // Show button only if data exists (แสดงปุ่มเฉพาะเมื่อมีข้อมูล)
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