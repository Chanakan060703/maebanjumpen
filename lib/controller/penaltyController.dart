import 'dart:convert';
import 'package:http/http.dart' as http;
// สมมติว่าไฟล์นี้มีอยู่จริงในโครงสร้างโปรเจกต์ของคุณ
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/penalty.dart'; // นำเข้า Penalty model

class Penaltycontroller {
  // ดึงข้อมูลบทลงโทษทั้งหมด
  Future getPenalty() async {
    var url = Uri.parse('$baseURL/maeban/penalties');

    http.Response response = await http.get(url, headers: headers);

    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  }

  // เพิ่มบทลงโทษใหม่ (รองรับการส่ง ID เป็น Query Parameters)
  Future<Penalty> addPenalty(
    Penalty penalty, // รับออบเจกต์ Penalty โดยตรง (Body)

    String? reportId, // ID รายงาน (Query Parameter)

    String? hirerId, // ID ผู้จ้าง (Query Parameter)

    String? housekeeperId, // ID แม่บ้าน (Query Parameter)
  ) async {
    // สร้าง URL พร้อม query parameters ตามที่ Controller.java คาดหวัง

    Uri url = Uri.parse('$baseURL/maeban/penalties');

    Map<String, String> queryParams = {};

    if (reportId != null && reportId.isNotEmpty) {
      queryParams['reportId'] = reportId;
    }

    // ส่ง ID ของผู้จ้างและแม่บ้านไป หาก API ต้องการใช้เพื่อระบุเป้าหมายแม้ในฝั่ง Dart จะใช้ reportId เป็นหลัก

    if (hirerId != null && hirerId.isNotEmpty) {
      queryParams['hirerId'] = hirerId;
    }

    if (housekeeperId != null && housekeeperId.isNotEmpty) {
      queryParams['housekeeperId'] = housekeeperId;
    }

    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    var body = json.encode(
      penalty.toJson(),
    ); // แปลงออบเจกต์ Penalty เป็น JSON (Request Body)

    http.Response response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var jsonResponse = jsonDecode(response.body);

      return Penalty.fromJson(jsonResponse);
    } else {
      // จัดการข้อผิดพลาดที่มาจาก API

      print('Failed to add penalty: ${response.statusCode} ${response.body}');

      throw Exception('Failed to add penalty');
    }
  }

  // อัปเดตบทลงโทษ
  Future updatePenalty(
    int id,

    String name,

    String description,

    String penaltyType,

    String penaltyValue,
  ) async {
    Map data = {
      'name': name,

      'description': description,

      'penaltyType': penaltyType,

      'penaltyValue': penaltyValue,
    };

    var body = json.encode(data);

    var url = Uri.parse('$baseURL/maeban/penalties/${id}');

    http.Response response = await http.put(url, headers: headers, body: body);

    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  }

  // ลบบทลงโทษ
  Future deletePenalty(int id) async {
    var url = Uri.parse('$baseURL/maeban/penalties/${id}');

    http.Response response = await http.delete(url, headers: headers);

    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  }

  // ดึงบทลงโทษตาม ID
  Future getPenaltyById(int id) async {
    var url = Uri.parse('$baseURL/maeban/penalties/${id}');

    http.Response response = await http.get(url, headers: headers);

    var jsonResponse = jsonDecode(response.body);

    return jsonResponse;
  }
}
