import 'package:maebanjumpen/model/housekeeper.dart'; // Import Housekeeper
import 'package:maebanjumpen/model/skill_type.dart'; // Import SkillType

class HousekeeperSkill {
  final int? skillId;
  final String? skillLevel;
  final Housekeeper? housekeeper;
  final SkillType? skillType;

  HousekeeperSkill({
    this.skillId,
    this.skillLevel,
    this.housekeeper,
    this.skillType,
  });

  factory HousekeeperSkill.fromJson(Map<String, dynamic> json) {
    return HousekeeperSkill(
      skillId: json['skillId'] as int?,
      skillLevel: json['skillLevel'] as String?,
      // ตรวจสอบว่า housekeeper เป็น Map ก่อน parse เพื่อหลีกเลี่ยง error ถ้า Backend ส่งแค่ ID
      housekeeper: json['housekeeper'] != null && json['housekeeper'] is Map<String, dynamic>
          ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
      // ตรวจสอบว่า skillType เป็น Map ก่อน parse
      skillType: json['skillType'] != null && json['skillType'] is Map<String, dynamic>
          ? SkillType.fromJson(json['skillType'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['skillId'] = skillId;
    data['skillLevel'] = skillLevel;
    // ส่งแค่ ID ของ housekeeper และ skillType กลับไป
    if (housekeeper != null && housekeeper!.id != null) {
      data['housekeeper'] = {'id': housekeeper!.id};
    } else {
      data['housekeeper'] = null;
    }
    if (skillType != null && skillType!.skillTypeId != null) {
      data['skillType'] = {'skillTypeId': skillType!.skillTypeId};
    } else {
      data['skillType'] = null;
    }
    return data;
  }
}