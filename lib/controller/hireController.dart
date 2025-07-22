import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/hire.dart'; // ตรวจสอบว่า import นี้ถูกต้องและ Hire model มี toJson()

class Hirecontroller {
  // คาดว่า Backend ใช้ Endpoint '/maeban/hires' และคืนค่าเป็น JSON array
  Future<List<Hire>?> getAllHires() async {
    final url = Uri.parse('$baseURL/maeban/hires'); // เปลี่ยนเป็น /hires (พหูพจน์)
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => Hire.fromJson(json)).toList();
      } else {
        print('Failed to get all hires. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting all hires: $e');
      return null;
    }
  }

  Future<List<Hire>?> getHiresByHirerId(int hirerId) async {
    final url = Uri.parse('$baseURL/maeban/hires/hirer/$hirerId'); 
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => Hire.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No hires found for hirer ID $hirerId. Status code: 404');
        return []; 
      } else {
        print('Failed to get hires by hirer ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting hires by hirer ID: $e');
      return null;
    }
  }

  Future<List<Hire>?> getHiresByHousekeeperId(int housekeeperId) async {
    final url = Uri.parse('$baseURL/maeban/hires/housekeepers/$housekeeperId'); 
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => Hire.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No hires found for housekeeper ID $housekeeperId. Status code: 404');
        return []; 
      } else {
        print('Failed to get hires by housekeeper ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting hires by housekeeper ID: $e');
      return null;
    }
  }

  Future<Hire?> addHire(Hire newHire) async {
    final url = Uri.parse('$baseURL/maeban/hires');
    try {
      final body = json.encode(newHire.toJson()); // นี่คือส่วนที่แปลง Hire Object เป็น JSON String
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hire.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to add hire. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding hire: $e');
      return null;
    }
  }

  // อัปเดต Hire ที่มีอยู่
  Future<Hire?> updateHire(int id, Hire updatedHire) async {
    final url = Uri.parse('$baseURL/maeban/hires/$id'); 
    try {
      final body = json.encode(updatedHire.toJson()); // updatedHire.toJson() ก็จะส่ง hirer.id และ housekeeper.id
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hire.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to update hire. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating hire: $e');
      return null;
    }
  }

  // ลบ Hire
  Future<bool> deleteHire(int id) async {
    final url = Uri.parse('$baseURL/maeban/hires/$id'); // เปลี่ยนเป็น /hires (พหูพจน์)
    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content ก็ถือว่าสำเร็จ
        print('Hire $id deleted successfully.');
        return true;
      } else {
        print('Failed to delete hire. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting hire: $e');
      return false;
    }
  }

  // ดึง Hire เดี่ยวด้วย ID
  Future<Hire?> getHireById(int id) async {
    final url = Uri.parse('$baseURL/maeban/hires/$id'); // เปลี่ยนเป็น /hires (พหูพจน์)
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hire.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to get hire by ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting hire by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateHireStatus(int hireId, String newStatus) async {
    Map data = {
      'status': newStatus, // Field to update on the backend
    };

    var body = json.encode(data);
    // Adjust this URL to your actual endpoint for updating hire status
    // It might be something like /maeban/hires/{id}/status or /maeban/hires/{id} with a PUT request
    var url = Uri.parse('$baseURL/maeban/hires/$hireId'); // Example: PUT /maeban/hires/123
    http.Response response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update hire status: ${response.statusCode} - ${response.body}');
    }
  }
}