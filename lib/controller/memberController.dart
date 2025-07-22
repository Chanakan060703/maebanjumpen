import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/hirer.dart'; // *** เพิ่ม import นี้ ***

class MemberController with ChangeNotifier {
  List<Member> _members = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = baseURL;
  final Map<String, String> _headers = headers;

  MemberController();

  /// ดึงข้อมูล Member ทั้งหมดจาก API
  Future<void> fetchAllMembers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maeban/members'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        _members = jsonList.map((json) => PartyRole.fromJson(json as Map<String, dynamic>) as Member).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load members. Status: ${response.statusCode}, Body: ${response.body}';
        _members = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching members: $e';
      _members = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ดึงข้อมูล Member ตาม ID
  Future<Member?> fetchMemberById(String id) async {
    _isLoading = true;
    _errorMessage = null;

    Member? result;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maeban/members/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
        result = PartyRole.fromJson(json) as Member; // PartyRole.fromJson ควรจะส่งคืน Member หรือ subclass ที่เหมาะสม
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load Member with ID $id: ${response.statusCode} - ${response.body}';
        result = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching Member: $e';
      result = null;
    } finally {
      _isLoading = false;
    }
    return result;
  }

  // *** เพิ่ม method นี้สำหรับดึง Hirer โดยเฉพาะ ***
  Future<Hirer?> getHirerById(String hirerId) async {
    _isLoading = true; // อาจจะไม่จำเป็นต้องเซ็ต isLoading ของ Controller ทั้งหมด
    _errorMessage = null;

    Hirer? hirer;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maeban/members/$hirerId'), // endpoint อาจจะใช้ /members/$id เหมือนเดิม หรือมี /hirers/$id ถ้า Backend แยก
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
        // ตรวจสอบ type ของ PartyRole ก่อน cast เป็น Hirer
        if (json['@type'] == 'Hirer') { // สมมติว่ามี field @type ใน JSON ที่ระบุประเภท
          hirer = Hirer.fromJson(json); // ใช้ Hirer.fromJson โดยตรงถ้ามี
          // หรือถ้า PartyRole.fromJson จัดการ polymorphism แล้ว
          // hirer = PartyRole.fromJson(json) as Hirer;
        } else {
          _errorMessage = 'Fetched data is not a Hirer type.';
        }
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load Hirer with ID $hirerId: ${response.statusCode} - ${response.body}';
        hirer = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching Hirer: $e';
      hirer = null;
    } finally {
      _isLoading = false; // รีเซ็ตสถานะโหลด
    }
    return hirer;
  }


  /// สร้าง Member ใหม่
  Future<bool> createMember(Member newMember) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/maeban/members'),
        headers: {
          ..._headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(newMember.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ไม่ต้อง fetchAllMembers() ทันทีถ้า UI ไม่ได้แสดงรายการทั้งหมด
        // อาจจะเพิ่ม newMember เข้าไปใน _members ถ้าต้องการอัปเดต UI ทันที
        return true;
      } else {
        _errorMessage = 'Failed to create member: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// อัปเดต Member
  Future<bool> updateMember(String id, Member updatedMember) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/maeban/members/$id'),
        headers: {
          ..._headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedMember.toJson()),
      );

      if (response.statusCode == 200) {
        // ไม่ต้อง fetchAllMembers() ทันที
        // อาจจะอัปเดต _members รายการเดียวที่ถูกแก้
        return true;
      } else {
        _errorMessage = 'Failed to update member: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ลบ Member
  Future<bool> deleteMember(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/maeban/members/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        // ไม่ต้อง fetchAllMembers() ทันที
        // อาจจะลบ member ออกจาก _members
        return true;
      } else {
        _errorMessage = 'Failed to delete member: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}