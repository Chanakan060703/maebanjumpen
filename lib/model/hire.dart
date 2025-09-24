import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/review.dart';
import 'package:maebanjumpen/model/report.dart'; // เพิ่ม import สำหรับคลาส Report

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

  final Hirer? hirer;
  final Housekeeper? housekeeper;
  final Review? review;
  final Report? report; // *** นี่คือส่วนที่เพิ่มเข้ามาใหม่ ***

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
    this.report, // *** เพิ่มใน constructor ***
  });

  factory Hire.fromJson(Map<String, dynamic> json) {
    List<String>? progressionImageUrls;
    if (json['progressionImageUrls'] != null) {
      progressionImageUrls = (json['progressionImageUrls'] as List)
          .map((item) => item as String)
          .toList();
    }
    
    return Hire(
      hireId: json['hireId'] as int?,
      hireName: json['hireName'] as String?,
      hireDetail: json['hireDetail'] as String?,
      paymentAmount: json['paymentAmount']?.toDouble(),
      hireDate: json['hireDate'] != null ? DateTime.parse(json['hireDate']) : null,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      jobStatus: json['jobStatus'] as String?,
      progressionImageUrls: progressionImageUrls,
      hirer: json['hirer'] != null ? Hirer.fromJson(json['hirer'] as Map<String, dynamic>) : null,
      housekeeper: json['housekeeper'] != null ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>) : null,
      review: json['review'] != null && json['review'] is! int
              ? Review.fromJson(json['review'] as Map<String, dynamic>)
              : null,
      report: json['report'] != null ? Report.fromJson(json['report'] as Map<String, dynamic>) : null, // *** เพิ่มใน factory ***
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hireId'] = hireId;
    data['hireName'] = hireName;
    data['hireDetail'] = hireDetail;
    data['paymentAmount'] = paymentAmount;
    data['hireDate'] = hireDate?.toIso8601String();
    data['startDate'] = startDate?.toIso8601String().split('T').first;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['location'] = location;
    data['jobStatus'] = jobStatus;

    // เราไม่ส่งรายการรูปภาพกลับไปให้ API
    // data['progressionImageUrls'] = progressionImageUrls;

    if (hirer != null && hirer!.id != null) {
      data['hirer'] = {
        'id': hirer!.id,
        'type': hirer!.type,
      };
    } else {
      data['hirer'] = null;
    }

    if (housekeeper != null && housekeeper!.id != null) {
      data['housekeeper'] = {
        'id': housekeeper!.id,
        'type': housekeeper!.type,
      };
    } else {
      data['housekeeper'] = null;
    }

    if (review != null && review!.reviewId != null) {
      data['review'] = {
        'reviewId': review!.reviewId,
      };
    } else {
      data['review'] = null;
    }

    if (report != null && report!.reportId != null) {
      data['report'] = {
        'reportId': report!.reportId,
      };
    } else {
      data['report'] = null;
    }

    return data;
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
    List<String>? services,
    dynamic wage,
    Hirer? hirer,
    Housekeeper? housekeeper,
    Review? review,
    Report? report, // *** เพิ่มใน copyWith ***
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
      hirer: hirer ?? this.hirer,
      housekeeper: housekeeper ?? this.housekeeper,
      review: review ?? this.review,
      report: report ?? this.report, // *** เพิ่มใน return ***
    );
  }
}