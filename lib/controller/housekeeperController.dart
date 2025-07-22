import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';

class HousekeeperController {

  const HousekeeperController(); // <<< เพิ่ม const constructor กลับไป

  Future<List<Housekeeper>?> getListHousekeeper() async {
    try {
      var url = Uri.parse('$baseURL/maeban/housekeepers');
      print('HousekeeperController: Fetching from URL: $url');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        print('HousekeeperController: Raw response data (status 200): $rawData');

        if (rawData.trim().isEmpty || rawData.trim() == '[]') {
          print('HousekeeperController: Response data is empty or empty array.');
          return [];
        }

        final data = json.decode(rawData) as List;
        print('HousekeeperController: Decoded JSON list length: ${data.length}');

        for (var i = 0; i < data.length; i++) {
          print('HousekeeperController: Item $i data before fromJson: ${data[i]}');
        }

        final List<Housekeeper> housekeepers = data.map((e) => Housekeeper.fromJson(e as Map<String, dynamic>)).toList();
        print('HousekeeperController: Successfully parsed ${housekeepers.length} housekeepers.');

        if (housekeepers.isNotEmpty) {
          final firstHousekeeper = housekeepers.first;
          print('HousekeeperController: First housekeeper details -');
          print('   ID: ${firstHousekeeper.id}');
          print('   First Name: ${firstHousekeeper.person?.firstName}');
          print('   Last Name: ${firstHousekeeper.person?.lastName}');
          print('   Picture URL: ${firstHousekeeper.person?.pictureUrl}');
          print('   Daily Rate: ${firstHousekeeper.dailyRate}');
          print('   Rating: ${firstHousekeeper.rating}');
          print('   Status Verify: ${firstHousekeeper.statusVerify}');
          print('   Skills: ${firstHousekeeper.housekeeperSkills?.map((s) => s.skillType?.skillTypeName).join(', ')}');
        }

        return housekeepers;
      }
      print('HousekeeperController: Failed to fetch housekeepers. Status code: ${response.statusCode}, Body: ${utf8.decode(response.bodyBytes)}');
      return null;
    } catch (e) {
      print('HousekeeperController: Error fetching housekeepers: $e');
      return null;
    }
  }

  Future<List<Housekeeper>> getNotVerifiedHousekeepers() async {
    try {
      var url = Uri.parse('$baseURL/maeban/housekeepers/unverified-or-null');
      print('HousekeeperController: Fetching unverified or null status housekeepers from URL: $url');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        print('HousekeeperController: Raw response data (unverified or null): $rawData');

        if (rawData.trim().isEmpty || rawData.trim() == '[]') {
          print('HousekeeperController: No unverified or null status housekeepers found.');
          return [];
        }

        final data = json.decode(rawData) as List;
        final List<Housekeeper> housekeepers = data.map((e) => Housekeeper.fromJson(e as Map<String, dynamic>)).toList();
        print('HousekeeperController: Successfully parsed ${housekeepers.length} unverified or null status housekeepers.');
        return housekeepers;
      } else {
        print('HousekeeperController: Failed to fetch unverified or null status housekeepers. Status code: ${response.statusCode}, Body: ${utf8.decode(response.bodyBytes)}');
        throw Exception('Failed to load unverified or null status housekeepers: ${response.statusCode}');
      }
    } catch (e) {
      print('HousekeeperController: Error fetching unverified or null status housekeepers: $e');
      throw Exception('Error fetching unverified or null status housekeepers: $e');
    }
  }

  Future<Housekeeper?> updateHousekeeperStatus(int housekeeperId, String newStatus) async {
    try {
      Housekeeper? originalHousekeeper = await getHousekeeperById(housekeeperId);
      if (originalHousekeeper == null) {
        throw Exception('Housekeeper with ID $housekeeperId not found.');
      }

      // ใช้ copyWith เพื่อสร้างสำเนาและอัปเดต statusVerify
      Housekeeper updatedHousekeeper = originalHousekeeper.copyWith(statusVerify: newStatus);

      // เรียกใช้เมธอด updateHousekeeper เดิมเพื่อส่งข้อมูลไป Backend
      return await updateHousekeeper(housekeeperId, updatedHousekeeper);
    } catch (e) {
      print("Error updating housekeeper status: $e");
      rethrow;
    }
  }

  Future<List<HousekeeperSkill>> getHousekeeperSkills(int housekeeperId) async {
    try {
      final response = await http.get(Uri.parse('$baseURL/maeban/housekeeper-skills/$housekeeperId'), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> skillsData = jsonDecode(utf8.decode(response.bodyBytes));
        return skillsData.map<HousekeeperSkill>((skill) => HousekeeperSkill.fromJson(skill as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load housekeeper skills: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching housekeeper skills: $e");
      throw Exception('Error fetching housekeeper skills: $e');
    }
  }

  Future addHousekeeper(
    String email,
    String firstName,
    String lastName,
    String idCardNumber,
    String phoneNumber,
    String address,
    String picture,
    String accountStatus,
    double dailyRate,
  ) async {
    Map<String, dynamic> requestBody = {
      'person': { 
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'idCardNumber': idCardNumber,
        'phoneNumber': phoneNumber,
        'address': address,
        'pictureUrl': picture,
        'accountStatus': accountStatus,
      },
      'dailyRate': dailyRate,
    };

    var body = json.encode(requestBody);
    var url = Uri.parse('$baseURL/maeban/housekeepers');
    http.Response response = await http.post(url, headers: headers, body: body);
    var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return jsonResponse;
  }

  Future<Housekeeper?> updateHousekeeper(int id, Housekeeper housekeeper) async {
    try {
      final Map<String, dynamic> requestBody = housekeeper.toJson();

      requestBody.remove('id'); 
      requestBody.remove('username');
      requestBody.remove('hires');
      requestBody.remove('housekeeperSkills');
      requestBody.remove('rating'); 

      if (requestBody.containsKey('person')) {
          (requestBody['person'] as Map<String, dynamic>).remove('personId'); 
          (requestBody['person'] as Map<String, dynamic>).remove('login'); 
          (requestBody['person'] as Map<String, dynamic>).remove('accountCreationDate'); 
      }

      var url = Uri.parse('$baseURL/maeban/housekeepers/$id');
      http.Response response = await http.put(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print("Housekeeper update successful!");
        return Housekeeper.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        print("Failed to update housekeeper. Status code: ${response.statusCode}");
        print("Response body: ${utf8.decode(response.bodyBytes)}");
        throw Exception("Failed to update housekeeper: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating housekeeper: $e");
      rethrow;
    }
  }

  Future deleteHousekeeper(int id) async {
    var url = Uri.parse('$baseURL/maeban/housekeepers/$id');
    http.Response response = await http.delete(url, headers: headers);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete housekeeper: ${response.statusCode}');
    }
  }

  Future<Housekeeper?> getHousekeeperById(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/housekeepers/$id');
      http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return Housekeeper.fromJson(json.decode(utf8Body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        print('Housekeeper with ID $id not found.');
        return null;
      } else {
        throw Exception('Failed to load housekeeper: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching housekeeper by ID: $e");
      return null;
    }
  }
}
