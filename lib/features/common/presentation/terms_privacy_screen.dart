import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class TermsPrivacyScreen extends StatelessWidget {
  final bool isPrivacy;
  const TermsPrivacyScreen({super.key, this.isPrivacy = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          isPrivacy ? 'SupplyX Privacy Policy' : 'SupplyX Terms of Service',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPrivacy ? 'Enterprise Data Privacy & Security' : 'Logistics Custody Terms & Conditions',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Last Updated: August 22, 2026 · Version 1.0',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 20),

                  if (isPrivacy) ...[
                    _section(
                      '1. Cryptographic Data Processing',
                      'SupplyX operates on deterministic HMAC-SHA256 signatures and verifiable blockchain hashes. Only verified consignment serials, location waypoints, and participant role identifiers are committed to the public custody ledger.',
                    ),
                    _section(
                      '2. Operator Telemetry & Audit Logs',
                      'Authentication events, terminal IP addresses, and barcode scanning attempts are recorded in real-time security telemetry to detect and prevent unauthorized consignment tampering.',
                    ),
                    _section(
                      '3. Encryption at Rest & in Transit',
                      'All communications between terminal clients and backend nodes are enforced via TLS 1.3. Local device vaults are encrypted using AES-256-GCM.',
                    ),
                  ] else ...[
                    _section(
                      '1. Chain of Custody Responsibility',
                      'Each participating stakeholder (Manufacturer, Distributor, Warehouse, Retailer) is legally accountable for recording accurate handover state transitions upon physical receipt or dispatch.',
                    ),
                    _section(
                      '2. Anti-Counterfeiting & Tamper Enforcement',
                      'Any deliberate alteration of physical packaging, forgery of HMAC barcode labels, or unauthorized ownership transfers will trigger immediate automated security alarms and partner decommission.',
                    ),
                    _section(
                      '3. Service Level & Operational Guarantees',
                      'SupplyX provides 99.9% uptime for cryptographic verification endpoints across both mobile inspection terminals and web control rooms.',
                    ),
                  ],

                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Acknowledge & Return to Dashboard',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
