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

  // Login — demo accounts, wires to backend later
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800)); // simulate network

    final demo = UserModel.demoAccounts();
    final match = demo.where((u) => u.email == email).firstOrNull;

    if (match != null && password == 'demo1234') {
      state = AuthState(user: match);
      return true;
    }

    state = const AuthState(error: 'Invalid email or password');
    return false;
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 1200));

    final user = UserModel(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
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
