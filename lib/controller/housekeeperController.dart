import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/review.dart'; // import Review model
import 'package:maebanjumpen/model/hire.dart'; // import Hire model

class HousekeeperController {
  const HousekeeperController();

  // ***************************************************************
  // *** เมธอดที่เพิ่มเข้ามาเพื่อแก้ไขข้อผิดพลาด 'undefined_method' ***
  // ***************************************************************

  // ประกาศเป็น static เพื่อให้เรียกใช้ได้โดยตรงจากชื่อคลาส (HousekeeperController.fetch...)
  // เมธอดนี้จะเรียกใช้ getHousekeeperById ที่มีอยู่แล้วเพื่อดึงข้อมูลรายละเอียดแม่บ้าน
  static Future<Housekeeper?> fetchHousekeeperWithDetails(int id) async {
    // ต้องสร้าง instance ชั่วคราวเพื่อเรียกใช้เมธอด getHousekeeperById

    // ซึ่งไม่ได้เป็น static (เป็น non-static)

    final controller = HousekeeperController();

    try {
      // เมธอด getHousekeeperById ของคุณมีการเรียก endpoint เดียวกัน

      // และจัดการการแปลงข้อมูล HousekeeperDetailDTO ให้เป็น Housekeeper Model แล้ว

      return await controller.getHousekeeperById(id);
    } catch (e) {
      print("Error in static fetchHousekeeperWithDetails: $e");

      return null;
    }
  }
  // ***************************************************************

  Future<List<Housekeeper>?> getListHousekeeper() async {
    try {
      var url = Uri.parse('$baseURL/maeban/housekeepers');

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);

        if (rawData.trim().isEmpty || rawData.trim() == '[]') {
          return [];
        }

        final data = json.decode(rawData) as List;

        final List<Housekeeper> housekeepers =
            data
                .map((e) => Housekeeper.fromJson(e as Map<String, dynamic>))
                .toList();

        return housekeepers;
      }

      return null;
    } catch (e) {
      print("Error fetching list of housekeepers: $e");

      return null;
    }
  }

  // *** NEW: เมธอดสำหรับดึงรายการที่ยังไม่ได้รับการยืนยัน/Null Status ***
  Future<List<Housekeeper>> getNotVerifiedHousekeepers() async {
    try {
      var url = Uri.parse('$baseURL/maeban/housekeepers/unverified-or-null');

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);

        if (rawData.trim().isEmpty || rawData.trim() == '[]') {
          return [];
        }

        final data = json.decode(rawData) as List;

        final List<Housekeeper> housekeepers =
            data
                .map((e) => Housekeeper.fromJson(e as Map<String, dynamic>))
                .toList();

        return housekeepers;
      } else {
        throw Exception(
          'Failed to load unverified or null status housekeepers: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Error fetching unverified or null status housekeepers: $e',
      );
    }
  }

  Future<Housekeeper?> updateHousekeeperStatus(
    int housekeeperId,
    String newStatus,
  ) async {
    try {
      Housekeeper? originalHousekeeper = await getHousekeeperById(
        housekeeperId,
      );

      if (originalHousekeeper == null) {
        throw Exception('Housekeeper with ID $housekeeperId not found.');
      }

      Housekeeper updatedHousekeeper = originalHousekeeper.copyWith(
        statusVerify: newStatus,
      );

      return await updateHousekeeper(housekeeperId, updatedHousekeeper);
    } catch (e) {
      print("Error updating housekeeper status: $e");

      rethrow;
    }
  }

  Future<List<HousekeeperSkill>> getHousekeeperSkills(int housekeeperId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/maeban/housekeeper-skills/$housekeeperId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> skillsData = jsonDecode(utf8.decode(response.bodyBytes));

        return skillsData
            .map<HousekeeperSkill>(
              (skill) =>
                  HousekeeperSkill.fromJson(skill as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load housekeeper skills: ${response.statusCode}',
        );
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

  Future<Housekeeper?> updateHousekeeper(
    int id,
    Housekeeper housekeeper,
  ) async {
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

        (requestBody['person'] as Map<String, dynamic>).remove(
          'accountCreationDate',
        );
      }

      var url = Uri.parse('$baseURL/maeban/housekeepers/$id');

      http.Response response = await http.put(
        url,

        headers: headers,

        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print("Housekeeper update successful!");

        return Housekeeper.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else {
        print(
          "Failed to update housekeeper. Status code: ${response.statusCode}",
        );

        print("Response body: ${utf8.decode(response.bodyBytes)}");

        throw Exception("Failed to update housekeeper: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating housekeeper: $e");

      rethrow;
    }
  }

  // เมธอดสำหรับอัปเดต Rating ของแม่บ้าน
  Future<Housekeeper?> updateHousekeeperRating(
    int housekeeperId,
    double newRating,
  ) async {
    try {
      Housekeeper? originalHousekeeper = await getHousekeeperById(
        housekeeperId,
      );

      if (originalHousekeeper == null) {
        print(
          'Housekeeper with ID $housekeeperId not found for rating update.',
        );

        return null;
      }
      Housekeeper updatedHousekeeper = originalHousekeeper.copyWith(
        rating: newRating,
      );
      return await updateHousekeeper(housekeeperId, updatedHousekeeper);
    } catch (e) {
      print("Error updating housekeeper rating: $e");

      return null;
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
      // Endpoint เดียวกันนี้ใน Java Controller คืนค่า HousekeeperDetailDTO

      var url = Uri.parse('$baseURL/maeban/housekeepers/$id');

      http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);

        // เนื่องจาก Housekeeper Model ใน Dart มีฟิลด์ jobsCompleted และ reviews

        // Housekeeper.fromJson จึงสามารถรองรับ HousekeeperDetailDTO ได้โดยตรง

        return Housekeeper.fromJson(
          json.decode(utf8Body) as Map<String, dynamic>,
        );
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
