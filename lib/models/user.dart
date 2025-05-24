// lib/models/user.dart
enum UserRole { admin, driver, parent }

class User {
  final String id;
  final String name;
  final String mobileNumber;
  final String email;
  final UserRole role;
  final String? busNo; // For drivers
  final String? driverId; // For parents
  final int? pendingFees; // For parents
  final int? noOfChildren; // For parents

  User({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.role,
    this.busNo,
    this.driverId,
    this.pendingFees = 0,
    this.noOfChildren = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'role': role.toString().split('.').last,
      'busNo': busNo,
      'driverId': driverId,
      'pendingFees': pendingFees,
      'noOfChildren': noOfChildren,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      mobileNumber: map['mobileNumber'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      busNo: map['busNo'] as String?,
      driverId: map['driverId'] as String?,
      pendingFees: map['pendingFees'] as int? ?? 0,
      noOfChildren: map['noOfChildren'] as int? ?? 1,
    );
  }
}