// lib/model/party_role.dart
import 'package:maebanjumpen/model/person.dart';

// ***** สำคัญมาก: Import ทุก Subclass Model จากไดเรกทอรี 'lib/model/' ที่ถูกต้อง *****
// ตรวจสอบ Path เหล่านี้ให้ถูกต้อง
import 'package:maebanjumpen/model/member.dart'; // Member extends PartyRole
import 'package:maebanjumpen/model/hirer.dart'; // Hirer extends Member
import 'package:maebanjumpen/model/housekeeper.dart'; // Housekeeper extends Member
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/account_manager.dart';

// คลาส Abstract สำหรับ PartyRole
abstract class PartyRole {
  final int? id;
  final Person? person;
  final String? type; // <<< เพิ่ม type field

  PartyRole({
    this.id,
    this.person,
    this.type, // <<< เพิ่ม type ใน constructor
  });

  factory PartyRole.fromJson(Map<String, dynamic> json) {
    // ใช้ 'type' field ที่มาจาก Backend เป็นหลักในการตัดสินใจ
    String? type = json['type'] as String?;

    if (type == 'housekeeper') {
      return Housekeeper.fromJson(json);
    } else if (type == 'hirer') {
      return Hirer.fromJson(json);
    } else if (type == 'admin') {
      return Admin.fromJson(json);
    } else if (type == 'accountManager') {
      return AccountManager.fromJson(json);
    } else if (type == 'member') { // ถ้า backend ส่ง type เป็น 'member'
      return Member.fromJson(json);
    }

    // Fallback logic หาก 'type' field ไม่ได้ให้ข้อมูลที่ชัดเจน
    // ควรพยายามทำให้ Backend ส่ง 'type' ที่ชัดเจนมาเสมอ
    if (json.containsKey('housekeeperSkills') ||
        json.containsKey('rating') ||
        json.containsKey('statusVerify')) {
      return Housekeeper.fromJson(json);
    }
    if (json.containsKey('hires') && json['hires'] is List) { // ตรวจสอบว่าเป็น List เพื่อความแม่นยำ
      return Hirer.fromJson(json);
    }
    if (json.containsKey('adminStatus')) {
      return Admin.fromJson(json);
    }
    if (json.containsKey('managerID')) {
      return AccountManager.fromJson(json);
    }

    // หากยังไม่สามารถระบุได้ ให้เป็น Member โดย default หรือ throw error
    if (json.containsKey('person') && json['person'] is Map<String, dynamic>) {
        // This suggests it's at least a Member or higher
        return Member.fromJson(json);
    }

    throw ArgumentError(
        'JSON ไม่ได้มี PartyRole type ที่ถูกต้อง และไม่สามารถเดาได้จาก properties ที่ให้มาใน JSON Response: $json');
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    // ส่ง type ที่มีอยู่แล้ว หรือกำหนดตาม subclass ถ้า type เป็น null
    if (type != null && type!.isNotEmpty) {
      data['type'] = type;
    } else {
        // หาก type เป็น null ให้พยายามเดา type จาก runtimeType
        if (this is Hirer) {
            data['type'] = 'hirer';
        } else if (this is Housekeeper) {
            data['type'] = 'housekeeper';
        } else if (this is Admin) {
            data['type'] = 'admin';
        } else if (this is AccountManager) {
            data['type'] = 'accountManager';
        } else if (this is Member) { // ตรวจสอบ Member เป็นอันสุดท้าย
            data['type'] = 'member';
        }
    }

    if (person != null) {
      data['person'] = person!.toJson();
    }
    return data;
  }

  // Abstract copyWith method
  PartyRole copyWith({
    int? id,
    Person? person,
    String? type,
  });
}