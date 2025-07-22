import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/person.dart';

class Admin extends PartyRole {
  final String? adminStatus;

  Admin({
    this.adminStatus,
    super.id,
    super.person,
    String? type,
  }) : super(
          type: type ?? 'admin',
        );

  factory Admin.fromJson(Map<String, dynamic> json) {
    final Person? parsedPerson = json['person'] != null
        ? Person.fromJson(json['person'] as Map<String, dynamic>)
        : null;

    return Admin(
      id: json['id'] as int?,
      person: parsedPerson,
      adminStatus: json['adminStatus'] as String?,
      type: json['type'] as String? ?? 'admin',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['adminStatus'] = adminStatus;
    return data;
  }

  @override
  Admin copyWith({
    int? id,
    Person? person,
    String? type,
    String? adminStatus, 
  }) {
    return Admin(
      id: id ?? this.id,
      person: person ?? this.person,
      type: type ?? this.type,
      adminStatus: adminStatus ?? this.adminStatus, 
    );
  }

  @override
  String toString() {
    return 'Admin(id: $id, person: $person, adminStatus: $adminStatus, type: $type)';
  }
}