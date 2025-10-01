import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/penalty.dart';

class Report {
  final int? reportId;
  final String? reportTitle;
  final String? reportMessage;
  final DateTime? reportDate;
  final String? reportStatus;

  // Relationships (Objects)
  final PartyRole? reporter;
  final PartyRole? hirer;
  final PartyRole? housekeeper;
  final Penalty? penalty;

  // Report Count (Assumed non-null for some report types/views)
  final int? reportCount;
  // ✅ เพิ่ม field 'hireId' ที่มีอยู่ใน Java DTO
  final int? hireId;
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
    this.hireId, // ✅ เพิ่มใน constructor
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as int?,
      reportTitle: json['reportTitle'] as String?,
      reportMessage: json['reportMessage'] as String?,
      reportDate:
          json['reportDate'] != null
              ? DateTime.parse(json['reportDate'])
              : null,
      reportStatus: json['reportStatus'] as String?,
      reporter:
          json['reporter'] != null && json['reporter'] is Map<String, dynamic>
              ? PartyRole.fromJson(json['reporter'] as Map<String, dynamic>)
              : null,
      hirer:
          json['hirer'] != null && json['hirer'] is Map<String, dynamic>
              ? PartyRole.fromJson(json['hirer'] as Map<String, dynamic>)
              : null,
      housekeeper:
          json['housekeeper'] != null &&
                  json['housekeeper'] is Map<String, dynamic>
              ? PartyRole.fromJson(json['housekeeper'] as Map<String, dynamic>)
              : null,
      penalty:
          json['penalty'] != null && json['penalty'] is Map<String, dynamic>
              ? Penalty.fromJson(json['penalty'] as Map<String, dynamic>)
              : null,
      reportCount: json['reportCount'] as int?,
      hireId: json['hireId'] as int?, // ✅ ดึงค่า hireId
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
    data['reportCount'] = reportCount;
    data['hireId'] = hireId; // ✅ ส่งค่า hireId กลับไป
    if (reporter != null && reporter!.id != null && reporter!.type != null) {
      data['reporter'] = {'id': reporter!.id, 'type': reporter!.type};
    } else {
      data['reporter'] = null;
    }
    if (hirer != null && hirer!.id != null && hirer!.type != null) {
      data['hirer'] = {'id': hirer!.id, 'type': hirer!.type};
    } else {
      data['hirer'] = null;
    }
    if (housekeeper != null &&
        housekeeper!.id != null &&
        housekeeper!.type != null) {
      data['housekeeper'] = {'id': housekeeper!.id, 'type': housekeeper!.type};
    } else {
      data['housekeeper'] = null;
    }
    if (penalty != null && penalty!.penaltyId != null) {
      data['penalty'] = {'penaltyId': penalty!.penaltyId};
    } else {
      data['penalty'] = null;
    }

    return data;
  }
}
