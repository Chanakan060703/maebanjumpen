// lib/controller/report_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/report.dart'; // Import Report model
import 'package:maebanjumpen/model/person.dart'; // Import Person model
import 'package:maebanjumpen/model/hirer.dart'; // Import Hirer model
import 'package:maebanjumpen/model/housekeeper.dart'; // Import Housekeeper model
import 'package:maebanjumpen/model/account_manager.dart'; // Import AccountManager model
import 'package:maebanjumpen/model/admin.dart'; // Import Admin model

class ReportController { 

  Future<List<Report>> getAllReport() async {
    var url = Uri.parse('$baseURL/maeban/reports');
    try {
      http.Response response = await http.get(url, headers: headers); // ใช้ headers ที่กำหนดไว้ใน constant_value

      if (response.statusCode == 200) {
        // แปลง List<dynamic> ที่ได้จาก jsonDecode ให้เป็น List<Report>
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((jsonItem) => Report.fromJson(jsonItem)).toList();
      } else {
        print('Failed to load reports. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load reports: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling getAllReport: $e');
      throw Exception('Failed to load reports: $e');
    }
  }

  // แก้ไข addReport ให้รับ Report object โดยตรง
  Future<Report> addReport(Report report) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/maeban/reports'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(report.toJson()), // แปลง Report object เป็น JSON string
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to add report. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to add report: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling addReport: $e');
      throw Exception('Failed to add report: $e');
    }
  }

  // แก้ไข updateReport ให้รับ Report object โดยตรง
  Future<Report> updateReport(int id, Report report) async {
    // ปรับปรุงการส่งข้อมูล JSON เพื่อให้ Spring Boot สามารถ resolve type ได้
    final Map<String, dynamic> reportJson = report.toJson();
    
    // Helper function to add DTYPE to PartyRole objects
    void addType(Map<String, dynamic> partyRoleJson, dynamic partyRoleObject) {
  if (partyRoleObject is Hirer) {
    partyRoleJson['type'] = 'hirer';
  } else if (partyRoleObject is Housekeeper) {
    partyRoleJson['type'] = 'housekeeper';
  } else if (partyRoleObject is AccountManager) {
    partyRoleJson['type'] = 'accountManager';
  } else if (partyRoleObject is Admin) {
    partyRoleJson['type'] = 'admin';
  } else {
    partyRoleJson['type'] = 'member';
  }
}

    if (reportJson['hirer'] != null && report.hirer != null) {
      addType(reportJson['hirer'], report.hirer);
    }
    if (reportJson['housekeeper'] != null && report.housekeeper != null) {
      addType(reportJson['housekeeper'], report.housekeeper);
    }
    if (reportJson['reporter'] != null && report.reporter != null) {
      addType(reportJson['reporter'], report.reporter);
    }

    var body = json.encode(reportJson);
    var url = Uri.parse('$baseURL/maeban/reports/$id');
    try {
      http.Response response = await http.put(url, headers: headers, body: body); // ใช้ headers

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to update report. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update report: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling updateReport: $e');
      throw Exception('Failed to update report: $e');
    }
  }

  Future<Map<String, dynamic>> deleteReport(int id) async {
    var url = Uri.parse('$baseURL/maeban/reports/$id');
    try {
      http.Response response = await http.delete(url, headers: headers); // ใช้ headers
      if (response.statusCode == 204) { // 204 No Content for successful delete
        return {'message': 'Report deleted successfully'};
      } else {
        print('Failed to delete report. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete report: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling deleteReport: $e');
      throw Exception('Failed to delete report: $e');
    }
  }

  // เปลี่ยน getReportById ให้คืนค่าเป็น Report object โดยตรงหากต้องการ
  Future<Report> getReportById(int id) async {
    var url = Uri.parse('$baseURL/maeban/reports/$id');
    try {
      http.Response response = await http.get(url, headers: headers); // ใช้ headers
      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to get report by ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get report by ID: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling getReportById: $e');
      throw Exception('Failed to get report by ID: $e');
    }
  }

  Future<Report?> findLatestReportWithPenaltyByPersonId(int personId) async {
    final url = Uri.parse('$baseURL/maeban/reports/latest-with-penalty/by-person/$personId'); // Endpoint ใหม่
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return Report.fromJson(data);
      } else if (response.statusCode == 404) {
        print("No latest report with penalty found for personId: $personId");
        return null;
      } else {
        print("Failed to fetch latest report with penalty: ${response.statusCode}, body: ${response.body}");
        throw Exception('Failed to fetch latest report with penalty');
      }
    } catch (e) {
      print("Error fetching latest report with penalty: $e");
      rethrow;
    }
  }
}
