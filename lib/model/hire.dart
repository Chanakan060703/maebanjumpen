import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/review.dart';

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
  final String? progressionImageUrl; // ยังคงเป็น nullable


  final Hirer? hirer;
  final Housekeeper? housekeeper;
  final Review? review;

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
    this.progressionImageUrl, // ยังคงเป็น nullable

  

    this.hirer,
    this.housekeeper,
    this.review,
  });

  factory Hire.fromJson(Map<String, dynamic> json) {
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
      progressionImageUrl: json['progressionImageUrl'] as String?,
      hirer: json['hirer'] != null ? Hirer.fromJson(json['hirer'] as Map<String, dynamic>) : null,
      housekeeper: json['housekeeper'] != null ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>) : null,
      review: json['review'] != null && json['review'] is! int
              ? Review.fromJson(json['review'] as Map<String, dynamic>)
              : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hireId'] = hireId; // hireId อาจเป็น null เมื่อสร้างใหม่
    data['hireName'] = hireName;
    data['hireDetail'] = hireDetail;
    data['paymentAmount'] = paymentAmount;
    data['hireDate'] = hireDate?.toIso8601String(); // ISO 8601 format
    data['startDate'] = startDate?.toIso8601String().split('T').first; // 'YYYY-MM-DD'
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['location'] = location;
    data['jobStatus'] = jobStatus;
    data['progressionImageUrl'] = progressionImageUrl;

   

    if (hirer != null && hirer!.id != null) {
      data['hirer'] = {
        'id': hirer!.id,
        'type': hirer!.type, // ต้องส่ง type ไปด้วยเพื่อให้ Backend deserialization ถูกต้อง
      };
    } else {
      data['hirer'] = null; // หรือจะละเว้น field นี้ไปเลยถ้า hirer เป็น null
    }

    if (housekeeper != null && housekeeper!.id != null) {
      data['housekeeper'] = {
        'id': housekeeper!.id,
        'type': housekeeper!.type, // ต้องส่ง type ไปด้วย
      };
    } else {
      data['housekeeper'] = null;
    }

    if (review != null && review!.reviewId != null) { // ปกติ review จะถูกสร้างทีหลัง
      data['review'] = {
        'reviewId': review!.reviewId,
      };
    } else {
      data['review'] = null;
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
    String? progressionImageUrl,
    List<String>? services, // ใส่ services ด้วย
    dynamic wage,           // ใส่ wage ด้วย
    Hirer? hirer,
    Housekeeper? housekeeper,
    Review? review,
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
      progressionImageUrl: progressionImageUrl ?? this.progressionImageUrl,
      hirer: hirer ?? this.hirer,
      housekeeper: housekeeper ?? this.housekeeper,
      review: review ?? this.review,
    );
  }
}