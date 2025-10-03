import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart'; // ตรวจสอบว่ามี baseURL และ headers ที่ถูกต้อง
import 'package:maebanjumpen/model/transaction.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kDebugMode

class TransactionController {
  // baseURL และ headers ถูกกำหนดใน constant_value.dart
  // เช่น final String baseURL = 'http://your-backend-ip:8088';
  // final Map<String, String> headers = {'Accept': 'application/json'};
  // ------------------------------------------------------------------
  // Helper for JSON headers
  // ------------------------------------------------------------------
  final Map<String, String> _jsonHeaders = {
    ...headers,
    'Content-Type': 'application/json',
  };
  // ------------------------------------------------------------------
  // GET methods
  // ------------------------------------------------------------------
  /// ดึงข้อมูล Transaction ทั้งหมด
  Future<List<Transaction>> getAllTransactions() async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions');
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        return data.map((e) => Transaction.fromJson(e)).toList();
      }
      // แสดงรายละเอียด error จาก backend ถ้ามี
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception(
        'Failed to load transactions: ${response.statusCode}. Detail: $errorBody',
      );
    } catch (e) {
      if (kDebugMode) print('Error fetching all transactions: $e');
      rethrow; // rethrow เพื่อให้ caller จัดการ exception ต่อไป
    }
  }

  /// ดึงข้อมูล Transaction โดย ID
  Future<Transaction> getTransactionById(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return Transaction.fromJson(
          json.decode(utf8.decode(response.bodyBytes)),
        );
      }
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception(
        'Failed to load transaction ID $id: ${response.statusCode}. Detail: $errorBody',
      );
    } catch (e) {
      if (kDebugMode) print('Error fetching transaction ID $id: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูล Transaction โดย Member ID
  Future<List<Transaction>> getTransactionsByMemberId(int memberId) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions?memberId=$memberId');
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        return data.map((e) => Transaction.fromJson(e)).toList();
      } else if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        // No Content หรือ Body ว่าง หมายถึงไม่มีข้อมูล
        return [];
      }
      // การจัดการ Exception ที่มีรายละเอียดมากขึ้น
      String errorDetail = utf8.decode(response.bodyBytes);
      throw Exception(
        'Failed to load transactions for member $memberId: ${response.statusCode}. Detail: $errorDetail',
      );
    } catch (e) {
      if (kDebugMode) print('Error fetching transactions by member: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูล Transaction โดยประเภท (ถ้า Backend รองรับ query param: ?type=)
  Future<List<Transaction>> getTransactionsByType(String type) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions?type=$type');
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        return data.map((e) => Transaction.fromJson(e)).toList();
      } else if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        return [];
      }
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception(
        'Failed to load transactions by type: ${response.statusCode}. Detail: $errorBody',
      );
    } catch (e) {
      if (kDebugMode) print('Error fetching transactions by type: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // POST/PATCH/PUT/DELETE methods
  // ------------------------------------------------------------------
  /// สร้าง Transaction ใหม่
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions');
      var body = json.encode(transaction.toJson());
      if (kDebugMode) print('Sending POST Request Body: $body');
      var response = await http.post(
        url,
        headers: _jsonHeaders, // ใช้ JSON headers
        body: body,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(
          json.decode(utf8.decode(response.bodyBytes)),
        );
      }
      String errorResponse = utf8.decode(response.bodyBytes);
      if (kDebugMode)
        print(
          'Failed to create transaction: ${response.statusCode} - $errorResponse',
        );
      throw Exception(
        'Failed to create transaction: ${response.statusCode} - $errorResponse',
      );
    } catch (e) {
      if (kDebugMode) print('Error creating transaction: $e');
      rethrow;
    }
  }

  /// อัปเดตสถานะ Transaction (ใช้ HTTP PATCH)
  Future<bool> updateTransactionStatus(
    int transactionId,
    String newStatus,
    int accountManagerId,
  ) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$transactionId/status');
      // สร้าง Body ที่มี 'newStatus' และ 'accountManagerId'
      // ส่ง accountManagerId เป็น int ตามหลักการทั่วไปของ JSON
      final Map<String, dynamic> bodyData = {
        'newStatus': newStatus,
        'accountManagerId': accountManagerId,
      };
      var body = json.encode(bodyData);
      if (kDebugMode) print('Sending PATCH Status Request Body to $url: $body');
      var response = await http.patch(
        url,
        headers: _jsonHeaders, // ใช้ JSON headers
        body: body,
      );
      if (response.statusCode == 200) {
        if (kDebugMode)
          print(
            'Transaction ID $transactionId status updated to $newStatus successfully.',
          );
        return true;
      } else {
        final errorDetail = utf8.decode(response.bodyBytes);
        if (kDebugMode) {
          print(
            'Failed to update transaction status: ${response.statusCode} - $errorDetail',
          );
        }
        // สามารถ throw exception ตรงนี้ได้หากต้องการให้ caller จัดการกับ error
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error updating transaction status: $e');
      return false;
    }
  }

  /// อัปเดต Transaction ทั่วไป (เปลี่ยนเป็น HTTP PATCH สำหรับ Partial Update)
  Future<bool> updateTransaction(int id, Transaction transaction) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      // สร้าง Map ใหม่ที่มีเฉพาะฟิลด์ที่ต้องการอัปเดต (เพื่อใช้ในการทำ Partial Update/PATCH)
      final Map<String, dynamic> dataToUpdate = {};
      // ไม่ควรอนุญาตให้อัปเดต ID, Status, ApprovalDate ผ่านเมธอดนี้
      if (transaction.transactionType != null)
        dataToUpdate['transactionType'] = transaction.transactionType;
      if (transaction.transactionAmount != null)
        dataToUpdate['transactionAmount'] = transaction.transactionAmount;
      if (transaction.transactionDate != null)
        dataToUpdate['transactionDate'] =
            transaction.transactionDate!.toIso8601String();
      if (transaction.prompayNumber != null)
        dataToUpdate['prompayNumber'] = transaction.prompayNumber;
      if (transaction.bankAccountNumber != null)
        dataToUpdate['bankAccountNumber'] = transaction.bankAccountNumber;
      if (transaction.bankAccountName != null)
        dataToUpdate['bankAccountName'] = transaction.bankAccountName;
      if (transaction.memberId != null)
        dataToUpdate['memberId'] = transaction.memberId;
      if (dataToUpdate.isEmpty) {
        if (kDebugMode) print('No fields to update for transaction ID $id.');
        return true;
      }
      var body = json.encode(dataToUpdate);
      if (kDebugMode) print('Sending PATCH Request Body to $url: $body');
      // *** เปลี่ยนจาก http.put เป็น http.patch สำหรับ Partial Update ***
      var response = await http.patch(
        url,
        headers: _jsonHeaders, // ใช้ JSON headers
        body: body,
      );
      if (response.statusCode == 200) {
        if (kDebugMode) print('Transaction with ID $id updated successfully.');
        return true;
      } else {
        final errorDetail = utf8.decode(response.bodyBytes);
        if (kDebugMode)
          print(
            'Failed to update transaction: ${response.statusCode} - $errorDetail',
          );
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error updating transaction: $e');
      return false;
    }
  }

  /// ลบ Transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      var response = await http.delete(url, headers: headers);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception(
        'Failed to delete transaction: ${response.statusCode}. Detail: $errorBody',
      );
    } catch (e) {
      if (kDebugMode) print('Error deleting transaction: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // QR Code Generation
  // ------------------------------------------------------------------
  /// สร้าง QR Code สำหรับการฝากเงิน
  Future<Map<String, dynamic>?> createDepositQrCode({
    required int memberId,
    required double amount,
  }) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/qrcode/deposit');
      final Map<String, dynamic> requestBody = {
        'memberId': memberId,
        'amount': amount,
      };
      var body = json.encode(requestBody);
      if (kDebugMode) print('Sending POST QR Code Request Body to $url: $body');
      var response = await http.post(
        url,
        headers: _jsonHeaders, // ใช้ JSON headers
        body: body,
      );
      if (kDebugMode)
        print('QR Code API Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        String? qrCodeBase64 = responseData['qrCodeImageBase64'];
        // transactionId อาจเป็น int หรือ String ขึ้นอยู่กับ Backend
        dynamic transactionId = responseData['transactionId'];
        if (qrCodeBase64 != null && qrCodeBase64.isNotEmpty) {
          if (kDebugMode)
            print(
              'Received qrCodeImageBase64 successfully. Length: ${qrCodeBase64.length}',
            );
          return {
            'qrCodeImageBase64': qrCodeBase64,
            'transactionId': transactionId,
          };
        } else {
          if (kDebugMode)
            print(
              'qrCodeImageBase64 is null or empty. Full response: $responseData',
            );
          throw Exception('Backend did not return valid QR Code Base64 data.');
        }
      } else {
        String errorDetail = utf8.decode(response.bodyBytes);
        if (kDebugMode) print('Backend Error Detail: $errorDetail');

        throw Exception(
          'Failed to create QR Code: ${response.statusCode} - $errorDetail',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error creating deposit QR Code: $e');
      rethrow;
    }
  }

  /// ดึงสถานะของ Transaction (ใช้สำหรับตรวจสอบหลังการชำระเงินด้วย QR)
  Future<Map<String, dynamic>?> getTransactionStatus(int transactionId) async {
    final url = Uri.parse('$baseURL/maeban/transactions/$transactionId/status');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        if (kDebugMode) {
          print(
            'Failed to get transaction status for ID $transactionId. Status code: ${response.statusCode}',
          );
          print('Response body: ${utf8.decode(response.bodyBytes)}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error getting transaction status: $e');
      return null;
    }
  }
}
