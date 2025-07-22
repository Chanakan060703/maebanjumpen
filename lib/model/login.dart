// สำหรับ jsonEncode ใน toJson

class Login {
  final String? username;
  final String? password;

  Login({
    this.username,
    this.password,
  });

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = username;
    data['password'] = password;
    return data;
  }
}