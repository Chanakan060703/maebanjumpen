import 'package:maebanjumpen/model/hire_lite.dart'; // ใช้ HireLite ตามที่คุณระบุ

class Review {
  final int? reviewId;
  final String? reviewMessage;
  final double? score;
  final DateTime? reviewDate;
  final HireLite? hire;
  final String? hirerFirstName;
  final String? hirerLastName;
  final String? hirerPictureUrl; 

  Review({
    this.reviewId,
    this.reviewMessage,
    this.score,
    this.reviewDate,
    this.hire,
    this.hirerFirstName,
    this.hirerLastName,
    this.hirerPictureUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] as int?,
      reviewMessage: json['reviewMessage'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      reviewDate: json['reviewDate'] != null
          ? DateTime.tryParse(json['reviewDate']) // ใช้ tryParse เพื่อความปลอดภัย
          : null,
      // ตรวจสอบ hire ไม่ให้เป็น int และ parse เป็น HireLite
      hire: json['hire'] != null && json['hire'] is! int
          ? HireLite.fromJson(json['hire'] as Map<String, dynamic>)
          : null,
      hirerFirstName: json['hirerFirstName'] as String?,
      hirerLastName: json['hirerLastName'] as String?,
      hirerPictureUrl: json['hirerPictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reviewId'] = reviewId;
    data['reviewMessage'] = reviewMessage;
    data['score'] = score;
    data['reviewDate'] = reviewDate?.toIso8601String();
    
    // สำหรับการส่งกลับ: ให้ส่ง ID หรือ null หากไม่มี
    if (hire != null && hire!.hireId != null) {
      data['hireId'] = hire!.hireId;
    }
    data['hirerFirstName'] = hirerFirstName;
    data['hirerLastName'] = hirerLastName;
    data['hirerPictureUrl'] = hirerPictureUrl;

    return data;
  }
}