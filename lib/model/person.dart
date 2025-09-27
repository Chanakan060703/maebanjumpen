import 'package:maebanjumpen/model/login.dart';

class Person {
  final int? personId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? idCardNumber;
  final String? phoneNumber;
  final String? address;
  final String? pictureUrl;
  final String? accountStatus;
  final Login? login;

  Person({
    this.personId,
    this.email,
    this.firstName,
    this.lastName,
    this.idCardNumber,
    this.phoneNumber,
    this.address,
    this.pictureUrl,
    this.accountStatus,
    this.login,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      personId: json['personId'] as int?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      idCardNumber: json['idCardNumber'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      pictureUrl: json['pictureUrl'] as String?,
      accountStatus: json['accountStatus'] as String?,
      login: json['login'] != null ? Login.fromJson(json['login']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['personId'] = personId;
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['idCardNumber'] = idCardNumber;
    data['phoneNumber'] = phoneNumber;
    data['address'] = address;
    data['pictureUrl'] = pictureUrl;
    if (accountStatus != null) {
      data['accountStatus'] = accountStatus;
    }
    if (login != null) {
      data['login'] = login!.toJson();
    }
    return data;
  }

  Person copyWith({
    int? personId,
    String? email,
    String? firstName,
    String? lastName,
    String? idCardNumber,
    String? phoneNumber,
    String? address,
    String? pictureUrl,
    String? accountStatus,
    Login? login,
  }) {
    return Person(
      personId: personId ?? this.personId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      login: login ?? this.login,
    );
  }
}