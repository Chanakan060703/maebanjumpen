import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/hire.dart'; // ตรวจสอบว่า import นี้ถูกต้องและ Hire model มี toJson()
import 'package:maebanjumpen/model/housekeeper_skill.dart'; // เพิ่ม import สำหรับ HousekeeperSkill

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

  /**
   * 💡 เมธอดใหม่: ดึงรายการงานจ้างที่ 'Completed' แล้วสำหรับ Housekeeper ID
   * Endpoint สมมติ: /maeban/hires/housekeepers/{housekeeperId}/completed
   */
  Future<List<Hire>?> getCompletedHiresByHousekeeperId(int housekeeperId) async {
    final url = Uri.parse('$baseURL/maeban/hires/housekeepers/$housekeeperId/completed'); 
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => Hire.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No completed hires found for housekeeper ID $housekeeperId. Status code: 404');
        return [];
      } else {
        print('Failed to get completed hires by housekeeper ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting completed hires by housekeeper ID: $e');
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

  // เมธอด updateHire ที่ขาดหายไป
  Future<Hire?> updateHire(int hireId, Hire updatedHireData) async {
    final url = Uri.parse('$baseURL/maeban/hires/$hireId'); // ตรงกับ @PutMapping("/{hireId}") ใน Backend
    try {
      final response = await http.put(
        url,
        headers: headers, // ใช้ headers เดียวกับที่อื่นๆ
        body: json.encode(updatedHireData.toJson()), // ส่ง Hire object ทั้งหมดไป
      );

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hire.fromJson(jsonDecode(utf8Body)); // Backend คืน Hire ที่อัปเดตแล้ว
      } else if (response.statusCode == 404) {
        print('Hire with ID $hireId not found for update.');
        print('Response body: ${response.body}');
        return null;
      } else if (response.statusCode == 400) { // Bad Request เช่น InsufficientBalanceException
        print('Bad request when updating hire. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        // คุณอาจต้องการจัดการ error body ตรงนี้เพื่อแสดงข้อความที่มาจาก Backend
        return null;
      }
      else {
        print('Failed to update hire. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating hire: $e');
      return null;
    }
  }

  // updateHireStatus (ถ้ายังต้องการใช้แยก)
  // แต่แนะนำให้ใช้ updateHire() ด้านบนแทน เพราะครอบคลุมกว่า
  Future<Map<String, dynamic>?> updateHireStatus(int hireId, String newStatus) async {
    Map<String, dynamic> data = {
      'jobStatus': newStatus, // ชื่อ field ควรตรงกับ model ของ Backend (jobStatus)
    };

    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/hires/$hireId');
    http.Response response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('Failed to update hire status: ${response.statusCode} - ${response.body}');
      return null;
      // throw Exception('Failed to update hire status: ${response.statusCode} - ${response.body}');
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

  Future<Hire?> addProgressionImagesToHire(int hireId, List<String> imageUrls) async {
    final url = Uri.parse('$baseURL/maeban/hires/$hireId/add-progression-images');
    try {
      // Body คือ List<String> ของ URL รูปภาพ
      final body = json.encode(imageUrls); 
      
      final response = await http.patch(
        url,
        headers: headers, // ใช้ headers เดียวกับที่อื่นๆ
        body: body,
      );

      if (response.statusCode == 200) {
        // Backend คืนค่า HireDTO ที่มีการอัปเดตแล้ว
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hire.fromJson(jsonDecode(utf8Body)); 
      } else if (response.statusCode == 404) {
        print('Hire with ID $hireId not found.');
        return null;
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        print('Bad request (400): ${errorBody['error']}');
        return null;
      } else {
        print('Failed to add progression images. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding progression images: $e');
      return null;
    }
  }
}
