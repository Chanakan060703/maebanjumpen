import 'package:maebanjumpen/model/hirer.dart';
import 'housekeeper.dart'; // 💡 สมมติว่ามี Housekeeper Model

class HireLite {
  final int? hireId;
  final String? hireName;
  final String? jobStatus;
  
  // ⭐️ เพิ่ม Hirer (ผู้ว่าจ้าง)
  final Hirer? hirer; 
  // ⭐️ เพิ่ม Housekeeper (แม่บ้าน)
  final Housekeeper? housekeeper; 

  HireLite({
    this.hireId, 
    this.hireName, 
    this.jobStatus,
    this.hirer, 
    this.housekeeper, 
  });

  factory HireLite.fromJson(Map<String, dynamic> json) {
    return HireLite(
      hireId: json['hireId'] as int?,
      hireName: json['hireName'] as String?,
      jobStatus: json['jobStatus'] as String?,
      
      // ⭐️ Parse Hirer (User)
      hirer: json['hirer'] != null && json['hirer'] is Map<String, dynamic>
          ? Hirer.fromJson(json['hirer'] as Map<String, dynamic>) 
          : null,
          
      // ⭐️ Parse Housekeeper
      housekeeper: json['housekeeper'] != null && json['housekeeper'] is Map<String, dynamic>
          ? Housekeeper.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hireId': hireId,
      'hireName': hireName,
      'jobStatus': jobStatus,
      // ปกติ HireLite ไม่จำเป็นต้องส่ง hirer/housekeeper กลับไปในการทำ CRUD ทั่วไป
      // แต่ถ้าจำเป็นต้องส่ง ID กลับไป ให้ใช้โค้ดด้านล่าง
      // 'hirer': hirer != null ? {'id': hirer!.id, 'type': 'hirer'} : null,
      // 'housekeeper': housekeeper != null ? {'id': housekeeper!.id, 'type': 'housekeeper'} : null,
    };
  }
}