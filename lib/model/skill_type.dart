// สำหรับ jsonEncode ใน toJson

class SkillType {
  final int? skillTypeId;
  final String? skillTypeName; // เปลี่ยนเป็น nullable
  final String? skillTypeDetail; // เปลี่ยนเป็น nullable

  SkillType({
    this.skillTypeId,
    this.skillTypeName, // ลบ required ออก
    this.skillTypeDetail, // ลบ required ออก
  });

  factory SkillType.fromJson(Map<String, dynamic> json) {
    return SkillType(
      skillTypeId: json['skillTypeId'],
      skillTypeName: json['skillTypeName'] as String?, // Cast เป็น String?
      skillTypeDetail: json['skillTypeDetail'] as String?, // Cast เป็น String?
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['skillTypeId'] = skillTypeId;
    data['skillTypeName'] = skillTypeName;
    data['skillTypeDetail'] = skillTypeDetail;
    return data;
  }
}