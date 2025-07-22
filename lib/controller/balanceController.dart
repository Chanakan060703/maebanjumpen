import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'dart:convert';

class BalanceController {
  Future<double> topUpBalance(int memberId, double amount) async {
    final url = Uri.parse('$baseURL/members/$memberId/topup');
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['newBalance'] as double;
    }
    throw Exception('Failed to top up balance');
  }

  Future<double> withdrawBalance(int memberId, double amount) async {
    final url = Uri.parse('$baseURL/members/$memberId/withdraw');
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['newBalance'] as double;
    }
    throw Exception('Failed to withdraw balance');
  }
}