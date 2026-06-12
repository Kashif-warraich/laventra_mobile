import 'dart:convert';

class UserModel {
  final int    id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final String status;
  final bool   mustChangePassword;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.status,
    this.mustChangePassword = false,
  });

  String get fullName => '$firstName $lastName';

  UserModel copyWith({bool? mustChangePassword}) => UserModel(
    id:                 id,
    firstName:          firstName,
    lastName:           lastName,
    username:           username,
    email:              email,
    phoneNumber:        phoneNumber,
    role:               role,
    status:             status,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                 json['id'],
    firstName:          json['first_name'],
    lastName:           json['last_name'],
    username:           json['username'],
    email:              json['email'],
    phoneNumber:        json['phone_number'],
    role:               json['role'],
    status:             json['status'],
    mustChangePassword: json['must_change_password'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id':                   id,
    'first_name':           firstName,
    'last_name':            lastName,
    'username':             username,
    'email':                email,
    'phone_number':         phoneNumber,
    'role':                 role,
    'status':               status,
    'must_change_password': mustChangePassword,
  };

  // For persisting to secure storage
  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str));
}
