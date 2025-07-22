import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/controller/reportController.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/login.dart';
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/model/penalty.dart'; // *** เพิ่มการนำเข้า Penalty model
import 'package:maebanjumpen/model/report.dart'; // *** เพิ่มการนำเข้า Report model

class LoginController {
  final ReportController _reportController = ReportController(); // *** เพิ่ม instance ของ ReportController ***

  // Authenticate User
  Future<PartyRole?> authenticate(String username, String password) async {
    try {
      var url = Uri.parse('$baseURL/maeban/login/authenticate');
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Authentication successful: $data');

        final String userType = data['type'];

        if (userType == 'hirer') {
          return Hirer.fromJson(data);
        } else if (userType == 'housekeeper') {
          return Housekeeper.fromJson(data);
        } else if (userType == 'admin') {
          return Admin.fromJson(data);
        } else if (userType == 'accountManager') {
          return AccountManager.fromJson(data);
        } else {
          throw Exception('Unknown user type received: $userType');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      print('Authentication error in controller: $e');
      throw Exception('Login process failed: $e');
    }
  }

  // *** เพิ่ม method สำหรับดึง Penalty object โดยใช้ ID ของ Person ***
  Future<Penalty?> getPenaltyByPersonId(int personId) async {
    try {
      // เรียกใช้ ReportController เพื่อดึง Report ล่าสุดที่มี Penalty
      final Report? report = await _reportController.findLatestReportWithPenaltyByPersonId(personId);
      return report?.penalty; // คืน Penalty object จาก Report
    } catch (e) {
      print("Error fetching penalty via report for person ID: $e");
      return null;
    }
  }

  // Create new login
  Future<Login?> createLogin(String username, String password) async {
    var url = Uri.parse('$baseURL/maeban/login');
    Map data = {
      'username': username,
      'password': password,
    };

    var body = json.encode(data);
    try {
      http.Response response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return Login.fromJson(json.decode(response.body));
      } else {
        print('Failed to create login: ${response.body}');
        throw Exception('Failed to create login');
      }
    } catch (e) {
      print('Error creating login: $e');
      throw Exception('Error creating login');
    }
  }

  // Update login details
  Future<Login?> updateLogin(String username, String newPassword) async {
    var url = Uri.parse('$baseURL/maeban/login/$username');
    Map data = {
      'username': username,
      'password': newPassword,
    };

    var body = json.encode(data);
    try {
      http.Response response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return Login.fromJson(json.decode(response.body));
      } else {
        print('Failed to update login: ${response.body}');
        throw Exception('Failed to update login');
      }
    } catch (e) {
      print('Error updating login: $e');
      throw Exception('Error updating login');
    }
  }

  // Delete login
  Future<void> deleteLogin(String username) async {
    var url = Uri.parse('$baseURL/maeban/login/$username');
    try {
      http.Response response = await http.delete(url, headers: headers);

      if (response.statusCode != 204) {
        print('Failed to delete login: ${response.body}');
        throw Exception('Failed to delete login');
      }
    } catch (e) {
      print('Error deleting login: $e');
      throw Exception('Error deleting login');
    }
  }
}