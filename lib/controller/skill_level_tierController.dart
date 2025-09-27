// lib/controller/skill_level_tierController.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart'; // ตรวจสอบเส้นทางให้ถูกต้อง
import 'package:maebanjumpen/model/skill_level_tier.dart'; // ตรวจสอบเส้นทางให้ถูกต้อง

class SkillLevelTierController {

  // ดึง SkillLevelTier ทั้งหมด
  Future<List<SkillLevelTier>?> getAllSkillLevelTiers() async {
    final url = Uri.parse('$baseURL/maeban/skill-level-tiers');
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(utf8Body);
        return jsonList.map((json) => SkillLevelTier.fromJson(json)).toList();
      } else {
        print('Failed to get all skill level tiers. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting all skill level tiers: $e');
      return null;
    }
  }

  // ดึง SkillLevelTier ด้วย ID
  Future<SkillLevelTier?> getSkillLevelTierById(int id) async {
    final url = Uri.parse('$baseURL/maeban/skill-level-tiers/$id');
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return SkillLevelTier.fromJson(jsonDecode(utf8Body));
      } else if (response.statusCode == 404) {
        print('SkillLevelTier with ID $id not found. Status code: 404');
        return null; // หรือ throw Exception('Not Found');
      }
      else {
        print('Failed to get skill level tier by ID. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting skill level tier by ID: $e');
      return null;
    }
  }

  // เพิ่ม SkillLevelTier ใหม่
  // โดยปกติข้อมูลนี้จะถูก Seed จาก Backend ไม่ได้สร้างจาก Client
  // แต่ถ้าจำเป็นต้องมี API นี้ ก็สามารถใช้ได้
  Future<SkillLevelTier?> addSkillLevelTier(SkillLevelTier newTier) async {
    final url = Uri.parse('$baseURL/maeban/skill-level-tiers');
    try {
      final body = json.encode(newTier.toJson());
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return SkillLevelTier.fromJson(jsonDecode(utf8Body));
      } else {
        print('Failed to add skill level tier. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding skill level tier: $e');
      return null;
    }
  }

  // อัปเดต SkillLevelTier ที่มีอยู่
  Future<SkillLevelTier?> updateSkillLevelTier(int id, SkillLevelTier updatedTier) async {
    final url = Uri.parse('$baseURL/maeban/skill-level-tiers/$id');
    try {
      final body = json.encode(updatedTier.toJson());
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        return SkillLevelTier.fromJson(jsonDecode(utf8Body));
      } else if (response.statusCode == 404) {
        print('SkillLevelTier with ID $id not found for update. Status code: 404');
        return null;
      } else {
        print('Failed to update skill level tier. Status code: ${response.statusCode}');
        print('Request body sent: $body');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating skill level tier: $e');
      return null;
    }
  }

  // ลบ SkillLevelTier
  Future<bool> deleteSkillLevelTier(int id) async {
    final url = Uri.parse('$baseURL/maeban/skill-level-tiers/$id');
    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content ก็ถือว่าสำเร็จ
        print('SkillLevelTier $id deleted successfully.');
        return true;
      } else {
        print('Failed to delete skill level tier. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting skill level tier: $e');
      return false;
    }
  }
}