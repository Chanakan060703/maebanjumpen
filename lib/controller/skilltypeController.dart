import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/skill_type.dart';

class Skilltypecontroller {

  Future<List<SkillType>> getAllSkilltype() async { // เปลี่ยน return type เป็น List<SkillType>
    var url = Uri.parse('$baseURL/maeban/skill-types');
    http.Response response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      // Map JSON แต่ละอันให้เป็น SkillType object
      return jsonList.map((json) => SkillType.fromJson(json)).toList();
    } else {
      print('Failed to load skill types: ${response.statusCode}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addSkilltype(String skillTypeName, String skillTypeDetail, double basePricePerHour) async {
    Map<String, dynamic> data = {
        'skillTypeName': skillTypeName,
        'skillTypeDetail': skillTypeDetail,
        'basePricePerHour': basePricePerHour,
    };
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/skill-types');
    http.Response response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);
        print('Add SkillType Response: $jsonResponse');
        return jsonResponse;
    } else {
        var errorBody = jsonDecode(response.body);
        print('Failed to add skill type: ${response.statusCode} - $errorBody');
        return null; // หรือ throw Exception
    }
}

  Future<Map<String, dynamic>?> updateSkilltype(int id, String skillTypeName, String skillTypeDetail, double basePricePerHour) async {
    Map<String, dynamic> data = {
        'skillTypeName': skillTypeName,
        'skillTypeDetail': skillTypeDetail,
        'basePricePerHour': basePricePerHour,
    };
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/skill-types/$id');
    http.Response response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('Update SkillType Response: $jsonResponse');
        return jsonResponse;
    } else {
        var errorBody = jsonDecode(response.body);
        print('Failed to update skill type: ${response.statusCode} - $errorBody');
        return null; // หรือ throw Exception
    }
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