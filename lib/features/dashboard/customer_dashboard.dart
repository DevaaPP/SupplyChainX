import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../product/domain/product_model.dart';
import 'dashboard_shell.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Customer Portal',
      tabs: const [
        DashboardTab(
          icon: Icons.qr_code_scanner_outlined,
          activeIcon: Icons.qr_code_scanner_rounded,
          label: 'Verify',
        ),
        DashboardTab(
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag_rounded,
          label: 'My Orders',
        ),
      ],
      pages: const [
        _VerifyProductTab(),
        _MyOrdersTab(),
      ],
    );
  }
}

// ─── Tab 1: Verify Product ─────────────────────────────────────────────────
class _VerifyProductTab extends StatefulWidget {
  const _VerifyProductTab();

  @override
  State<_VerifyProductTab> createState() => _VerifyProductTabState();
}

class _VerifyProductTabState extends State<_VerifyProductTab> {
  final _idCtrl = TextEditingController();

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final id = _idCtrl.text.trim();
    if (id.isNotEmpty) {
      context.push('/verify/$id');
    } else {
      context.push('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              // Hero Banner
              GlassCard(
                color: AppColors.primaryDim,
                borderColor: AppColors.primary.withOpacity(0.3),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Verify Product Authenticity',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan the physical QR code on your product box or enter the serial code to inspect the blockchain proof of origin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Launch Camera Scanner',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () => context.push('/qr/scan'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // OR divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR ENTER SERIAL ID',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),
              const SizedBox(height: 20),

              // Manual Input
              GlassCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Product ID / Serial Number',
                      hint: 'e.g. SCX-00112',
                      controller: _idCtrl,
                      prefixIcon: const Icon(Icons.tag_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Verify Authenticity',
                      icon: Icons.verified_user_rounded,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) {
                        return ActionChip(
                          label: Text(id,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.primary)),
                          backgroundColor: AppColors.primaryDim,
                          onPressed: () {
                            _idCtrl.text = id;
                            _verify();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trust Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _trustItem(Icons.verified_rounded, 'Tamper Proof'),
                  _trustItem(Icons.lock_outline_rounded, 'HMAC-SHA256'),
                  _trustItem(Icons.link_rounded, 'Public Ledger'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.low, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Tab 2: My Orders ──────────────────────────────────────────────────────
class _MyOrdersTab extends StatelessWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Purchased Products & Orders'),
        const SizedBox(height: 14),
        ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.customer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: AppColors.customer, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Serial: ${p.id} · Batch: ${p.batchNumber}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.low.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              PulseDot(color: AppColors.low, size: 6),
                              SizedBox(width: 6),
                              Text(
                                'AUTHENTIC',
                                style: TextStyle(
                                  color: AppColors.low,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'From: ${p.manufacturerName} (${p.factoryLocation})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.timeline_rounded, size: 14),
                          label: const Text('Track Journey',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: () => context.push('/verify/${p.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
