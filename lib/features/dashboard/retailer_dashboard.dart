import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/providers/auth_provider.dart';
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
      title: 'Retailer Dashboard',
      tabs: const [
        DashboardTab(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: 'Received',
        ),
        DashboardTab(
          icon: Icons.timeline_outlined,
          activeIcon: Icons.timeline_rounded,
          label: 'Journey',
        ),
        DashboardTab(
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          label: 'Sell Product',
        ),
      ],
      pages: const [
        _ReceivedProductsTab(),
        _ProductJourneyTab(),
        _MarkAsSoldTab(),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Received',
              value: '5',
              icon: Icons.inventory_rounded,
              color: AppColors.retailer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Verified',
              value: '3',
              icon: Icons.verified_user_rounded,
              color: AppColors.low,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Sold',
              value: '2',
              icon: Icons.check_circle_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Received Products ──────────────────────────────────────────────
class _ReceivedProductsTab extends StatefulWidget {
  const _ReceivedProductsTab();

  @override
  State<_ReceivedProductsTab> createState() => _ReceivedProductsTabState();
}

class _ReceivedProductsTabState extends State<_ReceivedProductsTab> {
  final Set<String> _sold = {};

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _RetailerStatsRow(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Inventory at Retail Store'),
        ),
        const SizedBox(height: 12),
        ...products.map((p) {
          final isSold = _sold.contains(p.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.retailer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.retailer, size: 20),
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
                              'ID: ${p.id} · Batch: ${p.batchNumber}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.low.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SOLD ✓',
                            style: TextStyle(
                              color: AppColors.low,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.retailer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'IN STOCK',
                            style: TextStyle(
                              color: AppColors.retailer,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 16),
                          label: const Text('Verify QR',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => context.push('/verify/${p.id}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!isSold)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.point_of_sale_rounded,
                                size: 16),
                            label: const Text('Mark Sold',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.low,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() => _sold.add(p.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${p.name} marked as sold to customer.'),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Tab 2: Journey ────────────────────────────────────────────────────────
class _ProductJourneyTab extends StatelessWidget {
  const _ProductJourneyTab();

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();
    final p = products.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.low, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Track: ${p.name} (${p.id})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...p.journey.map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDim,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.check,
                                color: AppColors.primary, size: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${j.role}: ${j.action}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${j.location} · ${j.actor}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Hash: ${j.blockchainHash}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Mark as Sold ───────────────────────────────────────────────────
class _MarkAsSoldTab extends StatefulWidget {
  const _MarkAsSoldTab();

  @override
  State<_MarkAsSoldTab> createState() => _MarkAsSoldTabState();
}

class _MarkAsSoldTabState extends State<_MarkAsSoldTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _priceCtrl = TextEditingController(text: '450.00');
  final _buyerCtrl = TextEditingController(text: 'Vikram Mehta');
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
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Sale completed! Blockchain record updated for $_selectedProductId.'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RetailerStatsRow(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Point of Sale — Transfer to Customer',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Item',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedProductId,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      items: _products
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} (${p.id})'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedProductId = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Sale Price (INR)',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Buyer Name (Optional)',
                    controller: _buyerCtrl,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Record Sale on Blockchain',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
