// lib/model/hirer.dart
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/hire.dart'; // ใช้ Hire ตัวเต็ม (หาก HireLite ไม่ใช่ตัวเดียวกัน)
import 'package:maebanjumpen/model/person.dart';
// ต้อง import Hire ตัวเต็ม หาก hires เป็น List<Hire> (ตาม DTO)

class Hirer extends Member {
  // สังเกต: hires ใน Backend DTO เป็น Set<Hire> แต่ใน Flutter DTO เป็น List<Integer> 
  // หากคุณส่ง Hirer ตัวเต็มมา จะเป็น List<Hire> ซึ่งผมใช้ตามที่คุณระบุในโค้ด
  final List<Hire>? hires;
  final String? username; // username ถูกดึงมาจาก login.username ใน Person

  Hirer({
    this.hires,
    this.username,
    super.id,
    super.person,
    String? type,
    super.balance,
  }) : super(
          type: type ?? 'hirer',
        );

  factory Hirer.fromJson(Map<String, dynamic> json) {
    // 💡 การแปลง hires: ตรวจสอบและแปลงจาก List<Map> เป็น List<Hire>
    // สมมติว่ามี Hire Model ตัวเต็มอยู่แล้ว
    var hiresList = json['hires'] as List?;
    List<Hire>? parsedHires;
    if (hiresList != null) {
      // **ข้อควรระวัง:** ถ้า hiresList เป็น List<int> (hireIds) ให้ใช้ตามนั้น
      // แต่ถ้าเป็น List<Map> (Hire objects) ให้ใช้ .map()
      parsedHires = hiresList
          .map((i) => Hire.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    final Person? personFromJson = json['person'] != null
        ? Person.fromJson(json['person'] as Map<String, dynamic>)
        : null;

    return Hirer(
      id: json['id'] as int?,
      person: personFromJson,
      type: json['type'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      hires: parsedHires,
      // ดึง username จาก Person.login.username
      username: personFromJson?.login?.username, 
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['username'] = username;
    // หากต้องการส่ง hiresIds กลับไป:
    // data['hireIds'] = hires?.map((h) => h.hireId).toList(); 
    return data;
  }
  
  // โค้ด copyWith() ที่คุณให้มาถูกต้องแล้ว
  @override
  Hirer copyWith({
    int? id,
    Person? person,
    String? type,
    double? balance,
    List<Hire>? hires,
    String? username,
  }) {
    final Member memberCopy = super.copyWith(
      id: id,
      person: person,
      type: type,
      balance: balance,
    );

    return Hirer(
      id: memberCopy.id,
      person: memberCopy.person,
      type: memberCopy.type, 
      balance: memberCopy.balance,
      hires: hires ?? this.hires,
      username: username ?? this.username,
    );
  }
}