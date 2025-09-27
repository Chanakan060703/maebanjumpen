import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';

class Housekeeperskillcontroller {
  Future getAllHousekeeperskill() async {
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills');
    http.Response response = await http.get(url, headers: headers);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }

  Future<Map<String, dynamic>> addHousekeeperskill(
    int housekeeperId,
    int skillTypeId,
    int skillLevelTierId,
    {required double customDailyRate} // เพิ่ม customDailyRate
  ) async {
    Map<String, dynamic> data = {
      'housekeeperId': housekeeperId,
      'skillTypeId': skillTypeId,
      'skillLevelTierId': skillLevelTierId,
      'pricePerDay': customDailyRate, // ส่งราคาที่ผู้ใช้กำหนด
    };
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills');
    http.Response response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var jsonResponse = jsonDecode(response.body);
      print('Add Housekeeper Skill Response: $jsonResponse');
      return {'status': 'success', 'data': jsonResponse};
    } else {
      var errorBody = jsonDecode(response.body);
      print('Failed to add housekeeper skill: ${response.statusCode} - $errorBody');
      String errorMessage = errorBody != null && errorBody['message'] != null
          ? errorBody['message']
          : 'Unknown error';
      return {'status': 'error', 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>> updateHousekeeperskill(
    int skillId,
    int skillLevelTierId,
    {required double customDailyRate} // เพิ่ม customDailyRate
  ) async {
    Map<String, dynamic> data = {
      'skillLevelTierId': skillLevelTierId,
      'pricePerDay': customDailyRate, // ส่งราคาที่ผู้ใช้กำหนด
    };
    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills/$skillId');
    http.Response response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print('Update Housekeeper Skill Response: $jsonResponse');
      return {'status': 'success', 'data': jsonResponse};
    } else {
      var errorBody = jsonDecode(response.body);
      print('Failed to update housekeeper skill: ${response.statusCode} - $errorBody');
      String errorMessage = errorBody != null && errorBody['message'] != null
          ? errorBody['message']
          : 'Unknown error';
      return {'status': 'error', 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>> deleteHousekeeperskill(int skillId) async {
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills/$skillId');
    http.Response response = await http.delete(url, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return {'status': 'success', 'message': 'Skill deleted successfully'};
    } else {
      var errorBody = jsonDecode(response.body);
      print('Failed to delete housekeeper skill: ${response.statusCode} - $errorBody');
      String errorMessage = errorBody != null && errorBody['message'] != null
          ? errorBody['message']
          : 'Unknown error';
      return {'status': 'error', 'message': errorMessage};
    }
  }

  Future getHousekeeperskillById(int id) async {
    var url = Uri.parse('$baseURL/maeban/housekeeper-skills/${id}');
    http.Response response = await http.get(url, headers: headers);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }
}