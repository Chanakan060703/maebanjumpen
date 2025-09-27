import 'package:maebanjumpen/model/hire_lite.dart'; // import HireLite

class Review {
  final int? reviewId;
  final String? reviewMessage;
  final double? score;
  final DateTime? reviewDate;
  final HireLite? hire; // เปลี่ยนจาก Hire? เป็น HireLite?

  Review({
    this.reviewId,
    this.reviewMessage,
    this.score,
    this.reviewDate,
    this.hire,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] as int?,
      reviewMessage: json['reviewMessage'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      reviewDate: json['reviewDate'] != null
          ? DateTime.parse(json['reviewDate'])
          : null,
      // ตรวจสอบ hire ไม่ให้เป็น int และ parse เป็น HireLite
      hire: json['hire'] != null && json['hire'] is! int
          ? HireLite.fromJson(json['hire'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reviewId'] = reviewId;
    data['reviewMessage'] = reviewMessage;
    data['score'] = score;
    data['reviewDate'] = reviewDate?.toIso8601String();
    // ใน toJson เรามักจะส่งแค่ ID ของ Hire กลับไปหาก Backend ต้องการ
    // หรือส่งเป็น HireLite object ถ้า Backend รองรับ
    if (hire != null && hire!.hireId != null) {
      data['hire'] = {'hireId': hire!.hireId}; // ส่งแค่ ID
    } else {
      data['hire'] = null;
    }
    return data;
  }
}