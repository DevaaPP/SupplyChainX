import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../core/rbac/roles.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.customer;
  double _strength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  double _calcStrength(String pass) {
    double s = 0;
    if (pass.length >= 8) s += 0.25;
    if (pass.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (pass.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (pass.contains(RegExp(r'[!@#\$%^&*]'))) s += 0.25;
    return s;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: _selectedRole.name,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      final route = switch (_selectedRole) {
        UserRole.manufacturer => '/dashboard/manufacturer',
        UserRole.distributor => '/dashboard/distributor',
        UserRole.warehouse => '/dashboard/warehouse',
        UserRole.retailer => '/dashboard/retailer',
        UserRole.customer => '/dashboard/customer',
      };
      context.go(route);
    }
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
        Expanded(flex: 4, child: _buildBranding()),
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
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
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Container(
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
          GestureDetector(
            onTap: () => context.go('/login'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 6),
                Text('Back to Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Join the\nSupply Chain Network',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select your role in the supply chain and get access to role-specific tools.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          ),
          const Spacer(),
          // Role cards preview
          ...UserRole.values.map((role) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(role.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(role.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final (strengthLabel, strengthColor) = switch (_strength) {
      0 => ('', AppColors.textMuted),
      <= 0.25 => ('Weak', AppColors.critical),
      <= 0.5 => ('Fair', AppColors.high),
      <= 0.75 => ('Good', AppColors.medium),
      _ => ('Strong', AppColors.low),
    };

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Account', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Register to access your dashboard', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 28),

          AppTextField(
            label: 'Full Name',
            hint: 'Rajesh Kumar',
            controller: _nameCtrl,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMuted),
            validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
            validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
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
            onChanged: (v) => setState(() => _strength = _calcStrength(v)),
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),

          // Password strength meter
          if (_strength > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _strength,
                      backgroundColor: AppColors.surfaceElevated,
                      color: strengthColor,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(strengthLabel, style: TextStyle(color: strengthColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Role selector
          const Text('Your Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ...UserRole.values.map((role) {
            final selected = _selectedRole == role;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryDim : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.cardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(role.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(role.label, style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                          Text(role.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          PrimaryButton(label: 'Create Account', onPressed: _isLoading ? null : _register, isLoading: _isLoading, icon: Icons.person_add_rounded),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
