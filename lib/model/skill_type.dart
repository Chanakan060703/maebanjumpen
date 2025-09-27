// lib/model/skill_type.dart
class SkillType {
  int? skillTypeId;
  String? skillTypeName;
  String? skillTypeDetail;
  double? basePricePerHour; // เพิ่ม field นี้

  SkillType({this.skillTypeId, this.skillTypeName, this.skillTypeDetail, this.basePricePerHour});

  factory SkillType.fromJson(Map<String, dynamic> json) {
    return SkillType(
      skillTypeId: json['skillTypeId'],
      skillTypeName: json['skillTypeName'],
      skillTypeDetail: json['skillTypeDetail'],
      basePricePerHour: (json['basePricePerHour'] as num?)?.toDouble(), // แปลงเป็น double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillTypeId': skillTypeId,
      'skillTypeName': skillTypeName,
      'skillTypeDetail': skillTypeDetail,
      'basePricePerHour': basePricePerHour,
    };
  }

  SkillType copyWith({
    int? skillTypeId,
    String? skillTypeName,
    String? skillTypeDetail,
    double? basePricePerHour,
  }) {
    return SkillType(
      skillTypeId: skillTypeId ?? this.skillTypeId,
      skillTypeName: skillTypeName ?? this.skillTypeName,
      skillTypeDetail: skillTypeDetail ?? this.skillTypeDetail,
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
    );
  }
}