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
  // ** แก้ไข: เปลี่ยนชนิดข้อมูลจาก String เป็น List<String> **
  final List<String>? progressionImageUrls;

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
    this.progressionImageUrls,

    this.hirer,
    this.housekeeper,
    this.review,
  });

  factory Hire.fromJson(Map<String, dynamic> json) {
    // ** แก้ไข: แปลงข้อมูลจาก dynamic เป็น List<String> **
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
      progressionImageUrls: progressionImageUrls, // ** ใช้ตัวแปรที่แปลงแล้ว **
      hirer: json['hirer'] != null ? Hirer.fromJson(json['hirer'] as Map<String, dynamic>) : null,
      housekeeper: json['housekeeper'] != null ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>) : null,
      review: json['review'] != null && json['review'] is! int
              ? Review.fromJson(json['review'] as Map<String, dynamic>)
              : null,
    );
  }

  // ไม่ต้องแก้ไขส่วนนี้ เพราะเราไม่จำเป็นต้องส่งรายการรูปภาพกลับไปให้ API
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
    // ** แก้ไข: เปลี่ยนชนิดข้อมูลเป็น List<String> **
    List<String>? progressionImageUrls,
    List<String>? services,
    dynamic wage,
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
      // ** แก้ไข: ใช้ตัวแปรที่แก้ไขแล้ว **
      progressionImageUrls: progressionImageUrls ?? this.progressionImageUrls,
      hirer: hirer ?? this.hirer,
      housekeeper: housekeeper ?? this.housekeeper,
      review: review ?? this.review,
    );
  }
}
