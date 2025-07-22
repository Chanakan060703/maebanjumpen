import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/skill_type.dart';

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
      housekeeper: json['housekeeper'] != null
          ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
      skillType: json['skillType'] != null
          ? SkillType.fromJson(json['skillType'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['skillId'] = skillId;
    data['skillLevel'] = skillLevel;
    if (housekeeper != null) {
      data['housekeeper'] = housekeeper!.toJson();
    }
    if (skillType != null) {
      data['skillType'] = skillType!.toJson();
    }
    return data;
  }
}