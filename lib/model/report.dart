// maebanjumpen/model/report.dart
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/penalty.dart';
// NEW: หากต้องการให้ Report สามารถมีข้อมูล Hire ได้ (แต่ระวัง Recursive Loop)
// import 'package:maebanjumpen/model/hire.dart';

class Report {
  final int? reportId;
  final String? reportTitle;
  final String? reportMessage;
  final DateTime? reportDate;
  final String? reportStatus;
  final PartyRole? reporter;
  final PartyRole? hirer;
  final PartyRole? housekeeper;
  final Penalty? penalty;
  final int? reportCount; // ควรจะเป็น int? สำหรับ reportCount
  // final Hire? hire; // พิจารณาเพิ่ม หาก Backend ส่งข้อมูล Hire กลับมาใน Report และจัดการ recursive loop ดีแล้ว

  Report({
    this.reportId,
    this.reportTitle,
    this.reportMessage,
    this.reportDate,
    this.reportStatus,
    this.reporter,
    this.hirer,
    this.housekeeper,
    this.penalty,
    this.reportCount,
    // this.hire, // NEW: เพิ่มใน constructor หากต้องการ
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as int?,
      reportTitle: json['reportTitle'] as String?,
      reportMessage: json['reportMessage'] as String?,
      reportDate: json['reportDate'] != null
          ? DateTime.parse(json['reportDate'])
          : null,
      reportStatus: json['reportStatus'] as String?,
      // PartyRole.fromJson จะจัดการการเลือก Subclass ที่ถูกต้องให้
      reporter: json['reporter'] != null && json['reporter'] is Map<String, dynamic>
          ? PartyRole.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
      hirer: json['hirer'] != null && json['hirer'] is Map<String, dynamic>
          ? PartyRole.fromJson(json['hirer'] as Map<String, dynamic>)
          : null,
      housekeeper: json['housekeeper'] != null && json['housekeeper'] is Map<String, dynamic>
          ? PartyRole.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
      penalty: json['penalty'] != null && json['penalty'] is Map<String, dynamic>
          ? Penalty.fromJson(json['penalty'] as Map<String, dynamic>)
          : null,
      reportCount: json['reportCount'] as int?,
      // hire: json['hire'] != null && json['hire'] is! int // NEW: เพิ่มใน fromJson หากต้องการ
      //     ? Hire.fromJson(json['hire'] as Map<String, dynamic>)
      //     : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reportId'] = reportId;
    data['reportTitle'] = reportTitle;
    data['reportMessage'] = reportMessage;
    data['reportDate'] = reportDate?.toIso8601String();
    data['reportStatus'] = reportStatus;
    data['reportCount'] = reportCount; // เพิ่ม reportCount ใน toJson

    // ส่งแค่ ID และ Type ของ PartyRole กลับไป
    if (reporter != null && reporter!.id != null && reporter!.type != null) {
      data['reporter'] = {
        'id': reporter!.id,
        'type': reporter!.type,
      };
    } else {
      data['reporter'] = null;
    }

    if (hirer != null && hirer!.id != null && hirer!.type != null) {
      data['hirer'] = {
        'id': hirer!.id,
        'type': hirer!.type,
      };
    } else {
      data['hirer'] = null;
    }

    if (housekeeper != null && housekeeper!.id != null && housekeeper!.type != null) {
      data['housekeeper'] = {
        'id': housekeeper!.id,
        'type': housekeeper!.type,
      };
    } else {
      data['housekeeper'] = null;
    }

    if (penalty != null && penalty!.penaltyId != null) {
      data['penalty'] = {
        'penaltyId': penalty!.penaltyId,
      };
    } else {
      data['penalty'] = null;
    }
    // NEW: เพิ่มส่วนสำหรับ hire ใน toJson หากต้องการ (และจัดการ recursive loop ดีแล้ว)
    // if (hire != null && hire!.hireId != null) {
    //   data['hire'] = {'hireId': hire!.hireId};
    // } else {
    //   data['hire'] = null;
    // }

    return data;
  }

  Report copyWith({
    int? reportId,
    String? reportTitle,
    String? reportMessage,
    DateTime? reportDate,
    String? reportStatus,
    PartyRole? reporter,
    PartyRole? hirer,
    PartyRole? housekeeper,
    Penalty? penalty,
    int? reportCount,
    // Hire? hire, // NEW: เพิ่มใน copyWith หากต้องการ
  }) {
    return Report(
      reportId: reportId ?? this.reportId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportMessage: reportMessage ?? this.reportMessage,
      reportDate: reportDate ?? this.reportDate,
      reportStatus: reportStatus ?? this.reportStatus,
      reporter: reporter ?? this.reporter,
      hirer: hirer ?? this.hirer,
      housekeeper: housekeeper ?? this.housekeeper,
      penalty: penalty ?? this.penalty,
      reportCount: reportCount ?? this.reportCount,
      // hire: hire ?? this.hire, // NEW: เพิ่มใน copyWith หากต้องการ
    );
  }
}