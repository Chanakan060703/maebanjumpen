import 'housekeeper.dart';
import 'skill_level_tier.dart';
import 'skill_type.dart';

class HousekeeperSkill {
  int? skillId;

  // ✅ เพิ่ม field ID ที่ Backend DTO ต้องการสำหรับการส่งข้อมูลเข้า (Input DTO)
  int? skillLevelTierId;
  int? housekeeperId;
  int? skillTypeId;

  SkillLevelTier? skillLevelTier;
  Housekeeper? housekeeper; // อาจจะใช้เป็น ID แทนในการส่งออก
  SkillType? skillType;
  int? totalHiresCompleted;
  double? pricePerDay;

  HousekeeperSkill({
    this.skillId,
    this.skillLevelTierId,
    this.housekeeperId,
    this.skillTypeId,
    this.skillLevelTier,
    this.housekeeper,
    this.skillType,
    this.totalHiresCompleted,
    this.pricePerDay,
  });

  factory HousekeeperSkill.fromJson(Map<String, dynamic> json) {
    return HousekeeperSkill(
      skillId: json['skillId'] as int?,

      // ✅ ดึงค่า ID ที่ Backend อาจจะส่งมาโดยตรง
      skillLevelTierId: json['skillLevelTierId'] as int?,

      housekeeperId: json['housekeeperId'] as int?,

      skillTypeId: json['skillTypeId'] as int?,

      skillLevelTier:
          json['skillLevelTier'] != null &&
                  json['skillLevelTier'] is Map<String, dynamic>
              ? SkillLevelTier.fromJson(
                json['skillLevelTier'] as Map<String, dynamic>,
              )
              : null,

      // หาก Housekeeper ถูกส่งมาเป็น object เต็ม, อาจเกิด Recursion ได้
      housekeeper:
          json['housekeeper'] != null &&
                  json['housekeeper'] is Map<String, dynamic>
              ? Housekeeper.fromJson(
                json['housekeeper'] as Map<String, dynamic>,
              )
              : null,

      skillType:
          json['skillType'] != null && json['skillType'] is Map<String, dynamic>
              ? SkillType.fromJson(json['skillType'] as Map<String, dynamic>)
              : null,

      totalHiresCompleted: json['totalHiresCompleted'] as int?,

      pricePerDay:
          json['pricePerDay'] != null
              ? (json['pricePerDay'] as num).toDouble()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,

      // ✅ ส่ง ID กลับไป (ถ้ามี)
      'skillLevelTierId': skillLevelTierId,

      'housekeeperId': housekeeperId,

      'skillTypeId': skillTypeId,

      // Fallback ในกรณีที่ ID เป็น null แต่มี Object เต็ม
      'skillLevelTier': skillLevelTier?.id, // ส่งแค่ ID ของ Level Tier

      'skillType': skillType?.skillTypeId, // ส่งแค่ ID ของ Skill Type

      'totalHiresCompleted': totalHiresCompleted,

      'pricePerDay': pricePerDay,
    };
  }

  HousekeeperSkill copyWith({
    int? skillId,

    int? skillLevelTierId,

    int? housekeeperId,

    int? skillTypeId,

    SkillLevelTier? skillLevelTier,

    Housekeeper? housekeeper,

    SkillType? skillType,

    int? totalHiresCompleted,

    double? pricePerDay,
  }) {
    return HousekeeperSkill(
      skillId: skillId ?? this.skillId,

      skillLevelTierId: skillLevelTierId ?? this.skillLevelTierId,

      housekeeperId: housekeeperId ?? this.housekeeperId,

      skillTypeId: skillTypeId ?? this.skillTypeId,

      skillLevelTier: skillLevelTier ?? this.skillLevelTier,

      housekeeper: housekeeper ?? this.housekeeper,

      skillType: skillType ?? this.skillType,

      totalHiresCompleted: totalHiresCompleted ?? this.totalHiresCompleted,

      pricePerDay: pricePerDay ?? this.pricePerDay,
    );
  }
}
