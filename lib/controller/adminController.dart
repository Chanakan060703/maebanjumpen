import 'dart:convert'; // สำหรับ json.decode, json.encode, utf8.decode
import 'package:http/http.dart' as http; // สำหรับการทำ HTTP requests
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/admin.dart'; // โมเดล Admin ที่แก้ไขแล้ว
// โมเดล Person ที่อาจจำเป็นต้องใช้ในการสร้าง request body


class Admincontroller {
  // เมธอดสำหรับดึงข้อมูล Admin ทั้งหมด
  // Endpoint: GET /maeban/admins
  Future<List<Admin>?> getAllAdmin() async {
    final url = Uri.parse('$baseURL/maeban/admins');
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // ถอดรหัส response body เป็น UTF-8 และแปลงเป็น List ของ Map
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = json.decode(utf8Body);

        // แปลงแต่ละ Map ใน List ให้เป็น Admin object
        return jsonList.map((json) => Admin.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        print('Error getAllAdmin: Status code: ${response.statusCode}, Body: ${response.body}');
        return null; // คืนค่า null ในกรณีที่เกิดข้อผิดพลาด
      }
    } catch (e) {
      print('Exception getAllAdmin: $e');
      return null; // คืนค่า null ในกรณีที่เกิด Exception
    }
  }

  // เมธอดสำหรับเพิ่ม Admin ใหม่
  // Endpoint: POST /maeban/admins
  Future<Admin?> addAdmin({
    required String email,
    required String firstName,
    required String lastName,
    required String idCardNumber,
    required String phoneNumber,
    required String address,
    String? pictureUrl, // Optional pictureUrl
    required String accountStatus,
    required String username,
    required String password,
    required String adminStatus,
  }) async {
    final url = Uri.parse('$baseURL/maeban/admins');

    // สร้าง Map สำหรับข้อมูล Person
    Map<String, dynamic> personData = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'idCardNumber': idCardNumber,
      'phoneNumber': phoneNumber,
      'address': address,
      'pictureUrl': pictureUrl, // สามารถเป็น null ได้
      'accountStatus': accountStatus,
      'login': { // ข้อมูล Login ที่ nested อยู่ใน Person
        'username': username,
        'password': password, // รหัสผ่านจะถูกเข้ารหัสใน Backend
      }
    };

    // สร้าง Map สำหรับข้อมูล Admin ทั้งหมด
    Map<String, dynamic> adminData = {
      'type': 'admin', // กำหนด type ให้ถูกต้องตาม PartyRole hierarchy
      'adminStatus': adminStatus, // ฟิลด์เฉพาะของ Admin
      'person': personData, // ใส่ข้อมูล Person ที่สร้างไว้ข้างบน
    };

    try {
      final body = json.encode(adminData); // แปลง Map เป็น JSON string
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) { // 200 OK หรือ 201 Created
        final utf8Body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = json.decode(utf8Body);
        return Admin.fromJson(jsonResponse); // แปลง JSON response กลับเป็น Admin object
      } else {
        print('Error addAdmin: Status code: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception addAdmin: $e');
      return null;
    }
  }

  // เมธอดสำหรับอัปเดต Admin ที่มีอยู่
  // Endpoint: PUT /maeban/admins/{id}
  Future<Admin?> updateAdmin({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String idCardNumber,
    required String phoneNumber,
    required String address,
    String? pictureUrl,
    required String accountStatus,
    required String username, // Username อาจจะใช้ในการอ้างอิง Login object
    required String adminStatus,
  }) async {
    final url = Uri.parse('$baseURL/maeban/admins/$id');

    // สร้าง Map สำหรับข้อมูล Person (อาจจะส่งเฉพาะ personId ถ้า Backend ต้องการ)
    // แต่ถ้า Backend ต้องการอัปเดตข้อมูล Person ด้วย ให้ส่งตามโครงสร้างนี้
    Map<String, dynamic> personData = {
      // 'personId': (admin object ที่มีอยู่ก่อนหน้า).person.personId, // อาจจะต้องดึง personId จาก Admin object เดิม
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'idCardNumber': idCardNumber,
      'phoneNumber': phoneNumber,
      'address': address,
      'pictureUrl': pictureUrl,
      'accountStatus': accountStatus,
      'login': { // อาจจะส่งแค่ username ถ้า Backend ไม่อนุญาตให้อัปเดต password โดยตรง
        'username': username,
      }
    };

    // สร้าง Map สำหรับข้อมูล Admin ทั้งหมด
    Map<String, dynamic> adminData = {
      'id': id, // ID ของ Admin ที่ต้องการอัปเดต
      'type': 'admin',
      'adminStatus': adminStatus,
      'person': personData,
    };

    try {
      final body = json.encode(adminData);
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = json.decode(utf8Body);
        return Admin.fromJson(jsonResponse);
      } else {
        print('Error updateAdmin: Status code: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception updateAdmin: $e');
      return null;
    }
  }

  // เมธอดสำหรับลบ Admin
  // Endpoint: DELETE /maeban/admins/{id}
  Future<bool> deleteAdmin(int id) async {
    final url = Uri.parse('$baseURL/maeban/admins/$id');
    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) { // 200 OK หรือ 204 No Content
        return true;
      } else {
        print('Error deleteAdmin: Status code: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception deleteAdmin: $e');
      return false;
    }
  }

  // เมธอดสำหรับดึงข้อมูล Admin โดย ID
  // Endpoint: GET /maeban/admins/{id}
  Future<Admin?> getAdminById(int id) async {
    final url = Uri.parse('$baseURL/maeban/admins/$id');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonMap = json.decode(utf8Body);
        return Admin.fromJson(jsonMap);
      } else {
        print('Error getAdminById: Status code: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getAdminById: $e');
      return null;
    }
  }
}