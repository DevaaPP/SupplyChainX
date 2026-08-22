import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../core/rbac/roles.dart';

/// Clean Industrial-Tech Landing Page for SupplyX
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _productIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        _goToDashboard(auth.user!.role);
      }
    });
  }

  @override
  void dispose() {
    _productIdCtrl.dispose();
    super.dispose();
  }

  void _goToDashboard(UserRole role) {
    final route = switch (role) {
      UserRole.manufacturer => '/dashboard/manufacturer',
      UserRole.distributor => '/dashboard/distributor',
      UserRole.warehouse => '/dashboard/warehouse',
      UserRole.retailer => '/dashboard/retailer',
      UserRole.customer => '/dashboard/customer',
    };
    if (mounted) context.go(route);
  }

  void _onTrackProduct() {
    final id = _productIdCtrl.text.trim();
    if (id.isNotEmpty) {
      context.push('/verify/$id');
    } else {
      context.push('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopNav(context),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Hero + Search Area
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _buildHeroText()),
                              const SizedBox(width: 40),
                              Expanded(flex: 5, child: _buildSearchCard()),
                            ],
                          )
                        else ...[
                          _buildHeroText(),
                          const SizedBox(height: 24),
                          _buildSearchCard(),
                        ],

                        const SizedBox(height: 48),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 36),

                        // Operational Trust Metrics
                        _buildTrustRow(isWide),

                        const SizedBox(height: 48),

                        // Supply Chain Lifecycle Visualization
                        _buildJourneySection(),

                        const SizedBox(height: 48),

                        // Footer bar
                        _buildFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SupplyX',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'v1.0',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Nav Links
              if (MediaQuery.of(context).size.width > 680) ...[
                _navLink('Track Product', () => context.push('/verify')),
                const SizedBox(width: 20),
                _navLink('Security Logs', () => context.push('/audit')),
                const SizedBox(width: 20),
                _navLink('Analytics', () => context.push('/analytics')),
                const SizedBox(width: 24),
              ],
              // Login CTA
              SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 14),
                  label: const Text('Operator Sign In', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Hero Left ─────────────────────────────────────────────────────────────
  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Chain of Custody & Traceability',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Operational traceability\nacross every handoff.',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Track manufacturing batches, verify physical QR signatures on receipt, and detect counterfeit products with cryptographic ledger verification.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            _quickStat('10,480', 'Tracked Units'),
            const SizedBox(width: 24),
            _quickStat('94.3%', 'On-Time Rate'),
            const SizedBox(width: 24),
            _quickStat('0.02%', 'Tamper Flag Rate'),
          ],
        ),
      ],
    );
  }

  Widget _quickStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Search Card (Right) ───────────────────────────────────────────────────
  Widget _buildSearchCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Track / Verify Product',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter serial ID or trigger barcode inspection',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Product Serial Number',
            hint: 'e.g. SCX-00112',
            controller: _productIdCtrl,
            prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Inspect Product History',
            icon: Icons.timeline_rounded,
            onPressed: _onTrackProduct,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/qr/scan'),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Scan Physical QR Code', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Sample Serials: ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 6),
              ...['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        _productIdCtrl.text = id;
                        _onTrackProduct();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          id,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Trust Row ─────────────────────────────────────────────────────────────
  Widget _buildTrustRow(bool isWide) {
    final items = [
      (Icons.verified_user_outlined, 'HMAC-SHA256 Signatures', 'Every unit is cryptographically sealed during manufacture.'),
      (Icons.account_tree_outlined, 'Deterministic Custody', 'Real-time ownership handoffs recorded on ledger.'),
      (Icons.shield_outlined, 'Role-Based Guards', 'Strict permission separation across all logistics participants.'),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _trustFeature(item.$1, item.$2, item.$3),
                  ),
                ))
            .toList(),
      );
    }

    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _trustFeature(item.$1, item.$2, item.$3),
              ))
          .toList(),
    );
  }

  Widget _trustFeature(IconData icon, String title, String desc) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  // ─── Journey Workflow ──────────────────────────────────────────────────────
  Widget _buildJourneySection() {
    final stages = [
      ('1', 'Manufacturer', 'Batch creation & signed QR generation', 'Guwahati Factory'),
      ('2', 'Distributor', 'Route acceptance & GPS tracking', 'Transit Network'),
      ('3', 'Warehouse', 'Intake, inspection & ML delay risk check', 'Central Hub'),
      ('4', 'Retailer', 'Proof of delivery & Point of Sale', 'Retail Outlets'),
      ('5', 'Customer', 'Origin verification & anti-counterfeit check', 'Consumer Unit'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5-Stage Chain of Custody',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Each participant confirms transfer to maintain end-to-end provenance.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: stages.asMap().entries.map((entry) {
              final idx = entry.key;
              final stage = entry.value;
              final isLast = idx == stages.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            stage.$1,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (!isLast) Container(width: 1.5, height: 28, color: AppColors.cardBorder),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(stage.$2, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(stage.$4, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(stage.$3, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SupplyX Operations · Cybersecurity & Traceability Engine',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
        ),
        InkWell(
          onTap: () => context.go('/login'),
          child: Text(
            'Partner Portal Sign In →',
            style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
