import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
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
class _StoreStockTab extends StatefulWidget {
  const _StoreStockTab();

  @override
  State<_StoreStockTab> createState() => _StoreStockTabState();
}

class _StoreStockTabState extends State<_StoreStockTab> {
  final Set<String> _sold = {};

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _RetailerStatsRow(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('SERIAL ID', style: _thStyle())),
                      Expanded(flex: 3, child: Text('ITEM NAME', style: _thStyle())),
                      Expanded(flex: 2, child: Text('STATUS', style: _thStyle())),
                      Expanded(flex: 3, child: Text('ACTIONS', textAlign: TextAlign.right, style: _thStyle())),
                    ],
                  ),
                ),
                ...products.map((p) {
                  final isSold = _sold.contains(p.id);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(p.id, style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text('Batch: ${p.batchNumber}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SeverityBadge(
                              severity: isSold ? 'SOLD' : 'AVAILABLE',
                              small: true,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
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
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () {
                                      setState(() => _sold.add(p.id));
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
class _PointOfSaleTab extends StatefulWidget {
  const _PointOfSaleTab();

  @override
  State<_PointOfSaleTab> createState() => _PointOfSaleTabState();
}

class _PointOfSaleTabState extends State<_PointOfSaleTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _priceCtrl = TextEditingController(text: '450.00');
  final _buyerCtrl = TextEditingController(text: 'Vikram Mehta (Cust #9821)');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _buyerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale completed for unit $_selectedProductId. Proof of sale committed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.id})'))).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v!),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Checkout Total (INR)',
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Customer Account / Identifier',
                  controller: _buyerCtrl,
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  label: 'Process Checkout & Update Ledger',
                  icon: Icons.receipt_rounded,
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
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColors.navy),
                const SizedBox(height: 14),
                Text('Intake Barcode Scanner', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Scan incoming delivery crates to cryptographically verify HMAC seals before accepting stock.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Trigger Camera Scanner',
                  icon: Icons.camera_alt_outlined,
                  onPressed: () => context.push('/qr/scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
