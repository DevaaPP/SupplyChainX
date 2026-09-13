import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
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
class _RetailerStatsRow extends ConsumerWidget {
  const _RetailerStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final total = products.length;
    final sold = products.where((p) => p.journey.any((j) => j.role.toLowerCase() == 'customer')).length;
    final onShelf = products.where((p) => !p.journey.any((j) => j.role.toLowerCase() == 'customer')).length;

    final horizontalPad = context.isMobile ? 14.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 14, horizontalPad, 0),
      child: ResponsiveKpiGrid(
        children: [
          StatCard(
            label: 'Stock on Shelves',
            value: '$onShelf units',
            color: AppColors.textPrimary,
            subtitle: onShelf > 0 ? 'Ready for customer POS' : 'Awaiting warehouse restock',
          ),
          StatCard(
            label: 'Customer Sales',
            value: '$sold sold',
            color: AppColors.success,
            subtitle: 'Transferred to buyers',
          ),
          StatCard(
            label: 'Cryptographic SLA',
            value: total > 0 ? '100%' : 'N/A',
            color: AppColors.primary,
            subtitle: 'Zero counterfeit risk',
          ),
          StatCard(
            label: 'Total Consignments',
            value: '$total tracked',
            color: AppColors.low,
            subtitle: 'Live supply chain',
          ),
        ],
      ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/delivery_pickup.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xF20F172A),
                          Color(0xAA0F172A),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'POINT OF SALE & INTAKE',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textOnPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Metro Supermarkets Store #04',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Retail Floor & Customer Verification Terminal',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instant Inbound Crate Verification · Digital Proof of Purchase Generation',
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _RetailerStatsRow(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: products.isEmpty
              ? GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Stock in Retail Inventory',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Store shelves are currently awaiting warehouse arrivals. Consignments will appear here once transferred from the warehouse or provisioned via showcase.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/dashboard/manufacturer'),
                          icon: const Icon(Icons.add_box_outlined, size: 16),
                          label: const Text('Provision Consignment in Manufacturer Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : GlassCard(
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

                      // Responsive Layout: Cards on Mobile, Table on Tablet/Desktop
                      if (context.screenWidth < 720)
                        Column(
                          children: products.map((p) {
                            final isSold = _sold.contains(p.id) ||
                                p.journey.any((j) => j.role.toLowerCase() == 'customer') ||
                                p.currentOwnerRole.toLowerCase() == 'customer' ||
                                p.currentStage >= 5;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p.id,
                                          style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isSold ? AppColors.surface : AppColors.successLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isSold ? 'SOLD AT POS' : 'IN STOCK',
                                            style: GoogleFonts.inter(
                                              color: isSold ? AppColors.textMuted : AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(p.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('Batch: ${p.batchNumber} · Facility: ${p.factoryLocation}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'View QR',
                                          icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primary),
                                          onPressed: () => showProductQrDialog(context, p),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          height: 28,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                            onPressed: () => context.push('/verify/${p.id}'),
                                            child: const Text('Verify', style: TextStyle(fontSize: 11)),
                                          ),
                                        ),
                                        if (!isSold) ...[
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 28,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: AppColors.textOnPrimary,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 12),
                                              label: const Text('Scan QR to Sell', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                              onPressed: () => context.push('/qr/scan?target=${p.id}&action=retailer_sold'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        // Table Header & Rows for Tablet/Desktop
                        Column(
                          children: [
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
                            ...products.map((p) {
                              final isSold = _sold.contains(p.id) ||
                                  p.journey.any((j) => j.role.toLowerCase() == 'customer') ||
                                  p.currentOwnerRole.toLowerCase() == 'customer' ||
                                  p.currentStage >= 5;
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
                                          if (!isSold) ...[
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              height: 28,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: AppColors.textOnPrimary,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 12),
                                                label: const Text('Scan QR to Sell', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                onPressed: () => context.push('/qr/scan?target=${p.id}&action=retailer_sold'),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
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
  final _buyerCtrl = TextEditingController(text: 'Customer POS Buyer');
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
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyStateView(
            title: 'No Units Available for POS Checkout',
            message: 'Receive inventory from the warehouse or provision showcase consignments before processing customer checkouts.',
            icon: Icons.point_of_sale_outlined,
          ),
        ),
      );
    }
    if (_selectedProductId == null || !products.any((p) => p.id == _selectedProductId)) {
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
                  label: 'Scan Unit Barcode to Authorize Sale',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () {
                    final targetId = _selectedProductId ?? products.firstOrNull?.id ?? 'SCX-00001';
                    context.push('/qr/scan?target=$targetId&action=retailer_sold');
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text(_isLoading ? 'Signing Block...' : 'Manual Override: Sign Sale Block'),
                    onPressed: _isLoading ? null : _submit,
                  ),
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
