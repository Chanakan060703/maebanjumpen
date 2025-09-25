import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

abstract class PartyRole {
  final int? id;
  final Person? person;
  final String? type;

  PartyRole({
    this.id,
    this.person,
    this.type,
  });

  factory PartyRole.fromJson(Map<String, dynamic> json) {
    String? type = json['type'] as String?;

    // ใช้ 'type' field ที่มาจาก Backend เป็นหลัก
    if (type == 'housekeeper') {
      return Housekeeper.fromJson(json);
    } else if (type == 'hirer') {
      return Hirer.fromJson(json);
    } else if (type == 'admin') {
      return Admin.fromJson(json);
    } else if (type == 'accountManager') {
      return AccountManager.fromJson(json);
    } else if (type == 'member') {
      return Member.fromJson(json);
    }

    // Fallback logic หาก 'type' field ไม่ได้ให้ข้อมูลที่ชัดเจน
    // ควรพยายามทำให้ Backend ส่ง 'type' ที่ชัดเจนมาเสมอ
    if (json.containsKey('housekeeperSkills') ||
        json.containsKey('rating') ||
        json.containsKey('statusVerify')) {
      return Housekeeper.fromJson(json);
    }
    // ตรวจสอบว่าเป็น List เพื่อความแม่นยำและป้องกัน error หาก hires เป็น null หรือไม่ใช่ List
    if (json.containsKey('hires') && json['hires'] is List) {
      return Hirer.fromJson(json);
    }
    if (json.containsKey('adminStatus')) {
      return Admin.fromJson(json);
    }
    if (json.containsKey('managerID')) {
      return AccountManager.fromJson(json);
    }

    // หากยังไม่สามารถระบุได้ ให้เป็น Member โดย default หรือ throw error
    // นี่คือ fallback ที่ปลอดภัยที่สุด
    if (json.containsKey('person') && json['person'] is Map<String, dynamic>) {
        debugPrint('Warning: PartyRole type not specified, defaulting to Member for JSON: $json');
        return Member.fromJson(json);
    }

    throw ArgumentError(
        'JSON ไม่ได้มี PartyRole type ที่ถูกต้อง และไม่สามารถเดาได้จาก properties ที่ให้มาใน JSON Response: $json');
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;

    // กำหนด type จาก instance type หาก type field เป็น null
    if (type != null && type!.isNotEmpty) {
      data['type'] = type;
    } else {
        if (this is Hirer) {
            data['type'] = 'hirer';
        } else if (this is Housekeeper) {
            data['type'] = 'housekeeper';
        } else if (this is Admin) {
            data['type'] = 'admin';
        } else if (this is AccountManager) {
            data['type'] = 'accountManager';
        } else if (this is Member) {
            data['type'] = 'member';
        } else {
            debugPrint('Warning: PartyRole cannot determine type for toJson. Defaulting to generic "partyRole".');
            data['type'] = 'partyRole'; // Fallback for unknown PartyRole type
        }
    }

    if (person != null) {
      data['person'] = person!.toJson();
    }
    return data;
  }

  @override
  PartyRole copyWith({
    int? id,
    Person? person,
    String? type,
  });
}