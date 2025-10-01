import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/person.dart'; // ตรวจสอบว่ามี Person model ที่ถูกต้อง

class PersonController {
  const PersonController(); // เพิ่ม const constructor

  Future<List<Person>?> getListPersons() async {
    try {
      var url = Uri.parse(
        '$baseURL/maeban/persons',
      ); // ใช้ string interpolation

      http.Response response = await http.get(url, headers: headers);

      print('getListPersons response status: ${response.statusCode}');

      print('getListPersons response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final utf8body = utf8.decode(response.bodyBytes);

        if (utf8body.isEmpty || utf8body.trim() == '[]') {
          return []; // คืนค่า empty list ถ้าไม่มีข้อมูล
        }

        List<dynamic> jsonList = json.decode(utf8body);

        List<Person> listPerson =
            jsonList
                .map((e) => Person.fromJson(e as Map<String, dynamic>))
                .toList();

        return listPerson;
      } else {
        throw Exception('Failed to load persons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting list of persons: $e');

      return null;
    }
  }

  Future<Person?> getPersonById(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/persons/$id');

      http.Response response = await http.get(url, headers: headers);

      print('getPersonById response status: ${response.statusCode}');

      print('getPersonById response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final utf8body = utf8.decode(response.bodyBytes);

        Map<String, dynamic> jsonMap = json.decode(utf8body);

        Person person = Person.fromJson(jsonMap);

        return person;
      } else if (response.statusCode == 404) {
        print('Person with ID $id not found.');

        return null;
      } else {
        throw Exception('Failed to load person by ID: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting person by ID: $e');

      return null;
    }
  }

  // แก้ไข: รับ Person object โดยตรง
  Future<Person?> addPerson(Person person) async {
    try {
      var url = Uri.parse('$baseURL/maeban/persons');

      var body = json.encode(person.toJson()); // ใช้ toJson() ของ Person model

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('addPerson response status: ${response.statusCode}');

      print('addPerson response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        print("Person creation successful!");

        return Person.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> errorBody = json.decode(
          utf8.decode(response.bodyBytes),
        );

        final String errorMessage =
            errorBody['message'] ?? 'Conflict: Duplicate data.';

        throw Exception(errorMessage);
      } else {
        print("Failed to create person. Status code: ${response.statusCode}");

        print("Response body: ${utf8.decode(response.bodyBytes)}");

        throw Exception("Failed to create person: ${response.statusCode}");
      }
    } catch (e) {
      print("Error adding person: $e");

      rethrow;
    }
  }

  // แก้ไข: รับ Person object โดยตรง
  Future<Person?> updatePerson(int id, Person person) async {
    try {
      var url = Uri.parse(
        '$baseURL/maeban/persons/$id',
      ); // URL ก็ยังใช้ ID จาก path

      var body = json.encode(person.toJson()); // ใช้ toJson() ของ Person model

      http.Response response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      print('updatePerson response status: ${response.statusCode}');

      print('updatePerson response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        print("Person update successful!");

        return Person.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> errorBody = json.decode(
          utf8.decode(response.bodyBytes),
        );

        final String errorMessage =
            errorBody['message'] ?? 'Conflict: Duplicate data.';

        throw Exception(errorMessage);
      } else {
        print("Failed to update person. Status code: ${response.statusCode}");

        print("Response body: ${utf8.decode(response.bodyBytes)}");

        throw Exception("Failed to update person: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating person: $e");

      rethrow;
    }
  }

  // 💡 NEW: เมธอดสำหรับอัปเดตสถานะบัญชี (ตรงกับ Java Endpoint)
  // PUT /maeban/persons/{personId}/account-status?status={newStatus}
  Future<void> updateAccountStatus(int personId, String newStatus) async {
    try {
      var url = Uri.parse(
        '$baseURL/maeban/persons/$personId/account-status',
      ).replace(
        queryParameters: {
          'status': newStatus, // ส่งสถานะใหม่เป็น Query Parameter
        },
      );

      http.Response response = await http.put(
        url,

        headers: headers,

        // ส่ง body เปล่าเพราะข้อมูลถูกส่งผ่าน URL (Query Parameter และ Path Variable)
        body: json.encode({}),
      );

      print('updateAccountStatus response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          "Person account status update successful for ID $personId to $newStatus!",
        );
      } else {
        print(
          "Failed to update person account status. Status code: ${response.statusCode}",
        );

        print("Response body: ${utf8.decode(response.bodyBytes)}");

        throw Exception(
          "Failed to update person account status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error updating person account status: $e");

      rethrow;
    }
  }

  // เปลี่ยนชื่อเมธอด
  Future<void> deletePerson(int id) async {
    try {
      var url = Uri.parse('$baseURL/maeban/persons/$id');

      http.Response response = await http.delete(url, headers: headers);

      print('deletePerson response status: ${response.statusCode}');

      print('deletePerson response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete person: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting person: $e');

      rethrow;
    }
  }
}
