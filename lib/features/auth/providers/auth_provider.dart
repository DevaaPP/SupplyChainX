import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rbac/roles.dart';
import '../domain/user_model.dart';

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // Login — supports one-click demo profiles and custom logins
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 400)); // smooth operator feedback

    final demo = UserModel.demoAccounts();
    final match = demo.where((u) => u.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;

    if (match != null) {
      state = AuthState(user: match);
      return true;
    }

    // Auto-provision session for custom test emails
    final normalized = email.trim().toLowerCase();
    UserRole inferredRole = UserRole.manufacturer;
    if (normalized.contains('distributor')) {
      inferredRole = UserRole.distributor;
    } else if (normalized.contains('warehouse')) {
      inferredRole = UserRole.warehouse;
    } else if (normalized.contains('retailer')) {
      inferredRole = UserRole.retailer;
    } else if (normalized.contains('customer')) {
      inferredRole = UserRole.customer;
    }

    final name = normalized.contains('@') ? normalized.split('@').first : 'Operator';
    final user = UserModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      displayName: name.substring(0, 1).toUpperCase() + name.substring(1),
      role: inferredRole,
      createdAt: DateTime.now(),
    );

    state = AuthState(user: user);
    return true;
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 500));

    final user = UserModel(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: name.trim(),
      role: UserRole.fromString(role),
      createdAt: DateTime.now(),
    );
    state = AuthState(user: user);
    return true;
  }

  void logout() {
    state = const AuthState();
  }

  void toggle2fa() {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(is2faEnabled: !state.user!.is2faEnabled),
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
