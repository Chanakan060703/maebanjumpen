import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:maebanjumpen/model/account_manager.dart'; // ตรวจสอบว่ามี AccountManager model ที่ถูกต้อง
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:maebanjumpen/screens/home_accountmanager.dart';
import 'package:maebanjumpen/screens/listrequestwithdraw_housekeeper.dart';
import 'package:maebanjumpen/screens/request_withdrawdetail_accountmanager.dart'; // นำเข้าหน้าจอรายละเอียดสำหรับ Account Manager

class ListWithdrawalRequestsScreen extends StatefulWidget {
  final bool isEnglish;
  final AccountManager user; // สำหรับ AccountManager

  const ListWithdrawalRequestsScreen({
    super.key,
    required this.user,
    this.isEnglish = true,
  });

  @override
  State<ListWithdrawalRequestsScreen> createState() =>
      _ListWithdrawalRequestsState();
}

class _ListWithdrawalRequestsState extends State<ListWithdrawalRequestsScreen> {
  late Future<List<Transaction>> _withdrawalRequestsFuture;
  final TransactionController _transactionController = TransactionController();

  @override
  void initState() {
    super.initState();
    _fetchWithdrawalRequests();
  }

  void _fetchWithdrawalRequests() {
    _withdrawalRequestsFuture = _transactionController
        .getAllTransactions()
        .then((transactions) {
          return transactions
              .where(
                (transaction) =>
                    // ตรวจสอบประเภท Transaction
                    (transaction.transactionType?.toLowerCase() == 'withdraw' ||
                        transaction.transactionType?.toLowerCase() ==
                            'withdrawal' ||
                        transaction.transactionType == 'ถอนเงิน') &&
                    // ตรวจสอบสถานะ: Pending Approve เท่านั้น
                    (transaction.transactionStatus?.toLowerCase() ==
                            'pending approve' ||
                        transaction.transactionStatus == 'กำลังรอตรวจสอบ'),
              )
              .toList();
        });
    // ใช้ if (mounted) เพื่อป้องกันการเรียก setState หลัง dispose
    if (mounted) {
      setState(() {});
    }
  }

  /// Navigates to the transaction detail screen for Account Manager.
  void _navigateToTransactionDetailScreen(
    BuildContext context,
    Transaction transaction,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RequestWithdrawDetailAccountManager(
                  transaction: transaction, 
                  isEnglish: widget.isEnglish,
                  transactionController: _transactionController, 
                  accountManagerId: widget.user.id!, // ส่ง ID ของ AccountManager
                ),
      ),
    ).then((result) {
      // เมื่อกลับมาจากหน้าจอรายละเอียด ให้รีเฟรชรายการหากมีการเปลี่ยนแปลง
      if (result == true) {
        _fetchWithdrawalRequests();
      }
    });
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
              builder: (context) => AccountManagerPage(
                isEnglish: widget.isEnglish,
                user: widget.user, // Pass the user object
              ),
            ),
          ),
        ),
        title: Text(
          widget.isEnglish ? 'Withdrawal Requests' : 'รายการคำขอถอนเงิน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _withdrawalRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                widget.isEnglish
                    ? 'Error: ${snapshot.error}'
                    : 'เกิดข้อผิดพลาด: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                widget.isEnglish
                    ? 'No pending withdrawal requests.'
                    : 'ไม่มีคำขอถอนเงินที่รออนุมัติ.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                _fetchWithdrawalRequests();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final transaction = snapshot.data![index];
                  final formattedDate =
                      transaction.transactionDate != null
                          ? DateFormat(
                              widget.isEnglish
                                  ? 'd MMM y, HH:mm'
                                  : 'd MMM y, HH:mm',
                              widget.isEnglish ? 'en_US' : 'th_TH',
                            ).format(transaction.transactionDate!.toLocal())
                          : (widget.isEnglish ? 'N/A Date' : 'ไม่มีวันที่');

                  final String displayStatus =
                      TransactionStatusHelper.getLocalizedStatus(
                        transaction.transactionStatus ?? '',
                        widget.isEnglish,
                      );
                  final Color statusColor =
                      TransactionStatusHelper.getStatusColor(
                        transaction.transactionStatus ?? '',
                      );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: WithdrawalRequestCard(
                      transaction: transaction,
                      formattedDate: formattedDate,
                      displayStatus: displayStatus,
                      statusColor: statusColor,
                      isEnglish: widget.isEnglish,
                      onView: () {
                        _navigateToTransactionDetailScreen(
                          context,
                          transaction,
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class WithdrawalRequestCard extends StatelessWidget {
  final Transaction transaction;
  final String formattedDate;
  final String displayStatus;
  final Color statusColor;
  final bool isEnglish;
  final VoidCallback onView;

  const WithdrawalRequestCard({
    super.key,
    required this.transaction,
    required this.formattedDate,
    required this.displayStatus,
    required this.statusColor,
    required this.isEnglish,
    required this.onView,
  });

  String _getMemberName(bool isEnglish) {
    final firstName = transaction.member?.person?.firstName;
    final lastName = transaction.member?.person?.lastName;
    final memberId = transaction.memberId ?? 'N/A';
    
    // ตรวจสอบว่ามีชื่อจริงอยู่หรือไม่
    if (firstName != null && firstName.isNotEmpty) {
      return '${isEnglish ? 'Name' : 'ชื่อ'} : $firstName ${lastName ?? ''}';
    } else {
      // แสดง Member ID เป็นข้อมูลสำรอง
      return '${isEnglish ? 'Member ID' : 'รหัสสมาชิก'} : $memberId';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // 🚩 แสดงจำนวนเงิน
                        '${transaction.transactionAmount?.toStringAsFixed(2) ?? '0.00'} ฿',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // 🚩 แสดงชื่อสมาชิก/รหัสสมาชิก
                        _getMemberName(isEnglish),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // 🚩 แสดงวันที่
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // 🚩 ปุ่มสำหรับดูรายละเอียด
                ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    isEnglish ? 'View' : 'ดูรายละเอียด',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 🚩 แสดงสถานะ
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}