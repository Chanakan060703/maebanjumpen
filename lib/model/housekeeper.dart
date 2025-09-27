// lib/model/housekeeper.dart
import 'package:maebanjumpen/model/housekeeper_skill.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/review.dart'; // ⭐️ ต้อง Import Review Model

class Housekeeper extends Member {
  final String? photoVerifyUrl;
  String? statusVerify;
  final double? rating;
  final List<Hire>? hires;
  final List<HousekeeperSkill>? housekeeperSkills;
  final String? username;
  final double? dailyRate;
  
  // ⭐️ เพิ่มฟิลด์ใหม่สำหรับรับ List ของรีวิวโดยตรงจาก Backend
  final List<Review>? reviews;

  Housekeeper({
    this.photoVerifyUrl,
    this.statusVerify,
    this.rating,
    this.hires,
    this.housekeeperSkills,
    this.username,
    super.id,
    super.person,
    super.balance,
    this.dailyRate,
    this.reviews, // ⭐️ เพิ่มใน Constructor
    String? type,
  }) : super(type: type ?? 'housekeeper');

  factory Housekeeper.fromJson(Map<String, dynamic> json) {
    // 1. Parse Hires List (ตามโค้ดเดิม)
    var hiresList = json['hires'] as List?;
    List<Hire>? parsedHires;
    if (hiresList != null) {
      parsedHires = hiresList.map((i) => Hire.fromJson(i)).toList();
    }

    // 2. Parse Housekeeper Skills List (ตามโค้ดเดิม)
    var skillsList = json['housekeeperSkills'] as List?;
    List<HousekeeperSkill>? parsedSkills;
    if (skillsList != null) {
      parsedSkills =
          skillsList
              .map((i) => HousekeeperSkill.fromJson(i as Map<String, dynamic>))
              .toList();
    }
    
    // ⭐️ 3. Parse Reviews List (ส่วนที่เพิ่มเข้ามา)
    var reviewsList = json['reviews'] as List?;
    List<Review>? parsedReviews;
    if (reviewsList != null) {
      // ตรวจสอบว่าแต่ละ item เป็น Map<String, dynamic> ก่อนทำการแปลง
      parsedReviews = reviewsList
          .whereType<Map<String, dynamic>>()
          .map((i) => Review.fromJson(i))
          .toList();
    }

    final Person? personFromJson =
        json['person'] != null
            ? Person.fromJson(json['person'] as Map<String, dynamic>)
            : null;

    return Housekeeper(
      id: json['id'] as int?,
      person: personFromJson,
      type: json['type'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      photoVerifyUrl: json['photoVerifyUrl'] as String?,
      statusVerify: json['statusVerify'] as String?,
      rating: json['rating']?.toDouble(),
      hires: parsedHires,
      housekeeperSkills: parsedSkills,
      username: personFromJson?.login?.username,
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      reviews: parsedReviews, // ⭐️ ใส่ parsedReviews
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['photoVerifyUrl'] = photoVerifyUrl;
    data['statusVerify'] = statusVerify;
    data['rating'] = rating;
    data['dailyRate'] = dailyRate;
    // ไม่จำเป็นต้องใส่ hires, housekeeperSkills, reviews ในการส่งข้อมูลกลับ (toJson)
    return data;
  }

  @override
  Housekeeper copyWith({
    int? id,
    Person? person,
    String? type,
    double? balance,
    String? photoVerifyUrl,
    String? statusVerify,
    double? rating,
    List<Hire>? hires,
    List<HousekeeperSkill>? housekeeperSkills,
    String? username,
    String? lineId,
    String? facebookLink,
    String? bankAccountNumber,
    String? bankAccountName,
    double? dailyRate,
    List<Review>? reviews, // ⭐️ เพิ่มใน copyWith parameter
  }) {
    final Member memberCopy = super.copyWith(
      id: id,
      person: person,
      type: type,
      balance: balance,
    );

    return Housekeeper(
      id: memberCopy.id,
      person: memberCopy.person,
      type: memberCopy.type,
      balance: memberCopy.balance,
      photoVerifyUrl: photoVerifyUrl ?? this.photoVerifyUrl,
      statusVerify: statusVerify ?? this.statusVerify,
      rating: rating ?? this.rating,
      hires: hires ?? this.hires,
      housekeeperSkills: housekeeperSkills ?? this.housekeeperSkills,
      username: username ?? this.username,
      dailyRate: dailyRate ?? this.dailyRate,
      reviews: reviews ?? this.reviews, // ⭐️ ใส่ reviews
    );
  }

  @override
  String toString() {
    return 'Housekeeper(id: $id, person: $person, type: $type, balance: $balance, statusVerify: $statusVerify, rating: $rating, dailyRate: $dailyRate, reviewsCount: ${reviews?.length ?? 0})';
  }
}