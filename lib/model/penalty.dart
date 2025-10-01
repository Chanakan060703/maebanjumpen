class Penalty {
  final int? penaltyId;
  final String? penaltyType;
  final String? penaltyDetail;
  final DateTime? penaltyDate;
  final String? penaltyStatus;
  // ✅ เพิ่ม field 'reportId' ที่มีอยู่ใน Java DTO
  final int? reportId;

  Penalty({
    this.penaltyId,
    this.penaltyType,
    this.penaltyDetail,
    this.penaltyDate,
    this.penaltyStatus,
    this.reportId,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      penaltyId: json['penaltyId'] as int?,
      penaltyType: json['penaltyType'] as String?,
      penaltyDetail: json['penaltyDetail'] as String?,
      penaltyDate:
          json['penaltyDate'] != null
              ? DateTime.parse(json['penaltyDate'])
              : null,
      penaltyStatus: json['penaltyStatus'] as String?,
      // ✅ ดึงค่า reportId จาก JSON
      reportId: json['reportId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['penaltyId'] = penaltyId;
    data['penaltyType'] = penaltyType;
    data['penaltyDetail'] = penaltyDetail;
    data['penaltyDate'] = penaltyDate?.toIso8601String();
    data['penaltyStatus'] = penaltyStatus;
    data['reportId'] = reportId;
    return data;
  }

  @override
  String toString() {
    return 'Penalty(penaltyId: $penaltyId, penaltyType: $penaltyType, penaltyStatus: $penaltyStatus)';
  }
}
