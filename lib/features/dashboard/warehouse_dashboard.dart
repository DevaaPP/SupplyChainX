import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../product/domain/product_model.dart';
import 'dashboard_shell.dart';

class WarehouseDashboard extends ConsumerStatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  ConsumerState<WarehouseDashboard> createState() =>
      _WarehouseDashboardState();
}

class _WarehouseDashboardState extends ConsumerState<WarehouseDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Warehouse Dashboard',
      tabs: const [
        DashboardTab(
          icon: Icons.move_to_inbox_outlined,
          activeIcon: Icons.move_to_inbox_rounded,
          label: 'Incoming',
        ),
        DashboardTab(
          icon: Icons.inventory_outlined,
          activeIcon: Icons.inventory_rounded,
          label: 'Inventory',
        ),
        DashboardTab(
          icon: Icons.swap_horiz_outlined,
          activeIcon: Icons.swap_horiz_rounded,
          label: 'Transfer',
        ),
        DashboardTab(
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          label: 'History',
        ),
      ],
      pages: const [
        _IncomingProductsTab(),
        _UpdateInventoryTab(),
        _TransferProductTab(),
        _WarehouseHistoryTab(),
      ],
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────
class _WarehouseStatsRow extends StatelessWidget {
  const _WarehouseStatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'In Stock',
              value: '24',
              icon: Icons.warehouse_rounded,
              color: AppColors.warehouse,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Incoming',
              value: '7',
              icon: Icons.local_shipping_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Low Stock',
              value: '2',
              icon: Icons.warning_amber_rounded,
              color: AppColors.critical,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Incoming Products ──────────────────────────────────────────────
class _IncomingProductsTab extends StatefulWidget {
  const _IncomingProductsTab();

  @override
  State<_IncomingProductsTab> createState() => _IncomingProductsTabState();
}

class _IncomingProductsTabState extends State<_IncomingProductsTab> {
  final Set<String> _received = {};

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _WarehouseStatsRow(),
        const SizedBox(height: 20),

        // ML Prediction Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            color: AppColors.medium.withOpacity(0.1),
            borderColor: AppColors.medium.withOpacity(0.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.medium.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph_rounded,
                      color: AppColors.medium, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'AI Logistics Risk Alert',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.medium.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ML PREDICTION',
                              style: TextStyle(
                                color: AppColors.medium,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Delay Risk: Medium (67% probability of 2-day delay on Siliguri route due to regional monsoon congestion).',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Expected Incoming Shipments'),
        ),
        const SizedBox(height: 12),
        ...products.map((p) {
          final isDone = _received.contains(p.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.warehouse.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.move_to_inbox_rounded,
                        color: AppColors.warehouse, size: 22),
                  ),
                  const SizedBox(width: 14),
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
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${p.id} · Batch: ${p.batchNumber}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          'From: ${p.factoryLocation}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.low.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Received ✓',
                          style: TextStyle(
                              color: AppColors.low,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warehouse,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() => _received.add(p.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${p.name} marked as received into warehouse stock.'),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        );
                      },
                      child: const Text('Receive',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
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

// ─── Tab 2: Inventory ──────────────────────────────────────────────────────
class _UpdateInventoryTab extends StatefulWidget {
  const _UpdateInventoryTab();

  @override
  State<_UpdateInventoryTab> createState() => _UpdateInventoryTabState();
}

class _UpdateInventoryTabState extends State<_UpdateInventoryTab> {
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Organic Rice 5kg', 'sku': 'SKU-RC01', 'stock': 120, 'min': 50, 'unit': 'bags'},
    {'name': 'Darjeeling Tea 250g', 'sku': 'SKU-TEA02', 'stock': 15, 'min': 40, 'unit': 'packs'},
    {'name': 'Mango Pickle 500ml', 'sku': 'SKU-PKL03', 'stock': 85, 'min': 30, 'unit': 'jars'},
    {'name': 'Cold Pressed Mustard Oil', 'sku': 'SKU-OIL04', 'stock': 10, 'min': 25, 'unit': 'bottles'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _WarehouseStatsRow(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Current Warehouse Inventory'),
        ),
        const SizedBox(height: 12),
        ..._inventory.map((item) {
          final isLow = (item['stock'] as int) < (item['min'] as int);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              borderColor: isLow ? AppColors.critical.withOpacity(0.3) : null,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLow
                          ? AppColors.critical.withOpacity(0.15)
                          : AppColors.warehouse.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLow ? Icons.warning_rounded : Icons.inventory_2_rounded,
                      color: isLow ? AppColors.critical : AppColors.warehouse,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['sku']} · Min: ${item['min']} ${item['unit']}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['stock']} ${item['unit']}',
                        style: TextStyle(
                          color: isLow ? AppColors.critical : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isLow)
                        const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            color: AppColors.critical,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded,
                        color: AppColors.primary),
                    onPressed: () {
                      _showEditStockDialog(item);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showEditStockDialog(Map<String, dynamic> item) {
    final ctrl = TextEditingController(text: item['stock'].toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Update Stock: ${item['name']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'New Stock Count',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null) {
                setState(() => item['stock'] = val);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Transfer ───────────────────────────────────────────────────────
class _TransferProductTab extends StatefulWidget {
  const _TransferProductTab();

  @override
  State<_TransferProductTab> createState() => _TransferProductTabState();
}

class _TransferProductTabState extends State<_TransferProductTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _recipientCtrl = TextEditingController(text: 'ABC Retail Store - Guwahati');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispatched $_selectedProductId to ${_recipientCtrl.text} successfully.'),
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
          const _WarehouseStatsRow(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispatch Product to Retailer',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Product from Inventory',
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
                    label: 'Destination Retailer',
                    controller: _recipientCtrl,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Confirm Dispatch on Chain',
                    icon: Icons.local_shipping_rounded,
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

// ─── Tab 4: History ───────────────────────────────────────────────────────
class _WarehouseHistoryTab extends StatelessWidget {
  const _WarehouseHistoryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _WarehouseStatsRow(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Warehouse Log'),
        ),
        const SizedBox(height: 12),
        ...[
          ('Dispatched: 50 units Organic Rice 5kg', 'Today, 10:15 AM', Icons.outbox_rounded, AppColors.warehouse),
          ('Received: 100 units Darjeeling Tea 250g', 'Yesterday, 3:45 PM', Icons.move_to_inbox_rounded, AppColors.low),
          ('Stock Check completed by Inspector', 'Aug 20, 2026', Icons.fact_check_rounded, AppColors.primary),
        ].map((h) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: h.$4.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(h.$3, color: h.$4, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.$1,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            h.$2,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
