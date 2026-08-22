import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../core/rbac/roles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  // Demo accounts for quick login
  final _demoAccounts = [
    ('manufacturer@supply.com', UserRole.manufacturer, '🏭'),
    ('distributor@supply.com', UserRole.distributor, '🚛'),
    ('warehouse@supply.com', UserRole.warehouse, '🏪'),
    ('retailer@supply.com', UserRole.retailer, '🏬'),
    ('customer@supply.com', UserRole.customer, '👤'),
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      final role = ref.read(authProvider).user!.role;
      final route = switch (role) {
        UserRole.manufacturer => '/dashboard/manufacturer',
        UserRole.distributor => '/dashboard/distributor',
        UserRole.warehouse => '/dashboard/warehouse',
        UserRole.retailer => '/dashboard/retailer',
        UserRole.customer => '/dashboard/customer',
      };
      context.go(route);
    } else {
      final err = ref.read(authProvider).error ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.critical),
      );
    }
  }

  void _demoLogin(String email) {
    _emailCtrl.text = email;
    _passCtrl.text = 'demo1234';
    _login();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWide() : _buildMobile(),
    );
  }

  Widget _buildWide() {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1730), Color(0xFF0A0E1A)],
              ),
            ),
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 6),
                      Text('Back to Home', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SupplyChainX',
                  style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Secure.\nTransparent.\nTraceable.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Role-based access to the supply chain platform.\nLog in to manage your part of the journey.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                ),
                const Spacer(),
                // Role pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in UserRole.values)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '${role.icon} ${role.label}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Right login form
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          GestureDetector(
            onTap: () => context.go('/'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 16),
                SizedBox(width: 4),
                Text('Back to Home', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('SupplyChainX', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign In', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Access your supply chain dashboard', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 32),

          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
            validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passCtrl,
            obscureText: _obscure,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Sign In',
            onPressed: _isLoading ? null : _login,
            isLoading: _isLoading,
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 24),

          // Demo accounts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Demo Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...List.generate(_demoAccounts.length, (i) {
                  final (email, role, icon) = _demoAccounts[i];
                  return GestureDetector(
                    onTap: () => _demoLogin(email),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                const Text('Password: demo1234', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: const Text('Register', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
