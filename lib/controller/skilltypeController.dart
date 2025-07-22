import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';

class Skilltypecontroller {

    

   Future<List<dynamic>> getAllSkilltype() async { // เปลี่ยน return type เป็น List<dynamic>
    var url = Uri.parse('$baseURL/maeban/skill-types');
    http.Response response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Backend ส่งคืน List ของ SkillType Objects โดยตรง
      List<dynamic> jsonResponse = jsonDecode(response.body);
      print('SkillType API Response: $jsonResponse'); // เพื่อ Debug
      return jsonResponse;
    } else {
      // จัดการข้อผิดพลาด
      print('Failed to load skill types: ${response.statusCode}');
      return []; // คืนค่า List ว่างเปล่าหากเกิดข้อผิดพลาด
    }
  }

  Future addSkilltype(String name) async {
    Map data = {'name': name};
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/skill-types');
    http.Response response = await http.post(url, headers: headers, body: body);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }

  Future updateSkilltype(int id, String name) async {
    Map data = {'name': name};
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/skill-types/${id}');
    http.Response response = await http.put(url, headers: headers, body: body);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> deleteHousekeeperskill(int skillId) async {
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills/$skillId');
    http.Response response = await http.delete(url, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content for successful delete
      return {'status': 'success', 'message': 'Skill deleted successfully'};
    } else {
      var errorBody = jsonDecode(response.body);
      print('Failed to delete housekeeper skill: ${response.statusCode} - $errorBody');
      return {'status': 'error', 'message': errorBody['message'] ?? 'Unknown error'};
    }
  }

  Future getSkilltypeById(int id) async {
    var url = Uri.parse('$baseURL/maeban/skill-types/${id}');
    http.Response response = await http.get(url, headers: headers);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }
}