class SkillLevelTier {
  final int? id;
  final String? skillLevelName;
  final int? minHiresForLevel;
  final double? priceMultiplier;
  final double? maxPricePerHourLimit;
  final double? minPricePerHourLimit; 

  SkillLevelTier({
    this.id,
    this.skillLevelName,
    this.minHiresForLevel,
    this.priceMultiplier,
    this.maxPricePerHourLimit,
    this.minPricePerHourLimit,
  });

  factory SkillLevelTier.fromJson(Map<String, dynamic> json) {
    return SkillLevelTier(
      id: json['id'] as int?,
      skillLevelName: json['skillLevelName'] as String?,
      minHiresForLevel: json['minHiresForLevel'] as int?,
      priceMultiplier: (json['priceMultiplier'] as num?)?.toDouble(),
      maxPricePerHourLimit: (json['maxPricePerHourLimit'] as num?)?.toDouble(),
      minPricePerHourLimit: (json['minPricePerHourLimit'] as num?)?.toDouble(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skillLevelName': skillLevelName,
      'minHiresForLevel': minHiresForLevel,
      'priceMultiplier': priceMultiplier,
      'maxPricePerHourLimit': maxPricePerHourLimit,
      'minPricePerHourLimit': minPricePerHourLimit,
    };
  }
}