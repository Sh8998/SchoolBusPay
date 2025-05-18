import 'package:flutter/foundation.dart';

enum UserRole { admin, driver, parent }

class User {
  final int id;
  final String name;
  final String mobileNumber;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'role': role.toString().split('.').last,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      mobileNumber: map['mobileNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
    );
  }
} 