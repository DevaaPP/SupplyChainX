import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  UserRole _selectedRole = UserRole.distributor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        Text('Register Partner Terminal', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Provision access to your specific supply chain role.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'Full Name / Organization',
                          hint: 'e.g. Apex Logistics Siliguri',
                          controller: _nameCtrl,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        AppTextField(
                          label: 'Work Email Address',
                          hint: 'e.g. dispatch@apexlogistics.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
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
                        const SizedBox(height: 16),

                        Text('Designated Supply Chain Role', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ...UserRole.values.map((role) {
                          final isSel = _selectedRole == role;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () => setState(() => _selectedRole = role),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primaryLight : AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Text(role.label, style: GoogleFonts.inter(color: isSel ? AppColors.primary : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text(role.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),

                        PrimaryButton(
                          label: 'Complete Provisioning',
                          isLoading: _isLoading,
                          onPressed: _register,
                        ),
                        const SizedBox(height: 14),

                        Center(
                          child: InkWell(
                            onTap: () => context.go('/login'),
                            child: Text('Already provisioned? Sign In →', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
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
