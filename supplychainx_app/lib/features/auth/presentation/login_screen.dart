import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final _demoAccounts = [
    ('manufacturer@supply.com', UserRole.manufacturer),
    ('distributor@supply.com', UserRole.distributor),
    ('warehouse@supply.com', UserRole.warehouse),
    ('retailer@supply.com', UserRole.retailer),
    ('customer@supply.com', UserRole.customer),
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
        UserRole.admin => '/audit',
      };
      context.go(route);
    } else {
      final err = ref.read(authProvider).error ?? 'Invalid credentials';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SupplyChainX Logistics',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operator Authentication', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Enter authorized credentials to access your terminal.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'Work Email Address',
                          hint: 'user@supply.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        AppTextField(
                          label: 'Password',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16, color: AppColors.textMuted),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 20),

                        PrimaryButton(
                          label: 'Authenticate & Enter Terminal',
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => context.go('/'),
                              child: Text('← Back to Home', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                            ),
                            InkWell(
                              onTap: () => context.go('/register'),
                              child: Text('Register Role →', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Demo Profiles
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('One-Click Demo Roles', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ..._demoAccounts.map((acc) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () => _demoLogin(acc.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  RoleBadge(role: acc.$2.label, small: true),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(acc.$1, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
