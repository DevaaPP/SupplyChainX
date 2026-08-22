import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
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
      title: 'Warehouse Control',
      tabs: const [
        DashboardTab(
          icon: Icons.warehouse_outlined,
          activeIcon: Icons.warehouse_rounded,
          label: 'Inventory Control',
        ),
        DashboardTab(
          icon: Icons.move_to_inbox_outlined,
          activeIcon: Icons.move_to_inbox_rounded,
          label: 'Inbound Intake',
        ),
        DashboardTab(
          icon: Icons.outbox_rounded,
          activeIcon: Icons.outbox_rounded,
          label: 'Retail Dispatch',
        ),
        DashboardTab(
          icon: Icons.fact_check_outlined,
          activeIcon: Icons.fact_check_rounded,
          label: 'Inspection Logs',
        ),
      ],
      pages: const [
        _InventoryControlTab(),
        _InboundIntakeTab(),
        _RetailDispatchTab(),
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
              label: 'Stock Capacity',
              value: '72.4%',
              color: AppColors.textPrimary,
              subtitle: '1,420 / 2,000 bins',
            ),
            StatCard(
              label: 'Expected Intake',
              value: '7 batches',
              color: AppColors.primary,
              subtitle: 'Next arrival: 14:15 IST',
            ),
            StatCard(
              label: 'Stock Thresholds',
              value: '2 Low',
              color: AppColors.warning,
              subtitle: 'Tea & Mustard Oil below min',
            ),
            StatCard(
              label: 'Turnover Cycle',
              value: '6.4 days',
              color: AppColors.success,
              subtitle: '↑ 0.6d vs target',
            ),
          ],
        );
      }),
    );
  }
}

// ─── Tab 1: Inventory Control ───────────────────────────────────────────────
class _InventoryControlTab extends StatefulWidget {
  const _InventoryControlTab();

  @override
  State<_InventoryControlTab> createState() => _InventoryControlTabState();
}

class _InventoryControlTabState extends State<_InventoryControlTab> {
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Organic Rice 5kg', 'sku': 'SKU-RC01', 'stock': 120, 'min': 50, 'unit': 'bags', 'loc': 'Aisle 3, Bin 12'},
    {'name': 'Darjeeling Tea 250g', 'sku': 'SKU-TEA02', 'stock': 15, 'min': 40, 'unit': 'packs', 'loc': 'Aisle 1, Bin 04'},
    {'name': 'Mango Pickle 500ml', 'sku': 'SKU-PKL03', 'stock': 85, 'min': 30, 'unit': 'jars', 'loc': 'Aisle 4, Bin 09'},
    {'name': 'Cold Pressed Mustard Oil 1L', 'sku': 'SKU-OIL04', 'stock': 10, 'min': 25, 'unit': 'bottles', 'loc': 'Aisle 2, Bin 18'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _WarehouseStatsRow(),
        const SizedBox(height: 16),

        // ML Risk Alert Box (Clean, restrained)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logistics ML Forecast: Medium Inbound Delay Risk on Route NH-27',
                        style: GoogleFonts.inter(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siliguri weather disruption estimated to delay batch BAT-2026-X102 by ~18 hours. Prepare buffer stock at Hub 4.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Inventory Table
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      _th('SKU / ITEM', flex: 3),
                      _th('LOCATION', flex: 2),
                      _th('ON-HAND', flex: 2, alignRight: true),
                      _th('STATUS', flex: 2),
                      _th('ACTION', flex: 1, alignRight: true),
                    ],
                  ),
                ),
                ..._inventory.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isLow = (item['stock'] as int) < (item['min'] as int);
                  final isLast = idx == _inventory.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] as String, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text('${item['sku']} · Min: ${item['min']}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(item['loc'] as String, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item['stock']} ${item['unit']}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              color: isLow ? AppColors.danger : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: SeverityBadge(
                              severity: isLow ? 'LOW STOCK' : 'HEALTHY',
                              small: true,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _editCount(item),
                              child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                            ),
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

  void _editCount(Map<String, dynamic> item) {
    final ctrl = TextEditingController(text: item['stock'].toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Adjust Stock Count', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item['name']} (${item['sku']})', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Verified Quantity',
              controller: ctrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null) setState(() => item['stock'] = v);
              Navigator.pop(context);
            },
            child: const Text('Save Count'),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Tab 2: Inbound Intake ──────────────────────────────────────────────────
class _InboundIntakeTab extends StatefulWidget {
  const _InboundIntakeTab();

  @override
  State<_InboundIntakeTab> createState() => _InboundIntakeTabState();
}

class _InboundIntakeTabState extends State<_InboundIntakeTab> {
  final Set<String> _intaked = {};

  @override
  Widget build(BuildContext context) {
    final products = ProductModel.mockProducts();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
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
                    Expanded(flex: 3, child: Text('CONSIGNMENT', style: _thStyle())),
                    Expanded(flex: 2, child: Text('ORIGIN', style: _thStyle())),
                    Expanded(flex: 2, child: Text('INTAKE ACTION', textAlign: TextAlign.right, style: _thStyle())),
                  ],
                ),
              ),
              ...products.map((p) {
                final isDone = _intaked.contains(p.id);
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
                        child: Text(p.factoryLocation, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: isDone
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(4)),
                                  child: Text('INTAKED ✓', style: GoogleFonts.inter(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                                )
                              : SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                    onPressed: () {
                                      setState(() => _intaked.add(p.id));
                                    },
                                    child: const Text('Confirm Intake', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _thStyle() => GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}

// ─── Tab 3: Retail Dispatch ─────────────────────────────────────────────────
class _RetailDispatchTab extends StatefulWidget {
  const _RetailDispatchTab();

  @override
  State<_RetailDispatchTab> createState() => _RetailDispatchTabState();
}

class _RetailDispatchTabState extends State<_RetailDispatchTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _destCtrl = TextEditingController(text: 'Metro Retailers - Store #08');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dispatched $_selectedProductId to ${_destCtrl.text}.')),
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
                Text('Dispatch Consignment to Retail', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Authorize stock movement to retail partner point-of-sale inventory.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                Text('Select Stock Unit', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                  label: 'Destination Retailer Outlet',
                  controller: _destCtrl,
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  label: 'Confirm Dispatch on Ledger',
                  icon: Icons.local_shipping_outlined,
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

// ─── Tab 4: Inspection Logs ─────────────────────────────────────────────────
class _WarehouseHistoryTab extends StatelessWidget {
  const _WarehouseHistoryTab();

  static const _logs = [
    ('Intake Completed', 'Batch BAT-2026-X102 received at Bay 4', '14 min ago', AppColors.success),
    ('Dispatched to Retail', '50 bags Rice dispatched to Metro Store #08', '1h ago', AppColors.primary),
    ('Audit Inspection Passed', 'Temperature compliance: 18.2°C (nominal)', '4h ago', AppColors.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final log = _logs[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SeverityBadge(severity: log.$1, small: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(log.$2, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              Text(log.$3, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
