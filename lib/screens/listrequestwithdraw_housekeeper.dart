import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/controller/transactionController.dart'; 
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/transaction.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart'; 
import 'package:provider/provider.dart'; 


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
        case 'pending payment': // เพิ่มสถานะนี้ถ้ามีในระบบของคุณ
          return 'รอชำระเงิน';
        case 'failed': // เพิ่มสถานะนี้ถ้ามีในระบบของคุณ
          return 'ล้มเหลว';
        case 'qr generated': // เพิ่มสถานะนี้ถ้ามีในระบบของคุณ
          return 'สร้าง QR แล้ว';
        default:
          return 'ไม่ทราบสถานะ';
      }
    }
  }

  static Color getStatusColor(String status) {
    if (status.toLowerCase() == 'pending approve' ||
        status.toLowerCase() == 'กำลังรอตรวจสอบ' ||
        status.toLowerCase() == 'pending payment' ||
        status.toLowerCase() == 'รอชำระเงิน' ||
        status.toLowerCase() == 'qr generated' ||
        status.toLowerCase() == 'สร้าง qr แล้ว') {
      return Colors.orange;
    } else if (status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'อนุมัติแล้ว' ||
        status.toLowerCase() == 'เสร็จสิ้น' ||
        status.toLowerCase() == 'completed') {
      return Colors.green;
    } else if (status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'ถูกปฏิเสธ' ||
        status.toLowerCase() == 'failed' ||
        status.toLowerCase() == 'ล้มเหลว') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}

// ---
// ## ListRequestsWithdrawalScreen
// หน้าจอสำหรับแสดงรายการคำขอถอนเงินของแม่บ้าน
// ---
class ListRequestsWithdrawalScreen extends StatefulWidget {
  final Housekeeper user; // รับ user object
  final bool isEnglish;

  const ListRequestsWithdrawalScreen({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  State<ListRequestsWithdrawalScreen> createState() =>
      _ListRequestsWithdrawalScreenState();
}

class _ListRequestsWithdrawalScreenState
    extends State<ListRequestsWithdrawalScreen> {
  final TransactionController _transactionController = TransactionController();
  List<Transaction> _withdrawalRequests =
      []; // List to store withdrawal transactions
  List<Transaction> _previousWithdrawalRequests = []; // สำหรับเก็บสถานะก่อนหน้า
  bool _isLoading = true;
  String? _errorMessage;

  // ไม่ต้องใช้ _notifiedEventKeys ที่นี่แล้ว เพราะจะย้ายไปจัดการใน NotificationManager
  // final Set<String> _notifiedEventKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchWithdrawalRequests(); // Fetch data when the screen initializes
  }

  /// Fetches withdrawal requests for the current user.
  Future<void> _fetchWithdrawalRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // เก็บสถานะปัจจุบันก่อนดึงข้อมูลใหม่
      _previousWithdrawalRequests = List.from(_withdrawalRequests);

      // Fetch all transactions for the current user (housekeeper)
      final List<Transaction> transactions = await _transactionController
          .getTransactionsByMemberId(widget.user.id!);

      if (mounted) {
        setState(() {
          // Filter only 'withdraw' type transactions based on English or Thai values
          _withdrawalRequests =
              transactions
                  .where(
                    (t) =>
                        t.transactionType?.toLowerCase() == 'withdrawal' || // 'Withdrawal' เป็นค่าที่ Spring ส่งมา
                        t.transactionType?.toLowerCase() == 'ถอนเงิน', // 'ถอนเงิน' เป็นค่าภาษาไทย
                  )
                  .toList();
          // Optionally sort by date, newest first
          _withdrawalRequests.sort(
            (a, b) => b.transactionDate!.compareTo(a.transactionDate!),
          );
          _isLoading = false;
        });

        // ตรวจสอบการเปลี่ยนแปลงสถานะและส่งแจ้งเตือน
        _checkAndNotifyStatusChanges();
      }
    } catch (e) {
      print('Error fetching withdrawal requests: $e'); // ใช้ print เพื่อ Debug
      if (mounted) {
        setState(() {
          _errorMessage =
              widget.isEnglish
                  ? 'No withdrawal requests found.'
                  : 'ไม่พบรายการคำขอถอนเงิน';
          _isLoading = false;
        });
      }
    }
  }

  /// Checks for status changes between current and previous withdrawal requests
  /// and sends notifications if changes are detected.
  void _checkAndNotifyStatusChanges() {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

    for (final newTransaction in _withdrawalRequests) {
      final oldTransaction = _previousWithdrawalRequests.firstWhereOrNull(
        (t) => t.transactionId == newTransaction.transactionId,
      );

      // สร้าง eventKey ที่ไม่ซ้ำกันสำหรับสถานะใหม่ของแต่ละ transaction
      final String eventKey = 'withdrawal_status_change_${newTransaction.transactionId}_${newTransaction.transactionStatus}';

      if (oldTransaction != null &&
          oldTransaction.transactionStatus != newTransaction.transactionStatus) {
        // สถานะมีการเปลี่ยนแปลง, ส่งแจ้งเตือน
        // ไม่ต้องใช้ _notifiedEventKeys.add(eventKey) ที่นี่แล้ว
        final String oldStatusLocalized = TransactionStatusHelper.getLocalizedStatus(oldTransaction.transactionStatus ?? '', widget.isEnglish);
        final String newStatusLocalized = TransactionStatusHelper.getLocalizedStatus(newTransaction.transactionStatus ?? '', widget.isEnglish);

        notificationManager.addNotification(
          title: widget.isEnglish ? 'Withdrawal Status Updated!' : 'สถานะคำขอถอนเงินอัปเดตแล้ว!',
          body: widget.isEnglish
              ? 'Your withdrawal request for ฿${newTransaction.transactionAmount?.toStringAsFixed(2)} has changed from "$oldStatusLocalized" to "$newStatusLocalized".'
              : 'คำขอถอนเงินจำนวน ฿${newTransaction.transactionAmount?.toStringAsFixed(2)} ของคุณเปลี่ยนสถานะจาก "$oldStatusLocalized" เป็น "$newStatusLocalized" แล้ว',
          payload: 'withdrawal_status_update_${newTransaction.transactionId}',
          showNow: true,
          eventKey: eventKey, // ส่ง eventKey ไปที่ NotificationManager
        );
      }
    }
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
              builder: (context) => HousekeeperPage(
                isEnglish: widget.isEnglish,
                user: widget.user, // Pass the user object
              ),
            ),
          ),
        ),
        title: Text(
          widget.isEnglish
              ? 'Withdrawal Requests History'
              : 'ประวัติคำขอถอนเงิน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchWithdrawalRequests,
                          child: Text(widget.isEnglish ? 'Retry' : 'ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              : _withdrawalRequests.isEmpty
                  ? Center(
                      child: Text(
                        widget.isEnglish
                            ? 'No withdrawal requests found.'
                            : 'ไม่พบรายการคำขอถอนเงิน.',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchWithdrawalRequests, // Enable pull-to-refresh
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _withdrawalRequests.length,
                        itemBuilder: (context, index) {
                          final transaction = _withdrawalRequests[index];
                          // Format date for display using intl package for better readability
                          final formattedDate =
                              transaction.transactionDate != null
                                  ? DateFormat(
                                          widget.isEnglish ? 'd MMM y, HH:mm' : 'd MMM y, HH:mm',
                                          widget.isEnglish ? 'en_US' : 'th_TH',
                                        ).format(transaction.transactionDate!.toLocal()) // ใช้ toLocal()
                                  : (widget.isEnglish ? 'N/A Date' : 'ไม่มีวันที่');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: WithdrawalRequestCard(
                              amount:
                                  transaction.transactionAmount?.toStringAsFixed(2) ??
                                  '0.00',
                              name:
                                  transaction.member?.person?.firstName ??
                                  (widget.isEnglish
                                      ? 'N/A Name'
                                      : 'ไม่มีชื่อ'), // Display member's first name
                              date: formattedDate,
                              status:
                                  transaction.transactionStatus ??
                                  (widget.isEnglish
                                      ? 'Unknown'
                                      : 'ไม่ทราบสถานะ'), // Add status
                              isEnglish: widget.isEnglish, // Pass isEnglish
                              onView: () {
                                _showTransactionDetailDialog(context, transaction);
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  /// Shows a detailed dialog for a specific withdrawal transaction.
  void _showTransactionDetailDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    // Format date inside the dialog for consistency
    final detailedFormattedDate =
        transaction.transactionDate != null
            ? DateFormat(
                widget.isEnglish ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy HH:mm',
                widget.isEnglish ? 'en_US' : 'th_TH',
              ).format(transaction.transactionDate!.toLocal()) // ใช้ toLocal()
            : (widget.isEnglish ? 'N/A' : 'ไม่มี');

    final detailedApprovalDate =
        transaction.transactionApprovalDate != null
            ? DateFormat(
                widget.isEnglish ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy HH:mm',
                widget.isEnglish ? 'en_US' : 'th_TH',
              ).format(transaction.transactionApprovalDate!.toLocal()) // ใช้ toLocal()
            : (widget.isEnglish ? 'N/A' : 'ไม่มี');


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.isEnglish ? 'Withdrawal Details' : 'รายละเอียดการถอนเงิน',
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '${widget.isEnglish ? 'Name' : 'ชื่อผู้ใช้'}: ${transaction.member?.person?.firstName ?? ''} ${transaction.member?.person?.lastName ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Amount' : 'จำนวนเงิน'}: ${transaction.transactionAmount?.toStringAsFixed(2) ?? '0.00'} ฿',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Date' : 'วันที่ส่งคำขอ'}: $detailedFormattedDate',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Status' : 'สถานะ'}: ${TransactionStatusHelper.getLocalizedStatus(transaction.transactionStatus ?? '', widget.isEnglish)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TransactionStatusHelper.getStatusColor(transaction.transactionStatus ?? ''),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'PromPay Number' : 'เบอร์พร้อมเพย์'}: ${transaction.prompayNumber ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Bank Account No.' : 'เลขที่บัญชีธนาคาร'}: ${transaction.bankAccountNumber ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Bank Account Name' : 'ชื่อบัญชีธนาคาร'}: ${transaction.bankAccountName ?? (widget.isEnglish ? 'N/A' : 'ไม่มี')}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.isEnglish ? 'Approval Date' : 'วันที่อนุมัติ'}: $detailedApprovalDate',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(widget.isEnglish ? 'Close' : 'ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Extension เพื่อช่วยในการค้นหาใน List
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

// ---
// ## Withdrawal Request Card Widget
// This stateless widget displays a single withdrawal request in a card format.
// ---
class WithdrawalRequestCard extends StatelessWidget {
  final String amount;
  final String name;
  final String date;
  final String status;
  final bool isEnglish;
  final VoidCallback onView;

  const WithdrawalRequestCard({
    super.key,
    required this.amount,
    required this.name,
    required this.date,
    required this.status,
    required this.isEnglish,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = TransactionStatusHelper.getLocalizedStatus(status, isEnglish);
    final statusColor = TransactionStatusHelper.getStatusColor(status);

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
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$amount ฿', // Display dynamic amount with Baht symbol
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isEnglish ? 'Name' : 'ชื่อ'} : $name',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
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
                    backgroundColor: Colors.blueAccent, // View button color
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
            const SizedBox(height: 10), // Space between top row and status
            Align(
              // Align status to the end
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(
                    0.2,
                  ), // Light background for status
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
