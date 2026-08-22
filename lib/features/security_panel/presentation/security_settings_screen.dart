import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});
  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = true;
  bool _loginAlerts = true;
  bool _qrAlerts = true;
  int _sessionTimeout = 30;

  final _sessions = [
    {'device': 'Chrome on Windows', 'ip': '192.168.1.10', 'time': '2 min ago', 'current': true},
    {'device': 'Pixel 8 (Android)', 'ip': '192.168.1.45', 'time': '1 hour ago', 'current': false},
    {'device': 'Safari on iPhone', 'ip': '172.16.0.23', 'time': '2 days ago', 'current': false},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final is2fa = user?.is2faEnabled ?? false;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Security Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Score
                _buildScoreCard(is2fa),
                const SizedBox(height: 24),

                // 2FA
                _buildSection('Two-Factor Authentication', [
                  _buildToggleTile(
                    icon: Icons.security_rounded,
                    title: '2FA (TOTP)',
                    subtitle: is2fa
                        ? 'Enabled — Using authenticator app'
                        : 'Disabled — Add extra security layer',
                    value: is2fa,
                    color: is2fa ? AppColors.low : AppColors.medium,
                    onChanged: (_) {
                      ref.read(authProvider.notifier).toggle2fa();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            is2fa ? '2FA disabled' : '2FA enabled successfully',
                          ),
                          backgroundColor: is2fa
                              ? AppColors.medium
                              : AppColors.low,
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                // Auth settings
                _buildSection('Authentication', [
                  _buildToggleTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID to login',
                    value: _biometricEnabled,
                    color: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _biometricEnabled = v),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timer_outlined,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Session Timeout',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text('Auto-logout after $_sessionTimeout min',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        DropdownButton<int>(
                          value: _sessionTimeout,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          underline: const SizedBox(),
                          items: [15, 30, 60, 120].map((m) =>
                              DropdownMenuItem(
                                  value: m,
                                  child: Text('$m min',
                                      style: const TextStyle(
                                          color: AppColors.primary)))).toList(),
                          onChanged: (v) =>
                              setState(() => _sessionTimeout = v!),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.secondary, size: 18),
                    ),
                    title: const Text('Change Password',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Last changed: 30 days ago',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                    onTap: () => _showChangePassword(context),
                  ),
                ]),
                const SizedBox(height: 20),

                // Notifications
                _buildSection('Security Alerts', [
                  _buildToggleTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Login Alerts',
                    subtitle: 'Notify on new login from unknown device',
                    value: _loginAlerts,
                    color: AppColors.primary,
                    onChanged: (v) => setState(() => _loginAlerts = v),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _buildToggleTile(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QR Tamper Alerts',
                    subtitle: 'Notify on tampered QR scan attempts',
                    value: _qrAlerts,
                    color: AppColors.critical,
                    onChanged: (v) => setState(() => _qrAlerts = v),
                  ),
                ]),
                const SizedBox(height: 20),

                // Active Sessions
                _buildSection('Active Sessions', [
                  ..._sessions.asMap().entries.map((e) {
                    final s = e.value;
                    final isCurrent = s['current'] as bool;
                    return Column(
                      children: [
                        if (e.key > 0)
                          const Divider(color: AppColors.cardBorder, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primaryDim
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  s['device'].toString().contains('Android')
                                      ? Icons.phone_android_rounded
                                      : Icons.computer_rounded,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(s['device'].toString(),
                                            style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryDim,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text('Current',
                                                style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('${s['ip']} · ${s['time']}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (!isCurrent)
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Session revoked'),
                                        backgroundColor: AppColors.high,
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.critical),
                                  child: const Text('Revoke',
                                      style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ]),
                const SizedBox(height: 20),

                // Encryption Status
                _buildSection('Encryption Status', [
                  _encRow(
                      Icons.lock_rounded,
                      'Data Encryption',
                      'AES-256-GCM',
                      true),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _encRow(
                      Icons.verified_user_rounded,
                      'QR Signing',
                      'HMAC-SHA256',
                      true),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _encRow(
                      Icons.vpn_key_rounded,
                      'Authentication',
                      'JWT + bcrypt',
                      true),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _encRow(
                      Icons.https_rounded,
                      'Transport',
                      'TLS 1.3 (HTTPS)',
                      true),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(bool is2fa) {
    final score = 72 + (is2fa ? 20 : 0) + (_biometricEnabled ? 8 : 0);
    final (label, color) = score >= 90
        ? ('Excellent', AppColors.low)
        : score >= 70
            ? ('Good', AppColors.medium)
            : ('Needs Improvement', AppColors.high);
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppColors.surfaceElevated,
                  color: color,
                  strokeWidth: 6,
                ),
                Text('$score',
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security Score',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (!is2fa)
                  const Text('Enable 2FA to improve your score',
                      style: TextStyle(
                          color: AppColors.medium, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _encRow(
      IconData icon, String label, String algo, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.low, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lowDim,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(algo,
                style: const TextStyle(
                    color: AppColors.low,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.low, size: 16),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Current Password',
              controller: oldCtrl,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'New Password',
              controller: newCtrl,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Password updated successfully'),
                backgroundColor: AppColors.low,
              ));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
