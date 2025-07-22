// lib/model/housekeeper.dart
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/person.dart';

class Housekeeper extends Member {
  final String? lineId;
  final String? facebookLink;
  final String? photoVerifyUrl;
  String? statusVerify;
  final double? rating;
  final List<Hire>? hires;
  final List<HousekeeperSkill>? housekeeperSkills;
  final String? username;
  final double? dailyRate;

  Housekeeper({
    this.facebookLink,
    this.lineId,
    this.photoVerifyUrl,
    this.statusVerify,
    this.rating,
    this.hires,
    this.housekeeperSkills,
    this.username,
    super.id,
    super.person,
    String? type, // <<< เพิ่ม type ตรงนี้
    super.balance,
    this.dailyRate,
  }) : super(type: type ?? 'housekeeper'); // <<< ส่ง type ไปยัง super constructor

  factory Housekeeper.fromJson(Map<String, dynamic> json) {
    var hiresList = json['hires'] as List?;
    List<Hire>? parsedHires;
    if (hiresList != null) {
      parsedHires = hiresList.map((i) => Hire.fromJson(i)).toList();
    }

    var skillsList = json['housekeeperSkills'] as List?;
    List<HousekeeperSkill>? parsedSkills;
    if (skillsList != null) {
      parsedSkills = skillsList.map((i) => HousekeeperSkill.fromJson(i as Map<String, dynamic>)).toList();
    }

    final Person? personFromJson = json['person'] != null
        ? Person.fromJson(json['person'] as Map<String, dynamic>)
        : null;

    return Housekeeper(
      id: json['id'] as int?,
      person: personFromJson,
      type: json['type'] as String?, // <<< ดึง type จาก JSON
      balance: (json['balance'] as num?)?.toDouble(),
      photoVerifyUrl: json['photoVerifyUrl'] as String?,
      statusVerify: json['statusVerify'] as String?,
      rating: json['rating']?.toDouble(),
      hires: parsedHires,
      housekeeperSkills: parsedSkills,
      username: personFromJson?.login?.username,
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['facebookLink'] = facebookLink;
    data['lineId'] = lineId;
    data['photoVerifyUrl'] = photoVerifyUrl;
    data['statusVerify'] = statusVerify;
    data['rating'] = rating;
    data['dailyRate'] = dailyRate;
    return data;
  }

  @override
  Housekeeper copyWith({
    int? id,
    Person? person,
    String? type,
    double? balance,
    String? photoVerifyUrl,
    String? statusVerify,
    double? rating,
    List<Hire>? hires,
    List<HousekeeperSkill>? housekeeperSkills,
    String? username,
    String? lineId,
    String? facebookLink,
    String? bankAccountNumber,
    String? bankAccountName,
    double? dailyRate,
  }) {
    final Member memberCopy = super.copyWith(
      id: id,
      person: person,
      type: type,
      balance: balance,
    );

    return Housekeeper(
      id: memberCopy.id,
      person: memberCopy.person,
      type: memberCopy.type, // <<< ใช้ type จาก memberCopy
      balance: memberCopy.balance,
      photoVerifyUrl: photoVerifyUrl ?? this.photoVerifyUrl,
      statusVerify: statusVerify ?? this.statusVerify,
      rating: rating ?? this.rating,
      hires: hires ?? this.hires,
      housekeeperSkills: housekeeperSkills ?? this.housekeeperSkills,
      username: username ?? this.username,
      lineId: lineId ?? this.lineId,
      facebookLink: facebookLink ?? this.facebookLink,
      dailyRate: dailyRate ?? this.dailyRate,
    );
  }
}