import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../core/rbac/roles.dart';

/// Public home/landing page — the first screen everyone sees.
/// Shows "Know where your product comes from" + product search + role navigation.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _productIdCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // If already logged in, redirect to dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        _goToDashboard(auth.user!.role);
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
      context.go('/verify/$id');
    } else {
      context.go('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ─── Wide (Web) Layout ───────────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 5, child: _buildHeroSection()),
              Expanded(flex: 4, child: _buildSearchPanel()),
            ],
          ),
        ),
        _buildTrustBadges(),
        _buildHowItWorks(),
      ],
    );
  }

  // ─── Mobile Layout ───────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          _buildHeroSection(),
          _buildSearchPanel(),
          _buildTrustBadges(),
          _buildHowItWorks(),
        ],
      ),
    );
  }

  // ─── Top Navigation Bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'SupplyChainX',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Nav items (wide only)
          if (MediaQuery.of(context).size.width > 700) ...[
            _navItem('Home', true),
            _navItem('Track Product', false),
            _navItem('About', false),
            _navItem('Login', false),
            const SizedBox(width: 8),
          ],
          // Login CTA
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, bool active) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );

  // ─── Hero Section ────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Blockchain-Secured Supply Chain',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 42,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: 'KNOW WHERE YOUR\n'),
                TextSpan(text: 'PRODUCT ', style: TextStyle(color: AppColors.primary)),
                TextSpan(text: 'COMES FROM'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Track every product from manufacturing to delivery.\nVerify authenticity with a single scan.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          // Trust stats row
          Row(
            children: [
              _heroStat('10K+', 'Products Tracked'),
              const SizedBox(width: 32),
              _heroStat('99.9%', 'Authenticity Rate'),
              const SizedBox(width: 32),
              _heroStat('5', 'Supply Chain Roles'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );

  // ─── Search/Track Panel ──────────────────────────────────────────────────
  Widget _buildSearchPanel() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 40, spreadRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track a Product',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a product ID or scan its QR code',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Product ID input
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _productIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter Product ID (e.g. SCX-00112)',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _onTrackProduct(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Track button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _onTrackProduct,
                icon: const Icon(Icons.track_changes_rounded, size: 18),
                label: const Text('Track Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.cardBorder)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
              const Expanded(child: Divider(color: AppColors.cardBorder)),
            ],
          ),
          const SizedBox(height: 16),

          // Scan QR button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/qr/scan'),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Demo quick links
          const Text('Demo Products:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) {
              return ActionChip(
                label: Text(id, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                backgroundColor: AppColors.primaryDim,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                onPressed: () {
                  _productIdCtrl.text = id;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Trust Badges ────────────────────────────────────────────────────────
  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _trustBadge(Icons.verified_rounded, '✓ Authenticity', 'Cryptographically signed products'),
          _trustBadge(Icons.timeline_rounded, '✓ Traceability', 'Full journey from farm to shelf'),
          _trustBadge(Icons.lock_rounded, '✓ Transparency', 'Immutable blockchain records'),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String title, String subtitle) => Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      );

  // ─── How It Works ────────────────────────────────────────────────────────
  Widget _buildHowItWorks() {
    final steps = [
      ('🏭', 'Manufacturer', 'Registers product & generates a signed QR code'),
      ('🚛', 'Distributor', 'Picks up and transfers to warehouse'),
      ('🏪', 'Warehouse', 'Stores and quality-checks the product'),
      ('🏬', 'Retailer', 'Receives and prepares for sale'),
      ('👤', 'Customer', 'Scans QR to verify authenticity'),
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Supply Chain Journey',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 0,
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 16),
                );
              }
              final step = steps[i ~/ 2];
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Text(step.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(step.$2,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(step.$3,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          // Login CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Are you a supply chain partner? ', style: TextStyle(color: AppColors.textMuted)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Login to your dashboard →',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
