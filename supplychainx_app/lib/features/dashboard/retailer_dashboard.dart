import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
import '../product/providers/products_provider.dart';
import 'dashboard_shell.dart';

class RetailerDashboard extends ConsumerStatefulWidget {
  const RetailerDashboard({super.key});

  @override
  ConsumerState<RetailerDashboard> createState() =>
      _RetailerDashboardState();
}

class _RetailerDashboardState extends ConsumerState<RetailerDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Retail Operations & POS',
      tabs: const [
        DashboardTab(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: 'Store Stock',
        ),
        DashboardTab(
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          label: 'Point of Sale',
        ),
        DashboardTab(
          icon: Icons.qr_code_scanner_rounded,
          activeIcon: Icons.qr_code_scanner_rounded,
          label: 'Verify Intake',
        ),
      ],
      pages: const [
        _StoreStockTab(),
        _PointOfSaleTab(),
        _VerifyIntakeTab(),
      ],
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────
class _RetailerStatsRow extends StatelessWidget {
  const _RetailerStatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        return GridView.count(
          crossAxisCount: isCompact ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isCompact ? 1.9 : 2.2,
          children: const [
            StatCard(
              label: 'Stock on Shelves',
              value: '148 units',
              color: AppColors.textPrimary,
              subtitle: '4 categories active',
            ),
            StatCard(
              label: 'Today\'s Sales',
              value: '₹ 14,280',
              color: AppColors.success,
              subtitle: '18 verified receipts',
            ),
            StatCard(
              label: 'QR Verified Rate',
              value: '100%',
              color: AppColors.primary,
              subtitle: 'No counterfeit flags',
            ),
            StatCard(
              label: 'Restock Inbound',
              value: '3 crates',
              color: AppColors.textMuted,
              subtitle: 'ETA 16:30 IST',
            ),
          ],
        );
      }),
    );
  }
}

// ─── Tab 1: Store Stock ─────────────────────────────────────────────────────
class _StoreStockTab extends ConsumerStatefulWidget {
  const _StoreStockTab();

  @override
  ConsumerState<_StoreStockTab> createState() => _StoreStockTabState();
}

class _StoreStockTabState extends ConsumerState<_StoreStockTab> {
  final Set<String> _sold = {};

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _RetailerStatsRow(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('On-Shelf Retail Inventory', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${products.length} Units Tracked', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 8),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('CONSIGNMENT', style: _thStyle())),
                      Expanded(flex: 2, child: Text('BATCH / ORIGIN', style: _thStyle())),
                      Expanded(flex: 2, child: Text('SHELF STATUS', style: _thStyle())),
                      Expanded(flex: 2, child: Text('ACTIONS', style: _thStyle(), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),

                // Rows
                ...products.map((p) {
                  final isSold = _sold.contains(p.id) || p.journey.any((j) => j.role.toLowerCase() == 'customer');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(p.id, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.batchNumber, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                              Text(p.factoryLocation, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSold ? AppColors.surfaceElevated : AppColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSold ? 'SOLD AT POS' : 'IN STOCK (AISLE 4)',
                              style: GoogleFonts.inter(
                                color: isSold ? AppColors.textMuted : AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 28,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  onPressed: () => context.push('/verify/${p.id}'),
                                  child: const Text('Verify', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (!isSold)
                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () {
                                      setState(() => _sold.add(p.id));
                                      ref.read(productsProvider.notifier).markAsSold(
                                        productId: p.id,
                                        storeName: 'Metro Retail Store #4',
                                        buyerName: 'Store POS Buyer',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Checkout recorded for ${p.id}. Live on tracking ledger!')),
                                      );
                                    },
                                    child: const Text('Checkout', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _thStyle() => GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}

// ─── Tab 2: Point of Sale ───────────────────────────────────────────────────
class _PointOfSaleTab extends ConsumerStatefulWidget {
  const _PointOfSaleTab();

  @override
  ConsumerState<_PointOfSaleTab> createState() => _PointOfSaleTabState();
}

class _PointOfSaleTabState extends ConsumerState<_PointOfSaleTab> {
  String? _selectedProductId;
  final _priceCtrl = TextEditingController(text: '450.00');
  final _buyerCtrl = TextEditingController(text: 'Vikram Mehta (Cust #9821)');
  bool _isLoading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _buyerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final products = ref.read(productsProvider);
    final targetId = _selectedProductId ?? products.firstOrNull?.id;
    if (targetId == null) return;

    setState(() => _isLoading = true);
    await ref.read(productsProvider.notifier).markAsSold(
      productId: targetId,
      storeName: 'Metro Retail Store #4 (POS Terminal 1)',
      buyerName: _buyerCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale completed for unit $targetId. Proof of sale committed to chain!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    if (_selectedProductId == null && products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Point of Sale & Proof of Purchase', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Transfers unit custody from Retail Inventory to Consumer upon transaction completion.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                Text('Select Scanned Unit', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedProductId,
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.id})'))).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Sale Price (INR)',
                  controller: _priceCtrl,
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Customer / Buyer Reference',
                  controller: _buyerCtrl,
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  label: 'Complete Sale & Sign Block',
                  icon: Icons.receipt_long_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab 3: Verify Intake ───────────────────────────────────────────────────
class _VerifyIntakeTab extends StatelessWidget {
  const _VerifyIntakeTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text('Inbound Receiving Verification', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Scan the cryptographic HMAC barcode on inbound crates from warehouse delivery to verify anti-tampering seal before accepting stock.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Launch Barcode Scanner',
                icon: Icons.camera_alt_outlined,
                onPressed: () => context.push('/qr/scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
