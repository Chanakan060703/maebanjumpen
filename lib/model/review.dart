import 'package:maebanjumpen/model/hire.dart';
// สำหรับ jsonEncode ใน toJson

class Review {
  final int? reviewId;
  final String? reviewMessage;
  final double? score;
  final DateTime? reviewDate;
  final Hire? hire;

  Review({
    this.reviewId,
    this.reviewMessage,
    this.score,
    this.reviewDate,
    this.hire,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] as int?, // Cast เป็น int?
      reviewMessage: json['reviewMessage'] as String?,
      score: json['score']?.toDouble(),
      reviewDate: json['reviewDate'] != null ? DateTime.parse(json['reviewDate']) : null,
      hire: json['hire'] != null && json['hire'] is! int
          ? Hire.fromJson(json['hire'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reviewId'] = reviewId;
    data['reviewMessage'] = reviewMessage;
    data['score'] = score;
    data['reviewDate'] = reviewDate?.toIso8601String();
    if (hire != null) {
      data['hire'] = hire!.toJson();
    }
    return data;
  }
}