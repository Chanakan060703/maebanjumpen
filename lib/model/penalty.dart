// lib/model/penalty.dart

// สำหรับ jsonEncode ใน toJson

class Penalty {
  final int? penaltyId;
  final String? penaltyType;
  final String? penaltyDetail;
  final DateTime? penaltyDate;
  final String? penaltyStatus;

  Penalty({
    this.penaltyId,
    this.penaltyType,
    this.penaltyDetail,
    this.penaltyDate,
    this.penaltyStatus,
  });

  // Factory constructor สำหรับสร้าง Penalty object จาก JSON
  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      penaltyId: json['penaltyId'] as int?, // Cast เป็น int?
      penaltyType: json['penaltyType'] as String?,
      penaltyDetail: json['penaltyDetail'] as String?,
      penaltyDate: json['penaltyDate'] != null ? DateTime.parse(json['penaltyDate']) : null,
      penaltyStatus: json['penaltyStatus'] as String?,
    );
  }

  // แปลง Penalty object เป็น Map สำหรับ JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['penaltyId'] = penaltyId;
    data['penaltyType'] = penaltyType;
    data['penaltyDetail'] = penaltyDetail;
    data['penaltyDate'] = penaltyDate?.toIso8601String(); // แปลง DateTime เป็น String ISO 8601
    data['penaltyStatus'] = penaltyStatus;
    return data;
  }
}