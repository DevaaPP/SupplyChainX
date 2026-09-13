import 'package:flutter/material.dart';
import '../../../core/rbac/roles.dart';

// Stores auth state locally (will be replaced by real API token when backend added)
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool is2faEnabled;
  final String? token; // JWT from backend
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.is2faEnabled = false,
    this.token,
    required this.createdAt,
  });

  UserModel copyWith({
    String? displayName,
    bool? is2faEnabled,
    String? token,
  }) =>
      UserModel(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role,
        is2faEnabled: is2faEnabled ?? this.is2faEnabled,
        token: token ?? this.token,
        createdAt: createdAt,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        role: UserRole.fromString(json['role'] as String),
        is2faEnabled: json['is_2fa_enabled'] as bool? ?? false,
        token: json['token'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'role': role.name,
        'is_2fa_enabled': is2faEnabled,
        'token': token,
        'created_at': createdAt.toIso8601String(),
      };

  // Demo accounts for UI testing
  static List<UserModel> demoAccounts() => [
        UserModel(
          id: 'demo-mfg',
          email: 'manufacturer@supply.com',
          displayName: 'Rajesh Kumar',
          role: UserRole.manufacturer,
          is2faEnabled: true,
          createdAt: DateTime(2024, 1, 1),
        ),
        UserModel(
          id: 'demo-dist',
          email: 'distributor@supply.com',
          displayName: 'Priya Sharma',
          role: UserRole.distributor,
          createdAt: DateTime(2024, 2, 1),
        ),
        UserModel(
          id: 'demo-wh',
          email: 'warehouse@supply.com',
          displayName: 'Amit Singh',
          role: UserRole.warehouse,
          createdAt: DateTime(2024, 2, 15),
        ),
        UserModel(
          id: 'demo-ret',
          email: 'retailer@supply.com',
          displayName: 'Sunita Patel',
          role: UserRole.retailer,
          createdAt: DateTime(2024, 3, 1),
        ),
        UserModel(
          id: 'demo-cust',
          email: 'customer@supply.com',
          displayName: 'Vikram Mehta',
          role: UserRole.customer,
          createdAt: DateTime(2024, 3, 15),
        ),
        UserModel(
          id: 'demo-admin',
          email: 'admin@supply.com',
          displayName: 'Enterprise Security Auditor',
          role: UserRole.admin,
          is2faEnabled: true,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];
}

// Helper for role colors
Color roleColor(UserRole role) {
  return switch (role) {
    UserRole.manufacturer => const Color(0xFF7B61FF),
    UserRole.distributor => const Color(0xFF00D4FF),
    UserRole.warehouse => const Color(0xFFFFB800),
    UserRole.retailer => const Color(0xFF00C896),
    UserRole.customer => const Color(0xFFFF6B35),
    UserRole.admin => const Color(0xFFEF4444),
  };
}
