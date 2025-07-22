import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/transactionController.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:maebanjumpen/model/account_manager.dart'; // ตรวจสอบว่ามี AccountManager model ที่ถูกต้อง
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:maebanjumpen/screens/home_accountmanager.dart';
import 'package:maebanjumpen/screens/request_withdrawdetail_accountmanager.dart'; // นำเข้าหน้าจอรายละเอียดสำหรับ Account Manager


class TransactionStatusHelper {
  static String getLocalizedStatus(String status, bool isEnglish) {
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

  static Color getStatusColor(String status) {
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
}

// ---
// ## ListWithdrawalRequestsScreen
// หน้าจอสำหรับแสดงรายการคำขอถอนเงินของ Account Manager
// ---
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

  /// Fetches withdrawal requests that are of 'withdraw' type and 'Pending Approve' status.
  void _fetchWithdrawalRequests() {
    _withdrawalRequestsFuture = _transactionController
        .getAllTransactions()
        .then((transactions) {
          return transactions
              .where(
                (transaction) =>
                    (transaction.transactionType?.toLowerCase() == 'withdraw' ||
                        transaction.transactionType?.toLowerCase() ==
                            'withdrawal' ||
                        transaction.transactionType == 'ถอนเงิน') &&
                    (transaction.transactionStatus?.toLowerCase() ==
                            'pending approve' ||
                        transaction.transactionStatus == 'กำลังรอตรวจสอบ'),
              )
              .toList();
        });
    if (mounted) {
      setState(() {});
    }
  }

  /// Navigates to the transaction detail screen for Account Manager.
  /// This screen allows Account Manager to approve or reject the request.
  void _navigateToTransactionDetailScreen(
    BuildContext context,
    Transaction transaction,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RequestWithdrawDetailAccountManager(
              // ใช้หน้าจอสำหรับ Account Manager
              transaction: transaction, // ส่ง transaction object เข้าไป
              isEnglish: widget.isEnglish,
              transactionController:
                  _transactionController, // ส่ง AccountManager user เข้าไป
            ),
      ),
    ).then((result) {
      // เมื่อกลับมาจากหน้าจอรายละเอียด ให้รีเฟรชรายการ
      // result อาจจะเป็น true ถ้ามีการอนุมัติ/ปฏิเสธและต้องการให้รีเฟรช
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
                        // เมื่อกดดู ให้ไปที่หน้า RequestWithdrawDetailAccountManager
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

// ---
// ## Withdrawal Request Card Widget
// This stateless widget displays a single withdrawal request in a card format.
// ---
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
                        '${transaction.transactionAmount?.toStringAsFixed(2) ?? '0.00'} ฿',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // ตรวจสอบให้แน่ใจว่า member และ person ใน transaction มีข้อมูล
                        '${isEnglish ? 'Name' : 'ชื่อ'} : ${transaction.member?.person?.firstName ?? 'N/A'} ${transaction.member?.person?.lastName ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
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
                // แสดงเฉพาะปุ่ม View
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
