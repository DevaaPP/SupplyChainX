import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/server_connection_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});
  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _biometric = true;
  bool _loginAlerts = true;
  bool _tamperAlerts = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final is2fa = user?.is2faEnabled ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Security & Access Controls', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cryptographic Engine Status
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cryptographic Security Engine', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _cryptoRow('QR Code Digital Signature', 'HMAC-SHA256', AppColors.success),
                      _cryptoRow('Data Transport Protocol', 'TLS 1.3 / HTTPS', AppColors.success),
                      _cryptoRow('Token Identity Provider', 'JWT + Bcrypt (Cost 12)', AppColors.success),
                      _cryptoRow('Local Secure Vault', 'AES-256-GCM', AppColors.success),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Factor Authentication
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Authentication Controls', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Two-Factor Authentication (TOTP)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(is2fa ? 'Enabled for operator sign-in' : 'Disabled — recommended for production terminals', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        value: is2fa,
                        onChanged: (_) {
                          ref.read(authProvider.notifier).toggle2fa();
                        },
                      ),
                      const Divider(color: AppColors.cardBorder),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Biometric Hardware Authentication', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text('Fingerprint / Face ID device integration', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        value: _biometric,
                        onChanged: (v) => setState(() => _biometric = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alerts & Telemetry
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Incident Broadcasts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Critical Tamper Alarms', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text('Immediate notification when counterfeit barcode is detected', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        value: _tamperAlerts,
                        onChanged: (v) => setState(() => _tamperAlerts = v),
                      ),
                      const Divider(color: AppColors.cardBorder),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Unrecognized Terminal Sign-in Alert', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text('Broadcast alerts for new IP / browser fingerprints', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        value: _loginAlerts,
                        onChanged: (v) => setState(() => _loginAlerts = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Network Infrastructure & Node Configuration
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Network Infrastructure & LAN Node',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'PORT 8000',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Node Endpoint: http://${ApiEndpoints.activeHost}:8000\nWhen switching Wi-Fi or networks, configure or auto-detect the host PC IP so mobile terminals synchronize with the backend ledger.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ServerConnectionDialog.show(context);
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.hub_outlined, size: 16, color: AppColors.primary),
                          label: Text(
                            'Configure Node IP (${ApiEndpoints.activeHost})',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
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

  Widget _cryptoRow(String label, String algo, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              algo,
              style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
