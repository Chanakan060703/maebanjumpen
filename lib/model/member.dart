// lib/model/member.dart
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/person.dart';

class Member extends PartyRole {
  final double? balance;

  Member({
    super.id,
    super.person,
    String? type, // เพิ่ม type ใน constructor
    this.balance,
  }) : super(type: type ?? 'member');

  factory Member.fromJson(Map<String, dynamic> json) {
    final Person? personFromJson =
        json['person'] != null
            ? Person.fromJson(json['person'] as Map<String, dynamic>)
            : null;

    return Member(
      id: json['id'] as int?,
      person: personFromJson,
      balance: (json['balance'] as num?)?.toDouble(),
      type:
          json['type'] as String? ??
          'member', // <<< ดึงค่า 'type' จาก JSON ด้วย
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // <<< ควรเป็น Map<String, dynamic> toJson()
    final Map<String, dynamic> data = super.toJson();
    data['balance'] = balance;
    return data;
  }

  @override
  Member copyWith({int? id, Person? person, String? type, double? balance}) {
    return Member(
      id: id ?? this.id,
      person: person ?? this.person,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'Member(id: $id, person: $person, type: $type, balance: $balance)';
  }
}
