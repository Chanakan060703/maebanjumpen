// lib/model/hirer.dart
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/person.dart';

class Hirer extends Member {
  final List<Hire>? hires;
  final String? username;

  Hirer({
    this.hires,
    this.username,
    super.id,
    super.person,
    String? type, // <<< เพิ่ม type ตรงนี้
    super.balance,
  }) : super(
          type: type ?? 'hirer',
        );

  factory Hirer.fromJson(Map<String, dynamic> json) {
    var hiresList = json['hires'] as List?;
    List<Hire>? parsedHires;
    if (hiresList != null) {
      parsedHires = hiresList.map((i) => Hire.fromJson(i)).toList();
    }

    final Person? personFromJson = json['person'] != null
        ? Person.fromJson(json['person'] as Map<String, dynamic>)
        : null;

    return Hirer(
      id: json['id'] as int?,
      person: personFromJson,
      type: json['type'] as String?, // <<< ดึง type จาก JSON
      balance: (json['balance'] as num?)?.toDouble(),
      hires: parsedHires,
      username: personFromJson?.login?.username,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    // super.toJson() ควรจะจัดการ 'type' ให้แล้ว
    data['username'] = username;
    return data;
  }

  @override
  Hirer copyWith({
    int? id,
    Person? person,
    String? type,
    double? balance,
    List<Hire>? hires,
    String? username,
  }) {
    final Member memberCopy = super.copyWith(
      id: id,
      person: person,
      type: type,
      balance: balance,
    );

    return Hirer(
      id: memberCopy.id,
      person: memberCopy.person,
      type: memberCopy.type, // <<< ใช้ type จาก memberCopy
      balance: memberCopy.balance,
      hires: hires ?? this.hires,
      username: username ?? this.username,
    );
  }
}