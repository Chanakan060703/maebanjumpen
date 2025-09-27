import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/review.dart';
import 'package:maebanjumpen/model/report.dart';
import 'package:maebanjumpen/model/skill_type.dart';

class Hire {
  final int? hireId;
  final String? hireName;
  final String? hireDetail;
  final double? paymentAmount;
  final DateTime? hireDate;
  final DateTime? startDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? jobStatus;
  final List<String>? progressionImageUrls;

  // ✅ แก้ไข: เอา final ออกเพื่อให้สามารถกำหนดค่าได้ใน constructor
  List<int>? additionalSkillTypeIds;
  int? skillTypeId;
  final Hirer? hirer;
  final Housekeeper? housekeeper;
  final Review? review;
  final Report? report;
  final SkillType? skillType;

  Hire({
    this.hireId,
    this.hireName,
    this.hireDetail,
    this.paymentAmount,
    this.hireDate,
    this.startDate,
    this.startTime,
    this.endTime,
    this.location,
    this.jobStatus,
    this.progressionImageUrls,
    this.hirer,
    this.housekeeper,
    this.review,
    this.report,
    this.skillType,
    this.skillTypeId,
    this.additionalSkillTypeIds,
  });

  factory Hire.fromJson(Map<String, dynamic> json) {
    return Hire(
      hireId: json['hireId'] as int?,
      hireName: json['hireName'] as String?,
      hireDetail: json['hireDetail'] as String?,
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble(),
      hireDate: json['hireDate'] != null ? DateTime.tryParse(json['hireDate']) : null,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      jobStatus: json['jobStatus'] as String?,
      progressionImageUrls: (json['progressionImageUrls'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      // ✅ การรับค่าจาก JSON ควรใช้ skillType
      skillType: json['skillType'] != null && json['skillType'] is Map<String, dynamic>
          ? SkillType.fromJson(json['skillType'] as Map<String, dynamic>)
          : null,
      hirer: json['hirer'] != null && json['hirer'] is Map<String, dynamic>
          ? Hirer.fromJson(json['hirer'] as Map<String, dynamic>)
          : null,
      housekeeper: json['housekeeper'] != null && json['housekeeper'] is Map<String, dynamic>
          ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
      review: json['review'] != null && json['review'] is Map<String, dynamic>
          ? Review.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      report: json['report'] != null && json['report'] is Map<String, dynamic>
          ? Report.fromJson(json['report'] as Map<String, dynamic>)
          : null,
      additionalSkillTypeIds: (json['additionalSkillTypeIds'] as List?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hireId': hireId,
      'hireName': hireName,
      'hireDetail': hireDetail,
      'paymentAmount': paymentAmount,
      'hireDate': hireDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String().split('T').first,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'jobStatus': jobStatus,
      'progressionImageUrls': progressionImageUrls,
      'skillType': skillType != null
          ? {'skillTypeId': skillType!.skillTypeId}
          : (skillTypeId != null ? {'skillTypeId': skillTypeId} : null),
      'hirer': (hirer != null && hirer!.id != null)
          ? {'id': hirer!.id, 'type': 'hirer'}
          : null,
      'housekeeper': (housekeeper != null && housekeeper!.id != null)
          ? {'id': housekeeper!.id, 'type': 'housekeeper'}
          : null,
      'review': (review != null && review!.reviewId != null)
          ? {'reviewId': review!.reviewId}
          : null,
      'report': (report != null && report!.reportId != null)
          ? {'reportId': report!.reportId}
          : null,
      'additionalSkillTypeIds': additionalSkillTypeIds,
    };
  }

  Hire copyWith({
    int? hireId,
    String? hireName,
    String? hireDetail,
    double? paymentAmount,
    DateTime? hireDate,
    DateTime? startDate,
    String? startTime,
    String? endTime,
    String? location,
    String? jobStatus,
    List<String>? progressionImageUrls,
    int? skillTypeId,
    Hirer? hirer,
    Housekeeper? housekeeper,
    Review? review,
    Report? report,
    SkillType? skillType,
    List<int>? additionalSkillTypeIds, // ✅ เพิ่มใน copyWith
  }) {
    return Hire(
      hireId: hireId ?? this.hireId,
      hireName: hireName ?? this.hireName,
      hireDetail: hireDetail ?? this.hireDetail,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      hireDate: hireDate ?? this.hireDate,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      jobStatus: jobStatus ?? this.jobStatus,
      progressionImageUrls: progressionImageUrls ?? this.progressionImageUrls,
      skillTypeId: skillTypeId ?? this.skillTypeId,
      hirer: hirer ?? this.hirer,
      housekeeper: housekeeper ?? this.housekeeper,
      review: review ?? this.review,
      report: report ?? this.report,
      skillType: skillType ?? this.skillType,
      additionalSkillTypeIds: additionalSkillTypeIds ?? this.additionalSkillTypeIds,
    );
  }
}
