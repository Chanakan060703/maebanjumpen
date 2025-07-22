import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/party_role.dart';

class Partyrolecontroller {
  Future <PartyRole?> getListPartyRole() async{
    var url = Uri.parse('$baseURL/maeban/party-roles');
    http.Response response = await http.get(url, headers: headers);

    if(response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      return PartyRole.fromJson(json.decode(utf8Body));
    } else {
      return null;
    }
  }

  Future <PartyRole?> addPartyRole(
    String email,
    String firstName,
    String lastName,
    String idCardNumber,
    String phoneNumber,
    String address,
    String picture,
    String accountStatus,
  ) async {
    Map data = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'idCardNumber': idCardNumber,
      'phoneNumber': phoneNumber,
      'address': address,
      'picture': picture,
      'accountStatus': accountStatus
    };

  var body = json.encode(data);
  var url = Uri.parse('$baseURL/maeban/party-roles');
  http.Response response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) { // หรือ 201 Created ถ้า Backend ส่งกลับ
    var jsonResponse = jsonDecode(response.body);
    return PartyRole.fromJson(jsonResponse);
  } else {
    print('Failed to add PartyRole: ${response.statusCode} - ${response.body}');
    return null;
  }
  }

  Future updatePartyRole(
    int id,
    String email,
    String firstName,
    String lastName,
    String idCardNumber,
    String phoneNumber,
    String address,
    String picture,
    String accountStatus,
  ) async {
    Map data = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'idCardNumber': idCardNumber,
      'phoneNumber': phoneNumber,
      'address': address,
      'picture': picture,
      'accountStatus': accountStatus
    };

    var body = json.encode(data);
    var url = Uri.parse('$baseURL/maeban/party-roles/$id');
    http.Response response = await http.put(url, headers: headers, body: body);
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse;
  }

  Future deletePartyRole(int id) async {
    var url = Uri.parse('$baseURL/maeban/party-roles/$id');
    http.Response response = await http.delete(url, headers: headers);
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
  
  Future<PartyRole?> getPartyRoleById(int id) async {
    var url = Uri.parse('$baseURL/maeban/party-roles/$id');
    http.Response response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final utf8Body = utf8.decode(response.bodyBytes);
      return PartyRole.fromJson(json.decode(utf8Body));
    } else {
      return null;
    }
  }
}