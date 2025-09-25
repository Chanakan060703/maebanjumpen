import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/person.dart';

class Transaction {
  final int? transactionId;
  final String? transactionType;
  final double? transactionAmount;
  final DateTime? transactionDate;
  final String? transactionStatus;
  final Member? member;
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
    this.prompayNumber,
    this.bankAccountNumber,
    this.bankAccountName,
    this.transactionApprovalDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    Person? person;
    // Check if first name and last name exist
    if (json['memberFirstName'] != null && json['memberLastName'] != null) {
      person = Person(
        firstName: json['memberFirstName'] as String,
        lastName: json['memberLastName'] as String,
        pictureUrl: json['memberPictureUrl'] as String?,
      );
    }

    Member? parsedMember;
    if (json['memberId'] != null) {
      parsedMember = Member(
        id: json['memberId'] as int?, // ใช้ int?
        type: json['memberType'] as String?,
        person: person,
      );
    }

    return Transaction(
      transactionId: json['transactionId'] as int?,
      transactionType: json['transactionType'] as String?,
      transactionAmount: (json['transactionAmount'] as num?)?.toDouble(),
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : null,
      transactionStatus: json['transactionStatus'] as String?,
      member: parsedMember,
      prompayNumber: json['prompayNumber'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      transactionApprovalDate: json['transactionApprovalDate'] != null
          ? DateTime.parse(json['transactionApprovalDate'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transactionType'] = transactionType;
    data['transactionAmount'] = transactionAmount;
    data['transactionDate'] = transactionDate?.toIso8601String();
    data['transactionStatus'] = transactionStatus;

    // Send member data in the structure expected by backend (ID and Type)
    if (member != null && member!.id != null && member!.type != null) {
      data['member'] = {
        'id': member!.id,
        'type': member!.type,
      };
    } else {
      data['member'] = null;
    }

    data['prompayNumber'] = prompayNumber;
    data['bankAccountNumber'] = bankAccountNumber;
    data['bankAccountName'] = bankAccountName;
    data['transactionApprovalDate'] = transactionApprovalDate?.toIso8601String();

    return data;
  }

  Transaction copyWith({
    int? transactionId,
    String? transactionType,
    double? transactionAmount,
    DateTime? transactionDate,
    String? transactionStatus,
    Member? member,
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
      prompayNumber: prompayNumber ?? this.prompayNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      transactionApprovalDate: transactionApprovalDate ?? this.transactionApprovalDate,
    );
  }
}