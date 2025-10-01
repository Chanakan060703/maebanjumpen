import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/person.dart';

class Transaction {
  final int? transactionId;
  final String? transactionType;
  final double? transactionAmount;
  final DateTime? transactionDate;
  final String? transactionStatus;
  
  final Member? member; // 👈 ใช้สำหรับเก็บข้อมูล Member (รวมถึง Person & PictureUrl) ที่ Backend ส่งกลับมา
  final int? memberId; // 👈 ใช้สำหรับส่งข้อมูล (Request Body)
  
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
          phoneNumber: json['memberPhoneNumber'] as String?, // เพิ่มถ้ามี
          pictureUrl: json['memberPictureUrl'] as String?, // 👈 ส่วนสำคัญ
        );
      }

      // สร้าง Member object
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
              ? DateTime.parse(json['transactionDate']).toLocal() // toLocal() ช่วยปรับ Timezone
              : null,
      transactionStatus: json['transactionStatus'] as String?,
      member: parsedMember, // 👈 เก็บ Member Object ที่สร้างขึ้น
      memberId: json['memberId'] as int?, // เก็บ memberId สำหรับอ้างอิง
      prompayNumber: json['prompayNumber'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      transactionApprovalDate:
          json['transactionApprovalDate'] != null
              ? DateTime.parse(json['transactionApprovalDate']).toLocal()
              : null,
    );
  }

  // ... (ส่วน toJson() และ copyWith() เหมือนเดิม)
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transactionType'] = transactionType;
    data['transactionAmount'] = transactionAmount;
    data['transactionDate'] = transactionDate?.toIso8601String();
    data['transactionStatus'] = transactionStatus;

    if (memberId != null) {
      data['memberId'] = memberId; 
    } else if (member != null && member!.id != null) {
      data['memberId'] = member!.id;
    } 
    
    data['prompayNumber'] = prompayNumber;
    data['bankAccountNumber'] = bankAccountNumber;
    data['bankAccountName'] = bankAccountName;
    data['transactionApprovalDate'] =
        transactionApprovalDate?.toIso8601String();

    return data;
  }

  Transaction copyWith({
    int? transactionId,
    String? transactionType,
    double? transactionAmount,
    DateTime? transactionDate,
    String? transactionStatus,
    Member? member,
    int? memberId, // 👈 เพิ่มใน copyWith
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
      memberId: memberId ?? this.memberId, // 👈 เพิ่มใน copyWith
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