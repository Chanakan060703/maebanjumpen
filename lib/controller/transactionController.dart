import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart'; // ตรวจสอบว่าไฟล์นี้มี baseURL และ headers ที่ถูกต้อง
import 'package:maebanjumpen/model/transaction.dart';

class TransactionController {
  // baseURL และ headers ควรจะถูกกำหนดใน constant_value.dart
  // เช่น final String baseURL = 'http://your-backend-ip:8088';
  // final Map<String, String> headers = {'Accept': 'application/json'};

  // ดึงข้อมูล Transaction ทั้งหมด
  Future<List<Transaction>> getAllTransactions() async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        return data.map((e) => Transaction.fromJson(e)).toList();
      }
      throw Exception('Failed to load transactions: ${response.statusCode}');
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Failed to load transactions');
    }
  }

  // ดึงข้อมูล Transaction โดย ID
  Future<Transaction> getTransactionById(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return Transaction.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Failed to load transaction: ${response.statusCode}');
    } catch (e) {
      print('Error fetching transaction: $e');
      throw Exception('Failed to load transaction');
    }
  }

  // สร้าง Transaction ใหม่
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions');
      final Map<String, String> requestHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };

      var body = json.encode(transaction.toJson());
      print('Sending POST Request Body: $body'); // เพิ่มบรรทัดนี้เพื่อ debug

      var response = await http.post(
          url,
          headers: requestHeaders,
          body: body
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      print('Failed to create transaction: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create transaction: ${response.body}');
    } catch (e) {
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction');
    }
  }

  Future<bool> updateTransactionStatus(int transactionId, String newStatus, int accountManagerId) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$transactionId/status');

      final Map<String, String> requestHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };

      // สร้าง Body ที่มี 'newStatus' และ 'accountManagerId' ตามที่ Backend คาดหวัง
      final Map<String, dynamic> bodyData = {
        'newStatus': newStatus,
        'accountManagerId': accountManagerId.toString(), // Backend คาดหวัง String
      };

      var body = json.encode(bodyData);
      print('Sending PATCH Status Request Body to $url: $body'); // Debugging

      // ใช้ http.patch() ตามที่ Backend กำหนดไว้ใน @PatchMapping
      var response = await http.patch(
        url,
        headers: requestHeaders,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Transaction ID $transactionId status updated to $newStatus successfully.');
        return true;
      } else {
        print('Failed to update transaction status: ${response.statusCode} - ${response.body}');
        if (response.body.isNotEmpty) {
          try {
            final errorDetail = json.decode(utf8.decode(response.bodyBytes));
            print('Backend Error Detail: ${errorDetail['error'] ?? errorDetail}');
          } catch (e) {
            print('Could not parse backend error response.');
          }
        }
        return false;
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // อัปเดต Transaction ทั่วไป (ใช้เมื่อต้องการเปลี่ยนหลายฟิลด์ *ยกเว้นสถานะ*)
  // เมธอดนี้จะยังคงอยู่และถูกใช้สำหรับอัปเดตข้อมูลอื่นๆ ที่ไม่ใช่สถานะ
  // แต่จะไม่มีการส่ง 'transactionStatus' หรือ 'transactionApprovalDate' ใน body ของ request
  Future<bool> updateTransaction(int id, Transaction transaction) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      final Map<String, String> requestHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };

      // สร้าง Map ใหม่ที่มีเฉพาะฟิลด์ที่ต้องการอัปเดต (ไม่รวม ID, Status, ApprovalDate)
      final Map<String, dynamic> dataToUpdate = {};
      if (transaction.transactionType != null) dataToUpdate['transactionType'] = transaction.transactionType;
      if (transaction.transactionAmount != null) dataToUpdate['transactionAmount'] = transaction.transactionAmount;
      if (transaction.transactionDate != null) dataToUpdate['transactionDate'] = transaction.transactionDate?.toIso8601String();
      // ไม่รวม transactionStatus เพราะมี endpoint แยกต่างหาก
      // ไม่รวม member เพราะ Backend บอก "Cannot change member of an existing transaction."
      if (transaction.prompayNumber != null) dataToUpdate['prompayNumber'] = transaction.prompayNumber;
      if (transaction.bankAccountNumber != null) dataToUpdate['bankAccountNumber'] = transaction.bankAccountNumber;
      if (transaction.bankAccountName != null) dataToUpdate['bankAccountName'] = transaction.bankAccountName;
      // ไม่รวม transactionApprovalDate เพราะถูกตั้งค่าโดย endpoint สถานะ
      
      var body = json.encode(dataToUpdate);
      print('Sending PUT Request Body to $url (non-status fields): $body'); // Debugging

      var response = await http.put(
          url,
          headers: requestHeaders,
          body: body
      );

      if (response.statusCode == 200) {
        print('Transaction with ID $id updated successfully (non-status fields).');
        return true;
      } else if (response.statusCode == 404) {
        print('Transaction with ID $id not found for update.');
        return false;
      } else {
        print('Failed to update transaction (non-status fields): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating transaction (non-status fields): $e');
      return false;
    }
  }

  // ลบ Transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/$id');
      var response = await http.delete(url, headers: headers);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to delete transaction: ${response.statusCode}');
    } catch (e) {
      print('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction');
    }
  }

  Future<List<Transaction>> getTransactionsByMemberId(int memberId) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions?memberId=$memberId');
      var response = await http.get(url, headers: headers);

      print('--- DEBUG Flutter: getTransactionsByMemberId ---');
      print('URL ที่เรียก: $url');
      print('HTTP Status Code: ${response.statusCode}');
      final String rawResponseBody = utf8.decode(response.bodyBytes);
      print('Response Body ที่ได้รับ (Raw): $rawResponseBody');
      // --- ---------------------------------------------------- ---

      if (response.statusCode == 200) {
        final data = json.decode(rawResponseBody) as List;
        return data.map((e) {
          print('Processing item in map. Type: ${e.runtimeType}, value: $e');
          return Transaction.fromJson(e);
        }).toList();
      }
      throw Exception('Failed to load transactions: ${response.statusCode}');
    } catch (e) {
      print('Error fetching transactions by member: $e');
      throw Exception('Failed to load transactions');
    }
  }

  // ดึงข้อมูล Transaction โดยประเภท
  Future<List<Transaction>> getTransactionsByType(String type) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions?type=$type');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        return data.map((e) => Transaction.fromJson(e)).toList();
      }
      throw Exception('Failed to load transactions: ${response.statusCode}');
    } catch (e) {
      print('Error fetching transactions by type: $e');
      throw Exception('Failed to load transactions');
    }
  }

  Future<Map<String, dynamic>?> createDepositQrCode({
    required int memberId,
    required double amount,
  }) async {
    try {
      var url = Uri.parse('$baseURL/maeban/transactions/qrcode/deposit');
      final Map<String, String> requestHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        'memberId': memberId,
        'amount': amount,
      };

      var body = json.encode(requestBody);
      print('Sending POST QR Code Request Body to $url: $body');

      var response = await http.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      print('QR Code API Response Status: ${response.statusCode}');
      print('QR Code API Response Body Length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));

        String? qrCodeBase64 = responseData['qrCodeImageBase64'];
        int? transactionId = responseData['transactionId'];

        if (qrCodeBase64 != null && qrCodeBase64.isNotEmpty) {
          // >>> แก้ไข: ทำความสะอาด Base64 string ก่อนส่งออก <<<
          String cleanBase64 = qrCodeBase64.replaceAll(RegExp(r'\s+'), ''); // ลบอักขระช่องว่างทั้งหมด
          
          print('TransactionController: Received qrCodeImageBase64 successfully. Cleaned Length: ${cleanBase64.length}');
          
          return {'qrCodeImageBase64': cleanBase64, 'transactionId': transactionId};
        } else {
          print('TransactionController: qrCodeImageBase64 is null or empty in responseData. Full response: $responseData');
          throw Exception('Backend did not return valid QR Code Base64 data.');
        }
      } else {
        print('Failed to create QR Code: ${response.statusCode} - ${response.body}');
        if (response.body.isNotEmpty) {
          try {
            final errorDetail = json.decode(utf8.decode(response.bodyBytes));
            print('Backend Error Detail: ${errorDetail['message'] ?? errorDetail['error'] ?? errorDetail}');
          } catch (e) {
            print('Could not parse backend error response for QR Code. Error: $e');
          }
        }
        throw Exception('Failed to create QR Code: ${response.body}');
      }
    } catch (e) {
      print('Error creating deposit QR Code: $e');
      throw Exception('Failed to create deposit QR Code: $e');
    }
  }

  Future<Map<String, dynamic>?> getTransactionStatus(int transactionId) async {
    final url = Uri.parse('$baseURL/maeban/transactions/$transactionId/status');
    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        print('Failed to get transaction status for ID $transactionId. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting transaction status: $e');
      return null;
    }
  }
}