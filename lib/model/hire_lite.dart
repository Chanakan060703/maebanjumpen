class HireLite {
  final int? hireId;
  final String? hireName;
  final String? jobStatus;

  HireLite({this.hireId, this.hireName, this.jobStatus});

  factory HireLite.fromJson(Map<String, dynamic> json) {
    return HireLite(
      hireId: json['hireId'] as int?,
      hireName: json['hireName'] as String?,
      jobStatus: json['jobStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hireId': hireId,
      'hireName': hireName,
      'jobStatus': jobStatus,
    };
  }
}