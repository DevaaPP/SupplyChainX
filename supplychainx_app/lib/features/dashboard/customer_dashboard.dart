import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/providers/products_provider.dart';
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
      title: 'Consumer Verification Portal',
      tabs: const [
        DashboardTab(
          icon: Icons.qr_code_scanner_outlined,
          activeIcon: Icons.qr_code_scanner_rounded,
          label: 'Verify Authenticity',
        ),
        DashboardTab(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Purchased Units',
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
class _VerifyProductTab extends ConsumerStatefulWidget {
  const _VerifyProductTab();

  @override
  ConsumerState<_VerifyProductTab> createState() => _VerifyProductTabState();
}

class _VerifyProductTabState extends ConsumerState<_VerifyProductTab> {
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
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
                          child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Origin & Authenticity Check',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Cryptographic verification against manufacturer ledger',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Launch Camera Barcode Scanner',
                      icon: Icons.qr_code_scanner_rounded,
                      onPressed: () => context.push('/qr/scan'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/qr/scan'),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Scan or Upload Packaging QR Pass', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Manual text entry disabled. Authenticity verification requires scanning the encrypted physical QR barcode on packaging.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Registered On-Chain Consignments',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any genuine consignment to view its immutable cryptographic audit report:',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),

                    if (products.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'No consignments on ledger yet. Register or provision items in Manufacturer hub.',
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                        ),
                      )
                    else
                      Column(
                        children: products.take(4).map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'ID: ${p.id} · Batch: ${p.batchNumber}',
                                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.verified_outlined, size: 13),
                                  label: const Text('Verify Pass', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primaryBorder),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => context.push('/verify/${p.id}'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: My Orders ──────────────────────────────────────────────────────
class _MyOrdersTab extends ConsumerWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsProvider);
    // Show orders that have reached consumer/retailer or all tracked products
    final products = allProducts;

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No Consumer Consignments Yet',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'When shipments are dispatched across the network, your tracked deliveries will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = products[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('ID: ${p.id} · Batch: ${p.batchNumber}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SeverityBadge(severity: 'VERIFIED', small: true),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 30),
                ),
                onPressed: () => context.push('/verify/${p.id}'),
                child: const Text('Inspect Journey', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}
