import 'package:flutter/foundation.dart';

enum UserRole {
  user('user'),
  admin('admin'),
  moderator('moderator');

  const UserRole(this.jsonValue);
  final String jsonValue;

  static UserRole fromJson(String? value) {
    return values.firstWhere(
      (role) => role.jsonValue == value,
      orElse: () => UserRole.user, 
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.isEmailVerified = false,
    this.role = UserRole.user,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        profileImageUrl: json['profileImageUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        lastLoginAt: DateTime.parse(json['lastLoginAt']),
        isEmailVerified: json['isEmailVerified'] ?? false,
        role: UserRole.fromJson(json['role']),
      );
    } catch (e) {
      // Helps debug if the data from storage is corrupt or malformed.
      debugPrint('Error parsing UserModel from JSON: $e');
      rethrow; // Rethrow to signal a critical data error.
    }
  }

  /// Converts the UserModel instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'role': role.jsonValue, // Use the enhanced enum value
    };
  }

  /// Creates a copy of the current user with updated fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    // Use ValueGetter to allow explicitly setting profileImageUrl to null.
    // Example usage: copyWith(profileImageUrl: () => null)
    ValueGetter<String?>? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl != null ? profileImageUrl() : this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// --- DATA CLASS FOR SIGN UP ---
class SignUpData {
  final String email;
  final String password;
  final String name;
  final String confirmPassword;
  final String recaptchaToken; // Añadir esta línea

  SignUpData({
    required this.email,
    required this.password,
    required this.name,
    required this.confirmPassword,
    required this.recaptchaToken,
  });

  bool get isPasswordValid => password.length >= 6;
  bool get doPasswordsMatch => password == confirmPassword;
  bool get isEmailValid => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool get isNameValid => name.trim().length >= 2;

  bool get isValid =>
      isPasswordValid &&
      doPasswordsMatch &&
      isEmailValid &&
      isNameValid;
}

// --- DATA CLASS FOR SIGN IN ---
class SignInData {
  final String email;
  final String password;
  final String recaptchaToken; 

  SignInData({
    required this.email,
    required this.password,
    required this.recaptchaToken, 
  });

  bool get isEmailValid => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool get isPasswordValid => password.isNotEmpty;

  bool get isValid => isEmailValid && isPasswordValid;
}