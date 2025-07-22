import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/person.dart';

class AccountManager extends PartyRole {
  final int? managerID; // เปลี่ยนเป็น int? เพื่อให้ตรงกับ Integer ของ Backend

  AccountManager({
    this.managerID,
    super.id,
    super.person,
    String? type,
  }) : super(
          type: type ?? 'accountManager',
        );

  factory AccountManager.fromJson(Map<String, dynamic> json) {
    // แก้ไขการ parse ออบเจกต์ 'person' ที่ซ้อนอยู่
    final Person? parsedPerson = json['person'] != null
        ? Person.fromJson(json['person'] as Map<String, dynamic>)
        : null;

    return AccountManager(
      id: json['id'] as int?,
      person: parsedPerson, // ใช้ออบเจกต์ Person ที่ parse มาอย่างถูกต้อง
      managerID: json['managerID'] as int?, // เปลี่ยนเป็น int?
      type: json['type'] as String?, // ตรวจสอบให้แน่ใจว่าได้รับ 'type' จาก JSON ถ้ามี
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['managerID'] = managerID;
    return data;
  }

  @override
  AccountManager copyWith({
    int? id,
    Person? person,
    String? type,
    int? managerID, // เปลี่ยนเป็น int?
  }) {
    return AccountManager(
      id: id ?? this.id,
      person: person ?? this.person,
      type: type ?? this.type,
      managerID: managerID ?? this.managerID,
    );
  }

  @override
  String toString() {
    return 'AccountManager(id: $id, person: $person, managerID: $managerID, type: $type)';
  }
}