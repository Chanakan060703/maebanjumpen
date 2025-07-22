import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/model/transaction.dart'; // Import your Transaction model
import 'package:maebanjumpen/controller/transactionController.dart'; // Import your TransactionController
import 'package:intl/intl.dart'; // For date formatting

class HistoryPageAccountManager extends StatefulWidget {
  final AccountManager user;
  final bool isEnglish;

  const HistoryPageAccountManager({
    super.key,
    required this.user,
    this.isEnglish = true,
  });

  @override
  State<HistoryPageAccountManager> createState() => _HistoryPageAccountManagerState();
}

class _HistoryPageAccountManagerState extends State<HistoryPageAccountManager> {
  final TransactionController _transactionController = TransactionController();
  List<Transaction> _transactionHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<Transaction> fetchedTransactions = await _transactionController.getAllTransactions();

      // Filter for approved transactions if needed for 'history' (adjust logic based on your definition of history)
      // For this example, let's assume we want to show all transactions for now,
      // but if "history" means only approved or completed ones, you'd filter here.
      // List<Transaction> approvedTransactions = fetchedTransactions.where((t) => t.transactionStatus == 'Approved').toList();


      // Sort by transactionApprovalDate in descending order (latest first)
      fetchedTransactions.sort((a, b) {
        // Handle null dates: nulls typically go to the end
        if (a.transactionApprovalDate == null && b.transactionApprovalDate == null) return 0;
        if (a.transactionApprovalDate == null) return 1; // a is null, b is not, a comes after
        if (b.transactionApprovalDate == null) return -1; // b is null, a is not, b comes after

        // Compare non-null dates
        return b.transactionApprovalDate!.compareTo(a.transactionApprovalDate!);
      });

      setState(() {
        _transactionHistory = fetchedTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = widget.isEnglish
            ? 'Failed to load transaction history: ${e.toString()}'
            : 'ไม่สามารถโหลดประวัติการทำรายการได้: ${e.toString()}';
        _isLoading = false;
        print('Error in _fetchTransactions: $e'); // For debugging
      });
    }
  }

  // Helper to format date
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(date); // Format as desired
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEnglish ? 'Transaction History' : 'ประวัติการทำรายการ',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
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
                        Icon(Icons.error_outline, color: Colors.red, size: 40),
                        SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchTransactions,
                          child: Text(widget.isEnglish ? 'Retry' : 'ลองอีกครั้ง'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transactionHistory.isEmpty
                  ? Center(
                      child: Text(
                        widget.isEnglish ? 'No history available.' : 'ไม่มีประวัติการทำรายการ',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _transactionHistory.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactionHistory[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Display relevant transaction info here
                                  '${widget.isEnglish ? 'Type:' : 'ประเภท:'} ${transaction.transactionType ?? 'N/A'} - ${transaction.transactionStatus ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${widget.isEnglish ? 'Amount:' : 'จำนวนเงิน:'} ${transaction.transactionAmount?.toStringAsFixed(2) ?? '-'} THB',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: transaction.transactionAmount == null || transaction.transactionAmount! == 0
                                        ? Colors.grey
                                        : (transaction.transactionType == 'Deposit' ? Colors.green[700] : Colors.red[700]), // Example: color based on type
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${widget.isEnglish ? 'Request Date:' : 'วันที่ร้องขอ:'} ${_formatDate(transaction.transactionDate)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${widget.isEnglish ? 'Approval Date:' : 'วันที่อนุมัติ:'} ${_formatDate(transaction.transactionApprovalDate)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                // You can add more details here, e.g., member info
                                if (transaction.member != null && transaction.member!.person != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      '${widget.isEnglish ? 'Member:' : 'สมาชิก:'} ${transaction.member!.person!.firstName ?? ''} ${transaction.member!.person!.lastName ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}