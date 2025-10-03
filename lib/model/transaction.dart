import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/person.dart';

class Transaction {
  final int? transactionId;
  final String? transactionType;
  final double? transactionAmount;
  final DateTime? transactionDate;
  final String? transactionStatus;
  
  final Member? member; // 👈 ใช้สำหรับเก็บข้อมูล Member (เมื่อได้รับจาก Backend)
  final int? memberId; // 👈 ใช้สำหรับส่งข้อมูล (Request Body) หรืออ้างอิง ID
  
  final String? prompayNumber;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final DateTime? transactionApprovalDate;

  Transaction({
    this.transactionId,
    this.transactionType,
    this.transactionAmount,
    this.transactionDate,
    this.transactionStatus,
    this.member,
    this.memberId,
    this.prompayNumber,
    this.bankAccountNumber,
    this.bankAccountName,
    this.transactionApprovalDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    
    Member? parsedMember;
    Person? parsedPerson;

    if (json.containsKey('member')) {
      parsedMember = Member.fromJson(json['member']);
    } 
    else if (json['memberId'] != null) { 
        
      if (json['memberFirstName'] != null || json['memberPictureUrl'] != null) {
        parsedPerson = Person(
          firstName: json['memberFirstName'] as String?,
          lastName: json['memberLastName'] as String?,
          phoneNumber: json['memberPhoneNumber'] as String?,
          pictureUrl: json['memberPictureUrl'] as String?,
        );
      }

      parsedMember = Member(
        id: json['memberId'] as int?, 
        type: json['memberType'] as String?,
        person: parsedPerson,
      );
    }


    return Transaction(
      transactionId: json['transactionId'] as int?,
      transactionType: json['transactionType'] as String?,
      transactionAmount: (json['transactionAmount'] as num?)?.toDouble(),
      transactionDate:
          json['transactionDate'] != null
              ? DateTime.parse(json['transactionDate']).toLocal() 
              : null,
      transactionStatus: json['transactionStatus'] as String?,
      member: parsedMember, 
      memberId: json['memberId'] as int?, 
      prompayNumber: json['prompayNumber'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      transactionApprovalDate:
          json['transactionApprovalDate'] != null
              ? DateTime.parse(json['transactionApprovalDate']).toLocal()
              : null,
    );
  }

  
  // ----------------------------------------------------------------------
  // 🎯 ส่วนที่แก้ไข: การสร้าง JSON (toJson) สำหรับส่ง Request
  // ----------------------------------------------------------------------
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transactionType'] = transactionType;
    data['transactionAmount'] = transactionAmount;
    
    // 💡 FIX DATE FORMAT: แปลงเป็น UTC, ตัด Microseconds, แล้วเพิ่ม 'Z' 
    // เพื่อให้เข้ากันได้ดีกับ Spring Boot LocalDateTime (2025-10-03T16:58:12Z)
    if (transactionDate != null) {
      data['transactionDate'] = transactionDate!.toUtc().toIso8601String().split('.')[0] + 'Z'; 
    } else {
      data['transactionDate'] = null;
    }
    
    data['transactionStatus'] = transactionStatus;

    // 🎯 FIX MEMBER: ส่ง Nested Object {"member": {"id": 4}}
    int? idToSend = memberId ?? member?.id;
    if (idToSend != null) {
      data['member'] = {'id': idToSend}; 
    }
    
    data['prompayNumber'] = prompayNumber;
    data['bankAccountNumber'] = bankAccountNumber;
    data['bankAccountName'] = bankAccountName;
    
    // 💡 FIX DATE FORMAT: ทำซ้ำสำหรับ transactionApprovalDate
    if (transactionApprovalDate != null) {
      data['transactionApprovalDate'] = transactionApprovalDate!.toUtc().toIso8601String().split('.')[0] + 'Z';
    } else {
      data['transactionApprovalDate'] = null;
    }

    return data;
  }
  // ----------------------------------------------------------------------
  
  Transaction copyWith({
    int? transactionId,
    String? transactionType,
    double? transactionAmount,
    DateTime? transactionDate,
    String? transactionStatus,
    Member? member,
    int? memberId, 
    String? prompayNumber,
    String? bankAccountNumber,
    String? bankAccountName,
    DateTime? transactionApprovalDate,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      transactionType: transactionType ?? this.transactionType,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      member: member ?? this.member,
      memberId: memberId ?? this.memberId, 
      prompayNumber: prompayNumber ?? this.prompayNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      transactionApprovalDate:
          transactionApprovalDate ?? this.transactionApprovalDate,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $transactionId, type: $transactionType, amount: $transactionAmount, status: $transactionStatus, memberId: $memberId)';
  }
}