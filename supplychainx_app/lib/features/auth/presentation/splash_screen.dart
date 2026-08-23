import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../app.dart';

/// Clean Industrial-Tech Landing Page for SupplyX
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _productIdCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;

  @override
  void dispose() {
    _productIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTrackProduct() async {
    final id = _productIdCtrl.text.trim();
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 350));
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
    final isWide = screenWidth > 960;
    final auth = ref.watch(authProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildMobileDrawer(context, auth),
      appBar: _buildTopNavBar(context, isWide, auth),
      body: _isSearching
          ? const CenterPageLoading(message: 'Querying cryptographic custody records...')
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Authenticated Session Banner (if logged in)
                        if (auth.isAuthenticated) ...[
                          _buildAuthWelcomeBanner(context, auth),
                          const SizedBox(height: 24),
                        ],

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

                        // Compliance, Terms & Privacy Section
                        _buildLegalAndPrivacySection(),

                        const SizedBox(height: 48),

                        // Footer bar
                        _buildFooter(auth),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAuthWelcomeBanner(BuildContext context, AuthState auth) {
    final roleRoute = dashboardRoute(auth.user!.role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signed in as ${auth.user!.displayName} (${auth.user!.role.label})',
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.go(roleRoute),
            icon: const Icon(Icons.dashboard_rounded, size: 14),
            label: const Text('Open My Dashboard →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Navigation Bar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildTopNavBar(BuildContext context, bool isWide, AuthState auth) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          // Logo & Brand
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 18),
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
                    'OPERATIONS',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Desktop Navigation Links
          if (isWide) ...[
            _navButton('Home', () => context.go('/')),
            _navButton('🤖 ML Predictor', () => context.push('/ml-studio')),
            _navButton('💬 AI Assistant', () => context.push('/assistant')),
            _navButton('Track Consignment', () => context.push('/verify')),
            _navButton('Optical Scanner', () => context.push('/qr/scan')),
            _navButton('Analytics', () => context.push('/analytics')),
            _navButton('Security Logs', () => context.push('/audit')),
            const SizedBox(width: 10),

            if (auth.isAuthenticated) ...[
              ElevatedButton.icon(
                onPressed: () => context.go(dashboardRoute(auth.user!.role)),
                icon: const Icon(Icons.dashboard_outlined, size: 14),
                label: const Text('Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
                tooltip: 'Sign Out',
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded, size: 14),
                label: const Text('Operator Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ],
          ] else ...[
            // Mobile Menu Trigger
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Navigation Menu',
            ),
          ],
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mobile Navigation Drawer ─────────────────────────────────────────────
  Widget _buildMobileDrawer(BuildContext context, AuthState auth) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.sidebar),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.hub_outlined, color: AppColors.textPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SupplyX Operations',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  auth.isAuthenticated
                      ? 'Active Session: ${auth.user!.displayName} (${auth.user!.role.label})'
                      : 'Traceability & Cryptographic Proof of Custody',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.home_outlined, 'Home', () {
            Navigator.pop(context);
            context.go('/');
          }),
          if (auth.isAuthenticated)
            _drawerTile(Icons.dashboard_rounded, 'My Operations Dashboard', () {
              Navigator.pop(context);
              context.go(dashboardRoute(auth.user!.role));
            }),
          _drawerTile(Icons.search_rounded, 'Track Consignment', () {
            Navigator.pop(context);
            context.push('/verify');
          }),
          _drawerTile(Icons.qr_code_scanner_rounded, 'Optical Barcode Scanner', () {
            Navigator.pop(context);
            context.push('/qr/scan');
          }),
          _drawerTile(Icons.shield_outlined, 'Security Audit Stream', () {
            Navigator.pop(context);
            context.push('/audit');
          }),
          _drawerTile(Icons.bar_chart_outlined, 'Analytics & KPIs', () {
            Navigator.pop(context);
            context.push('/analytics');
          }),
          _drawerTile(Icons.smart_toy_outlined, 'AI Logistics Assistant', () {
            Navigator.pop(context);
            context.push('/assistant');
          }),
          const Divider(color: AppColors.cardBorder),
          _drawerTile(Icons.gavel_rounded, 'Terms of Service', () {
            Navigator.pop(context);
            context.push('/terms');
          }),
          _drawerTile(Icons.privacy_tip_outlined, 'Privacy & Compliance Policy', () {
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
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      onTap: onTap,
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
                decoration: const BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Chain of Custody & Traceability',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
                            color: AppColors.textPrimary,
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

  // ─── Terms & Privacy Checking Section on Home Page ─────────────────────────
  Widget _buildLegalAndPrivacySection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                'Enterprise Governance & Legal Compliance',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SupplyX operates under strict data protection and custodial accountability standards.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/terms'),
                  icon: const Icon(Icons.article_outlined, size: 16),
                  label: const Text('Read Terms of Service', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/privacy'),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text('Read Privacy Policy', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(AuthState auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SupplyX Operations · Cybersecurity & Traceability Engine',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => context.push('/terms'),
              child: Text(
                'Terms',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
            InkWell(
              onTap: () => context.push('/privacy'),
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
            if (auth.isAuthenticated)
              InkWell(
                onTap: () => context.go(dashboardRoute(auth.user!.role)),
                child: Text(
                  'My Dashboard →',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )
            else
              InkWell(
                onTap: () => context.go('/login'),
                child: Text(
                  'Partner Sign In →',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
