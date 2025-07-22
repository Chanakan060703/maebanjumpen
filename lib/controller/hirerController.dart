import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/hirer.dart'; // ตรวจสอบว่า import นี้ถูกต้อง
import 'package:maebanjumpen/model/person.dart'; // ต้องมั่นใจว่า Person model มี toJson()

class Hirercontroller {
  // ดึงรายการ Hirer ทั้งหมด
  Future<List<Hirer>?> getListHirer() async {
    final url = Uri.parse('$baseURL/maeban/hirers');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        // เนื่องจาก getListHirer คาดว่าจะได้ list, ต้อง decode เป็น List<dynamic>
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => Hirer.fromJson(json)).toList();
      } else {
        print('Failed to get hirer list. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting hirer list: $e');
      return null;
    }
  }

  // เพิ่ม Hirer ใหม่
  // เปลี่ยนพารามิเตอร์ให้รับ Person object แทน String แยกแต่ละฟิลด์
  Future<Hirer?> addHirer(Person newPerson) async {
    final url = Uri.parse('$baseURL/maeban/hirers');
    try {
      // คาดว่า Backend ต้องการข้อมูล Person เพื่อสร้าง Hirer
      final body = json.encode(newPerson.toJson()); // แปลง Person object เป็น JSON
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hirer.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to add hirer. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding hirer: $e');
      return null;
    }
  }

  // อัปเดต Hirer ที่มีอยู่
  // เปลี่ยนพารามิเตอร์ให้รับ Person object แทน String แยกแต่ละฟิลด์
  Future<Hirer?> updateHirer(int id, Person updatedPerson) async {
    final url = Uri.parse('$baseURL/maeban/hirers/$id');
    try {
      final body = json.encode(updatedPerson.toJson()); // แปลง Person object เป็น JSON
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hirer.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to update hirer. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating hirer: $e');
      return null;
    }
  }

  // ลบ Hirer
  Future<bool> deleteHirer(int id) async {
    final url = Uri.parse('$baseURL/maeban/hirers/$id');
    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Hirer $id deleted successfully.');
        return true;
      } else {
        print('Failed to delete hirer. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting hirer: $e');
      return false;
    }
  }

  // ดึง Hirer เดี่ยวด้วย ID
  Future<Hirer?> getHirerById(int id) async {
    final url = Uri.parse('$baseURL/maeban/hirers/$id');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Hirer.fromJson(json.decode(utf8Body));
      } else {
        print('Failed to get hirer by ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting hirer by ID: $e');
      return null;
    }
  }
}