import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rbac/roles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState());

  // Login — tries live FastAPI backend, seamlessly falls back to offline demo profiles
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );

      if (res != null && res.statusCode == 200 && res.data != null) {
        final token = res.data['access_token'] as String;
        final userData = res.data['user'] as Map<String, dynamic>;
        
        _apiClient.setAuthToken(token);
        final user = UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String,
          displayName: userData['display_name'] as String,
          role: UserRole.fromString(userData['role'] as String),
          is2faEnabled: userData['is_2fa_enabled'] as bool? ?? false,
          token: token,
          createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        );

        state = AuthState(user: user);
        return true;
      }
    } catch (_) {
      // Backend offline or error -> fallback to local demo resolution
    }

    // Offline / Demo fallback
    await Future.delayed(const Duration(milliseconds: 300));
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

    try {
      final res = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'display_name': name.trim(),
          'role': role.toLowerCase(),
        },
      );

      if (res != null && res.statusCode == 200 && res.data != null) {
        final token = res.data['access_token'] as String;
        final userData = res.data['user'] as Map<String, dynamic>;
        
        _apiClient.setAuthToken(token);
        final user = UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String,
          displayName: userData['display_name'] as String,
          role: UserRole.fromString(userData['role'] as String),
          is2faEnabled: userData['is_2fa_enabled'] as bool? ?? false,
          token: token,
          createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        );

        state = AuthState(user: user);
        return true;
      }
    } catch (_) {}

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
    _apiClient.setAuthToken(null);
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
  (ref) => AuthNotifier(ref.watch(apiClientProvider)),
);
