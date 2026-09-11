import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../app.dart';

/// Agency-Grade Enterprise Landing Page & Web Portal for SupplyChainX
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  final _productIdCtrl = TextEditingController(text: 'SCX-00112');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  int _activeBannerIndex = 0;
  late AnimationController _pulseCtrl;
  late AnimationController _scannerBeamCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerBeamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _productIdCtrl.dispose();
    _pulseCtrl.dispose();
    _scannerBeamCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTrackProduct([String? customId]) async {
    final id = (customId ?? _productIdCtrl.text).trim();
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isSearching = false);

    if (id.isNotEmpty) {
      context.push('/verify/$id');
    } else {
      context.push('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;
    final auth = ref.watch(authProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildMobileDrawer(context, auth),
      appBar: _buildTopNavBar(context, isDesktop, auth),
      body: _isSearching
          ? const CenterPageLoading(message: 'Tracking consignment & verifying delivery records...')
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ─── HEAD BANNER UNDER NAVIGATION ───────────────────────────
                  _buildGlobalHeadBanner(context, isDesktop, isTablet, auth),

                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 36 : (isTablet ? 24 : 16),
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── HERO SECTION ─────────────────────────────
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: _buildHeroLeft(isDesktop)),
                                  const SizedBox(width: 48),
                                  Expanded(flex: 5, child: _buildInteractiveSimulatorCard()),
                                ],
                              )
                            else ...[
                              _buildHeroLeft(isDesktop),
                              const SizedBox(height: 32),
                              _buildInteractiveSimulatorCard(),
                            ],

                            const SizedBox(height: 56),

                            // ─── OPERATIONAL METRICS STRIP ───────────────
                            _buildKpiMetricsStrip(isDesktop, isTablet),

                            const SizedBox(height: 48),

                            // ─── VISUAL OPERATIONS SHOWCASE BANNER ──────
                            _buildVisualOperationsShowcaseBanner(isDesktop, isTablet),

                            const SizedBox(height: 64),

                            // ─── ARCHITECTURAL 4-PILLAR MATRIX ───────────
                            _buildArchitecturePillars(isDesktop, isTablet),

                            const SizedBox(height: 64),

                            // ─── 5-STAGE CUSTODY WORKFLOW ─────────────────
                            _buildCustodyPipelineSection(isDesktop),

                            const SizedBox(height: 64),

                            // ─── LIVE TELEMETRY & THREAT MONITOR ──────────
                            _buildTelemetryConsoleSection(isDesktop),

                            const SizedBox(height: 64),

                            // ─── MULTI-ROLE WORKSPACES ───────────────────
                            _buildStakeholderWorkspacesSection(isDesktop, isTablet, auth),

                            const SizedBox(height: 64),

                            // ─── COMPLIANCE & LEGAL ACCORD ───────────────
                            _buildComplianceAndLegalSection(context),

                            const SizedBox(height: 56),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── ENTERPRISE MULTI-COLUMN FOOTER ───────────────────
                  _buildComprehensiveFooter(context, auth),
                ],
              ),
            ),
    );
  }

  // ─── Global Logistics Head Banner Under Navigation ──────────────────────────
  Widget _buildGlobalHeadBanner(BuildContext context, bool isDesktop, bool isTablet, AuthState auth) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Stack(
        children: [
          // Background High-Res Air Cargo & Logistics Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/global_logistics_banner.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Deep Multi-Stop Gradient Scrim (ensures contrast & maximum readability)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF8080E1A),
                    Color(0xEE0F172A),
                    Color(0xC00F172A),
                    Color(0x550F172A),
                  ],
                  stops: [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Glowing Industrial Yellow Bottom Accent Line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 36 : (isTablet ? 24 : 16),
                  vertical: isDesktop ? 28 : 20,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 7, child: _buildHeadBannerText(context)),
                          const SizedBox(width: 32),
                          Expanded(flex: 5, child: _buildHeadBannerQuickTrack(context)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeadBannerText(context),
                          const SizedBox(height: 18),
                          _buildHeadBannerQuickTrack(context),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Head Banner Text Content ───────────────────────────────────────────────
  Widget _buildHeadBannerText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live Network Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GLOBAL AIR & GROUND FREIGHT NETWORK • 220+ COUNTRIES & TERRITORIES',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Headline
        Text(
          'Next-Gen Air Cargo, Freight &\nLast-Mile Delivery Operations.',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        Text(
          'Synchronized real-time GPS fleet tracking, bonded warehouse fulfillment, and cryptographically verified proof-of-delivery across international transport corridors.',
          style: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1),
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Service Capability Chips
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _headBannerCapabilityChip(Icons.flight_takeoff_rounded, 'Air Cargo'),
            _headBannerCapabilityChip(Icons.local_shipping_rounded, 'Interstate Freight'),
            _headBannerCapabilityChip(Icons.bolt_rounded, 'Same-Day Express'),
            _headBannerCapabilityChip(Icons.verified_rounded, 'Verified Custody'),
          ],
        ),
      ],
    );
  }

  Widget _headBannerCapabilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Head Banner Quick Track Pod ───────────────────────────────────────────
  Widget _buildHeadBannerQuickTrack(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xDD0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'EXPRESS TRACKING PORTAL',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Text(
                  'LIVE SLA: 99.4%',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compact Search Input Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: TextField(
                    controller: _productIdCtrl,
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Enter Tracking ID (e.g. SCX-00112)',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _onTrackProduct(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _onTrackProduct(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Serial Selector Chips
          Row(
            children: [
              Text(
                'Quick Samples: ',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10),
              ),
              const SizedBox(width: 4),
              ...['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() => _productIdCtrl.text = id);
                      _onTrackProduct();
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        id,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Top Navigation Bar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildTopNavBar(BuildContext context, bool isDesktop, AuthState auth) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          // Logo & Brand Mark
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SupplyChainX',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Text(
                            'EXPRESS LOGISTICS',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Global Freight & Delivery Operations',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Desktop Navigation Links
          if (isDesktop) ...[
            _navItem('Track Consignment', Icons.track_changes_outlined, () => context.push('/verify')),
            _navItem('Optical Scanner', Icons.qr_code_scanner_rounded, () => context.push('/qr/scan')),
            _navItem('ML Delay Studio', Icons.model_training_rounded, () => context.push('/ml-studio'), isHighlighted: true),
            _navItem('AI Copilot', Icons.smart_toy_outlined, () => context.push('/assistant')),
            _navItem('Analytics', Icons.bar_chart_outlined, () => context.push('/analytics')),
            _navItem('Security Logs', Icons.shield_outlined, () => context.push('/audit')),
            const SizedBox(width: 14),

            if (auth.isAuthenticated) ...[
              ElevatedButton.icon(
                onPressed: () => context.go(dashboardRoute(auth.user!.role)),
                icon: const Icon(Icons.dashboard_rounded, size: 15),
                label: Text('${auth.user!.role.label} Dashboard', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
                tooltip: 'Sign Out Session',
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded, size: 15),
                label: const Text('Operator Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Navigation Menu',
            ),
          ],
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, VoidCallback onTap, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Left Column ───────────────────────────────────────────────────────
  Widget _buildHeroLeft(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security & Network Protocol Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryBorder),
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
              const SizedBox(width: 8),
              Text(
                'GLOBAL FREIGHT & PARCEL DELIVERY NETWORK • REAL-TIME DISPATCH',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Main Headline
        Text(
          'Global Freight Tracking &\nVerified Delivery Services.',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 44 : 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 16),

        // Value Proposition Body Copy
        Text(
          'Enterprise air cargo, cross-border freight forwarding, automated warehouse fulfillment, and verified last-mile delivery. Track shipments with live GPS, predictive AI arrival forecasts, and tamper-proof digital proof-of-delivery across 5 interconnected supply chain stages.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: isDesktop ? 16 : 14,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        // Hero CTA Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => _onTrackProduct(),
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Track Consignment / Order →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/qr/scan'),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Launch Barcode Scanner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: AppColors.cardBorderStrong),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/ml-studio'),
              icon: const Icon(Icons.model_training_rounded, size: 16, color: AppColors.navy),
              label: const Text('Route & Delay Forecast', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: AppColors.cardBorderStrong),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Trust Badges Line
        Row(
          children: [
            _trustIconBadge(Icons.lock_outline_rounded, 'Tamper-Proof Digital Seal'),
            const SizedBox(width: 18),
            _trustIconBadge(Icons.account_tree_outlined, 'Verified Chain of Custody'),
            const SizedBox(width: 18),
            _trustIconBadge(Icons.psychology_outlined, 'Predictive Route AI'),
          ],
        ),
      ],
    );
  }

  Widget _trustIconBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.navy),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Interactive Consignment Inspection Card (Hero Right) ───────────────────
  Widget _buildInteractiveSimulatorCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping_rounded, size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Consignment & Dispatch Tracking',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Real-time carrier & proof-of-delivery verification',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          AppTextField(
            label: 'Consignment / Tracking Number',
            hint: 'e.g. SCX-00112',
            controller: _productIdCtrl,
            prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppColors.textMuted),
          ),

          const SizedBox(height: 12),

          // 1-Click Sample Serial Chips
          Row(
            children: [
              Text('Sample Shipments: ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) {
                    final isSelected = _productIdCtrl.text == id;
                    return InkWell(
                      onTap: () {
                        setState(() => _productIdCtrl.text = id);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryBorder : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          id,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Dispatch Status / Route Preview Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE CARRIER STATUS',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'IN TRANSIT • ON TIME',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Consignment: ${_productIdCtrl.text.isEmpty ? "NONE" : _productIdCtrl.text} (Express Freight)',
                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Route: Guwahati Air Hub ➔ Siliguri Logistics Center',
                  style: GoogleFonts.jetBrainsMono(color: const Color(0xFF64748B), fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  'Custodian: Apex Express · Cold-Chain: 4.2°C (Optimal)',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          PrimaryButton(
            label: 'Track Consignment Details →',
            icon: Icons.verified_user_rounded,
            onPressed: () => _onTrackProduct(),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 38,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/qr/scan'),
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: const Text('Launch Barcode & QR Scanner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Metrics Strip ─────────────────────────────────────────────────────
  Widget _buildKpiMetricsStrip(bool isDesktop, bool isTablet) {
    final metrics = [
      ('148,250+', 'Shipments Dispatched', 'Active freight consignments & parcel deliveries'),
      ('99.98%', 'Verified Delivery Rate', 'Zero lost handoffs with digital proof-of-delivery'),
      ('94.8%', 'On-Time Transit Rate', 'AI route delay prediction & smart dynamic bypasses'),
      ('< 380ms', 'Dispatch Scan Latency', 'High-speed automated barcode & RFID hub intake'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: isDesktop
          ? Row(
              children: metrics.asMap().entries.map((entry) {
                final idx = entry.key;
                final m = entry.value;
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: idx == metrics.length - 1
                            ? BorderSide.none
                            : const BorderSide(color: AppColors.cardBorder, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _kpiItem(m.$1, m.$2, m.$3),
                  ),
                );
              }).toList(),
            )
          : Wrap(
              spacing: 20,
              runSpacing: 20,
              children: metrics.map((m) {
                return SizedBox(
                  width: isTablet ? (MediaQuery.of(context).size.width / 2) - 48 : double.infinity,
                  child: _kpiItem(m.$1, m.$2, m.$3),
                );
              }).toList(),
            ),
    );
  }

  Widget _kpiItem(String value, String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Visual Operations Showcase Banner ───────────────────────────────────────
  Widget _buildVisualOperationsShowcaseBanner(bool isDesktop, bool isTablet) {
    final slides = [
      (
        image: 'assets/images/logistics_fleet.jpg',
        badge: 'CORRIDOR TELEMETRY • HIGHWAY A4',
        title: 'High-Speed Freight Transit & Route Telemetry',
        description: 'Real-time transit risk modeling monitoring arterial speed, weather disruptions, and GPS checkpoints with sub-second hash generation.',
        metrics: [
          ('88 KM/H', 'Cruising Velocity'),
          ('SILIGURI HUB', 'Next Waypoint 12km'),
          ('19:34 IST', 'Dynamic ML ETA'),
        ],
        actionLabel: 'Launch ML Transit Predictor →',
        actionRoute: '/ml-studio',
      ),
      (
        image: 'assets/images/smart_warehouse.jpg',
        badge: 'AUTOMATED INTAKE • HUB 04',
        title: 'Robotic Conveyor Sorting & Inbound Quality Verification',
        description: 'Computer-vision and barcode laser scanners verifying physical package dimensions and HMAC-SHA256 seals against live custody records.',
        metrics: [
          ('1,420 BINS', 'Active Warehouse Storage'),
          ('99.1%', 'Automated Intake Accuracy'),
          ('ZERO DELAYS', 'Buffer Stock Nominal'),
        ],
        actionLabel: 'Explore Warehouse Control →',
        actionRoute: '/dashboard/warehouse',
      ),
      (
        image: 'assets/images/delivery_pickup.jpg',
        badge: 'LAST-MILE DISPATCH • POS TERMINAL',
        title: 'Zero-Emission Courier Pickup & Optical QR Handover',
        description: 'Handheld laser scanners authenticating physical digital seals at the loading dock to guarantee zero counterfeit vulnerability.',
        metrics: [
          ('ELECTRIC FLEET', 'Zero-Carbon Logistics'),
          ('100% VERIFIED', 'Cryptographic Intake Seal'),
          ('0.00% COUNTERFEIT', 'Mathematical Certainty'),
        ],
        actionLabel: 'Launch Optical Scanner →',
        actionRoute: '/qr/scan',
      ),
    ];

    final currentSlide = slides[_activeBannerIndex];
    final bannerHeight = isDesktop ? 380.0 : (isTablet ? 350.0 : 440.0);

    return Container(
      height: bannerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image with Animated Fade
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                currentSlide.image,
                key: ValueKey(currentSlide.image),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // High-Tech Scrim Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xF50B132B),
                    const Color(0xEE0F172A),
                    const Color(0x990F172A),
                    const Color(0x440F172A),
                  ],
                  stops: const [0.0, 0.45, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Animated Laser Scanning Line
          AnimatedBuilder(
            animation: _scannerBeamCtrl,
            builder: (context, _) {
              return Positioned(
                top: _scannerBeamCtrl.value * bannerHeight,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.8),
                        Colors.cyanAccent,
                        AppColors.primary.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Content Layer
          Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag + Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
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
                          const SizedBox(width: 8),
                          Text(
                            currentSlide.badge,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE SENSOR FEED',
                            style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Title & Description
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSlide.title,
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 24 : 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSlide.description,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFCBD5E1),
                          fontSize: isDesktop ? 13 : 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Telemetry Metric Badges
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: currentSlide.metrics.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.$1,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            m.$2,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Navigation Tabs & Action Button
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(currentSlide.actionRoute),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text(
                        currentSlide.actionLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    // Slide Selector Indicator Buttons
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _bannerTabBtn(0, '1. Freight Transit', Icons.local_shipping_outlined),
                          _bannerTabBtn(1, '2. Smart Warehouse', Icons.warehouse_outlined),
                          _bannerTabBtn(2, '3. Delivery Pickup', Icons.qr_code_scanner_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerTabBtn(int index, String label, IconData icon) {
    final isSelected = _activeBannerIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeBannerIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? AppColors.textOnPrimary : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.textOnPrimary : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Architectural 4-Pillar Matrix ──────────────────────────────────────────
  Widget _buildArchitecturePillars(bool isDesktop, bool isTablet) {
    final pillars = [
      (
        Icons.local_shipping_outlined,
        'End-to-End Shipment Visibility',
        'Real-time GPS corridor tracking, multi-carrier status checkpoints, and automated ETA alerts across global air, ocean, and ground supply lines.',
        'VISIBILITY LAYER',
        () => context.push('/verify')
      ),
      (
        Icons.model_training_rounded,
        'Predictive Route & Delay AI',
        'Random Forest ML pipeline evaluated across 14 live features (weather, highway congestion, transit velocity) with SHAP attribution for delay prevention.',
        'INTELLIGENCE LAYER',
        () => context.push('/ml-studio')
      ),
      (
        Icons.verified_user_outlined,
        'Tamper-Proof Delivery Verification',
        'HMAC digital signatures generated at dispatch. Every subsequent handoff seals an immutable cryptographic proof-of-delivery block.',
        'SECURITY LAYER',
        () => context.push('/audit')
      ),
      (
        Icons.admin_panel_settings_outlined,
        'Enterprise Multi-Role Portals',
        'Dedicated operational workspaces for Shippers, Freight Carriers, Fulfillment Warehouses, Retailers, and End Consumers.',
        'OPERATIONS LAYER',
        () => context.go('/login')
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeadingBadge('CORE CAPABILITIES', 'Enterprise Logistics Foundation'),
        const SizedBox(height: 8),
        Text(
          'Engineered for High-Velocity Freight & Guaranteed Verification',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Four integrated logistics systems working in lockstep to secure cargo, predict transit risks, and accelerate delivery.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isDesktop
                ? (constraints.maxWidth - 48) / 4
                : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: pillars.map((p) {
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    onTap: p.$5,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(p.$1, color: AppColors.navy, size: 22),
                              ),
                              Text(
                                p.$4,
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            p.$2,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.$3,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'Explore Module',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textPrimary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ─── 5-Stage Custody Pipeline Section ───────────────────────────────────────
  Widget _buildCustodyPipelineSection(bool isDesktop) {
    final stages = [
      (
        '1',
        'Origin & Batch Dispatch',
        'Guwahati Production Hub',
        'Consignment registered with digital tamper seal and initial dispatch manifest generated.',
        'MANIFEST #DISP-001',
        Icons.factory_outlined,
      ),
      (
        '2',
        'Cross-Dock Freight Transit',
        'Siliguri Regional Logistics Hub',
        'Outbound highway transit verified, GPS waypoints broadcasted, and carrier handoff signed.',
        'CARRIER #TRK-940',
        Icons.local_shipping_outlined,
      ),
      (
        '3',
        'Fulfillment & Sortation',
        'Kolkata Central Distribution Center',
        'Inbound conveyor laser intake verified, automated route delay risk calculated, bin assigned.',
        'HUB BIN #KOL-14',
        Icons.warehouse_outlined,
      ),
      (
        '4',
        'Local Hub & Retail Intake',
        'Metro Retail Distribution Center',
        'Pallet barcode seals confirmed on loading dock intake; retail shelf inventory ready.',
        'RETAIL #MET-04',
        Icons.storefront_outlined,
      ),
      (
        '5',
        'Last-Mile Delivery & Handover',
        'Customer Destination',
        'Recipient scans delivery QR to complete proof-of-delivery and confirm genuine package receipt.',
        'VERIFIED #DEL-100',
        Icons.verified_user_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeadingBadge('GLOBAL DELIVERY PIPELINE', '5-Stage Connected Custody'),
        const SizedBox(height: 8),
        Text(
          'End-to-End Shipment Journey & Proof of Delivery',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Every transport checkpoint cryptographically seals custody transition to maintain absolute delivery accountability.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: stages.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isLast = idx == stages.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Number & Connecting Line
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: idx == 0 || isLast ? AppColors.navy : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: idx == 0 || isLast ? AppColors.navy : AppColors.cardBorderStrong,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              s.$1,
                              style: GoogleFonts.inter(
                                color: idx == 0 || isLast ? Colors.white : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.cardBorder,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 18),

                    // Stage Information
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(s.$6, size: 16, color: AppColors.navy),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.$2,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Text(
                                      s.$3,
                                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    s.$5,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.$4,
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Live Telemetry Console Section ─────────────────────────────────────────
  Widget _buildTelemetryConsoleSection(bool isDesktop) {
    final telemetryLogs = [
      ('[08:14:22 UTC]', 'DISPATCH_SEALED', 'Consignment SCX-00112 cleared customs and sealed with digital tamper lock', AppColors.success),
      ('[08:21:05 UTC]', 'AIR_CARGO_DEP', 'Flight SCX-882 departed Guwahati Air Hub ➔ Siliguri Freight Center', AppColors.primary),
      ('[08:35:40 UTC]', 'AI_ROUTE_OPT', 'Corridor NH-27 weather bypass suggested; dynamic ETA updated (-45m)', AppColors.warning),
      ('[09:02:11 UTC]', 'HUB_INTAKE_OK', 'Kolkata Central Hub confirmed automated intake at Conveyor Bin 14', AppColors.success),
      ('[09:14:50 UTC]', 'DELIVERY_SIGNED', 'Final customer recipient verified digital proof-of-delivery at POS', AppColors.textPrimary),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                'LIVE FLEET TELEMETRY & DISPATCH OPERATIONS',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push('/audit'),
                child: Row(
                  children: [
                    Text(
                      'Open Full Audit Stream →',
                      style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),
          ...telemetryLogs.map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.$1,
                    style: GoogleFonts.jetBrainsMono(color: const Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (log.$4 == AppColors.primary ? const Color(0xFFEDDB43) : log.$4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.$2,
                      style: GoogleFonts.jetBrainsMono(
                        color: log.$4 == AppColors.textPrimary ? Colors.white : (log.$4 == AppColors.primary ? const Color(0xFFEDDB43) : log.$4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log.$3,
                      style: GoogleFonts.inter(color: const Color(0xFFE2E8F0), fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Multi-Role Stakeholder Workspaces ───────────────────────────────────────
  Widget _buildStakeholderWorkspacesSection(bool isDesktop, bool isTablet, AuthState auth) {
    final roles = [
      (
        'Shipper / Manufacturer',
        'Batch Dispatch & Manifest Generation',
        'Provision consignment serials, generate digital HMAC package seals, and dispatch freight.',
        Icons.precision_manufacturing_outlined,
        '/dashboard/manufacturer',
      ),
      (
        'Carrier / Distributor',
        'Fleet Transit, Telemetry & Waypoints',
        'Accept physical freight, broadcast real-time GPS waypoints, and confirm transport handoffs.',
        Icons.local_shipping_outlined,
        '/dashboard/distributor',
      ),
      (
        'Fulfillment Warehouse',
        'Automated Intake, Bins & Route AI',
        'Scan conveyor barcodes, monitor cold-chain compliance, and route packages to outbound bays.',
        Icons.warehouse_outlined,
        '/dashboard/warehouse',
      ),
      (
        'Retail Store',
        'Dock Receiving & Point of Sale',
        'Verify pallet integrity on dock intake and register authentic proof-of-purchase.',
        Icons.storefront_outlined,
        '/dashboard/retailer',
      ),
      (
        'Recipient / Customer',
        'Consignment Tracking & Proof of Delivery',
        'Track active shipment milestones, verify digital delivery authenticity, and inspect route history.',
        Icons.verified_user_outlined,
        '/verify',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeadingBadge('LOGISTICS PORTALS', 'Multi-Stakeholder Workspaces'),
        const SizedBox(height: 8),
        Text(
          'Tailored Operations Control for Every Logistics Participant',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Secure, role-based workflows orchestrating cargo manifests, fleet transit, and delivery handovers.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isDesktop
                ? (constraints.maxWidth - 48) / 3
                : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: roles.map((r) {
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    onTap: () {
                      if (auth.isAuthenticated) {
                        context.go(r.$5);
                      } else {
                        context.go('/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(r.$4, size: 20, color: AppColors.navy),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r.$1,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            r.$2,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.$3,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                auth.isAuthenticated ? 'Launch Workspace' : 'Sign In as ${r.$1}',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textPrimary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ─── Compliance, Legal & Standards Section ──────────────────────────────────
  Widget _buildComplianceAndLegalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.navy, size: 22),
              const SizedBox(width: 10),
              Text(
                'Global Logistics Compliance & Trade Security Accord',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SupplyChainX adheres strictly to ISO-28000 supply chain security management, WCO SAFE trade frameworks, and FIPS-180-4 cryptographic tamper-verification standards.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/terms'),
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: const Text('Read Terms of Service', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/privacy'),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text('Read Privacy & Custody Policy', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Comprehensive Multi-Column Footer ──────────────────────────────────────
  Widget _buildComprehensiveFooter(BuildContext context, AuthState auth) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _footerBrandColumn()),
                          const SizedBox(width: 48),
                          Expanded(flex: 2, child: _footerLinksColumn('Platform Core', [
                            ('Track Consignment', () => context.push('/verify')),
                            ('Optical Scanner', () => context.push('/qr/scan')),
                            ('Register Consignment', () => context.push('/product/register')),
                            ('Security Telemetry', () => context.push('/audit')),
                          ])),
                          Expanded(flex: 2, child: _footerLinksColumn('Intelligence & ML', [
                            ('ML Delay Predictor', () => context.push('/ml-studio')),
                            ('AI Operations Copilot', () => context.push('/assistant')),
                            ('Transit Analytics', () => context.push('/analytics')),
                            ('Corridor Risk Heatmap', () => context.push('/analytics')),
                          ])),
                          Expanded(flex: 2, child: _footerLinksColumn('Governance & Legal', [
                            ('Terms of Service', () => context.push('/terms')),
                            ('Privacy Policy', () => context.push('/privacy')),
                            ('Security Architecture', () => context.push('/security')),
                            (auth.isAuthenticated ? 'Sign Out Session' : 'Partner Sign In', () {
                              if (auth.isAuthenticated) {
                                ref.read(authProvider.notifier).logout();
                              } else {
                                context.go('/login');
                              }
                            }),
                          ])),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _footerBrandColumn(),
                          const SizedBox(height: 32),
                          _footerLinksColumn('Platform Core', [
                            ('Track Consignment', () => context.push('/verify')),
                            ('Optical Scanner', () => context.push('/qr/scan')),
                            ('Register Consignment', () => context.push('/product/register')),
                            ('Security Telemetry', () => context.push('/audit')),
                          ]),
                          const SizedBox(height: 24),
                          _footerLinksColumn('Intelligence & ML', [
                            ('ML Delay Predictor', () => context.push('/ml-studio')),
                            ('AI Operations Copilot', () => context.push('/assistant')),
                            ('Transit Analytics', () => context.push('/analytics')),
                          ]),
                          const SizedBox(height: 24),
                          _footerLinksColumn('Governance', [
                            ('Terms of Service', () => context.push('/terms')),
                            ('Privacy Policy', () => context.push('/privacy')),
                          ]),
                        ],
                      );
              }),

              const SizedBox(height: 48),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 SupplyChainX Technologies Inc. All rights reserved.',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Global Logistics Network Online · SLAs Verified',
                        style: GoogleFonts.jetBrainsMono(color: const Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerBrandColumn() {
    return Column(
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
              'SupplyChainX',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Enterprise air cargo, interstate freight forwarding, and verified last-mile delivery network. Unifying live GPS corridor intelligence, automated bonded warehouse fulfillment, and tamper-proof digital proof-of-delivery.',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _footerLinksColumn(String header, List<(String, VoidCallback)> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: link.$2,
              child: Text(
                link.$1,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionHeadingBadge(String badge, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Text(
            badge,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile Drawer ────────────────────────────────────────────────────────
  Widget _buildMobileDrawer(BuildContext context, AuthState auth) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  auth.isAuthenticated
                      ? 'Operator: ${auth.user!.displayName} (${auth.user!.role.label})'
                      : 'Global Freight & Delivery Operations',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.home_outlined, 'Home Portal', () {
            Navigator.pop(context);
            context.go('/');
          }),
          if (auth.isAuthenticated)
            _drawerTile(Icons.dashboard_rounded, '${auth.user!.role.label} Dashboard', () {
              Navigator.pop(context);
              context.go(dashboardRoute(auth.user!.role));
            }),
          _drawerTile(Icons.track_changes_outlined, 'Track Shipment / Order', () {
            Navigator.pop(context);
            context.push('/verify');
          }),
          _drawerTile(Icons.qr_code_scanner_rounded, 'Barcode & QR Scanner', () {
            Navigator.pop(context);
            context.push('/qr/scan');
          }),
          _drawerTile(Icons.model_training_rounded, 'ML Transit Delay Studio', () {
            Navigator.pop(context);
            context.push('/ml-studio');
          }),
          _drawerTile(Icons.smart_toy_outlined, 'AI Operations Copilot', () {
            Navigator.pop(context);
            context.push('/assistant');
          }),
          _drawerTile(Icons.bar_chart_outlined, 'Logistics Analytics', () {
            Navigator.pop(context);
            context.push('/analytics');
          }),
          _drawerTile(Icons.shield_outlined, 'Security Audit Stream', () {
            Navigator.pop(context);
            context.push('/audit');
          }),
          const Divider(color: AppColors.cardBorder),
          _drawerTile(Icons.gavel_rounded, 'Terms of Service', () {
            Navigator.pop(context);
            context.push('/terms');
          }),
          _drawerTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
            Navigator.pop(context);
            context.push('/privacy');
          }),
          const Divider(color: AppColors.cardBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: auth.isAuthenticated
                ? OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out Session'),
                  )
                : PrimaryButton(
                    label: 'Operator Sign In',
                    icon: Icons.login_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy, size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
