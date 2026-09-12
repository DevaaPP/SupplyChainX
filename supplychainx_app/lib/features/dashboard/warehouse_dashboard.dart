import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
import '../product/providers/products_provider.dart';
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
class _WarehouseStatsRow extends ConsumerWidget {
  const _WarehouseStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final total = products.length;
    final intaked = products.where((p) => p.journey.any((j) => j.role.toLowerCase() == 'warehouse')).length;
    final inTransit = products.where((p) => !p.journey.any((j) => j.role.toLowerCase() == 'warehouse')).length;
    final dispatched = products.where((p) => p.journey.any((j) => j.role.toLowerCase() == 'retailer' || j.role.toLowerCase() == 'customer')).length;

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
          children: [
            StatCard(
              label: 'Warehouse Stock',
              value: '$intaked consignments',
              color: AppColors.textPrimary,
              subtitle: '$total total registered',
            ),
            StatCard(
              label: 'Expected Intake',
              value: '$inTransit in-transit',
              color: AppColors.primary,
              subtitle: inTransit > 0 ? 'Awaiting receiving bay' : 'All arrivals cleared',
            ),
            StatCard(
              label: 'Dispatched to Retail',
              value: '$dispatched units',
              color: AppColors.success,
              subtitle: 'Transferred outbound',
            ),
            StatCard(
              label: 'Facility Health',
              value: total > 0 ? 'Optimal' : 'Standby',
              color: AppColors.low,
              subtitle: 'RFID & cold-chain nominal',
            ),
          ],
        );
      }),
    );
  }
}

// ─── Tab 1: Inventory Control ───────────────────────────────────────────────
class _InventoryControlTab extends ConsumerStatefulWidget {
  const _InventoryControlTab();

  @override
  ConsumerState<_InventoryControlTab> createState() => _InventoryControlTabState();
}

class _InventoryControlTabState extends ConsumerState<_InventoryControlTab> {
  final Map<String, int> _customStockCounts = {};

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
                    'assets/images/smart_warehouse.jpg',
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
                              'AUTOMATED FACILITY #04',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textOnPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kolkata Central Distribution Hub',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Robotic Inventory & Inbound Intake Floor',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${products.length} Active Consignments · Real-time Optical Dimension & Barcode Verifications',
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _WarehouseStatsRow(),
        const SizedBox(height: 16),

        // ML Risk Alert Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: products.isNotEmpty ? AppColors.infoLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: products.isNotEmpty ? AppColors.infoBorder : AppColors.successBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  products.isNotEmpty ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  color: products.isNotEmpty ? AppColors.info : AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        products.isNotEmpty
                            ? 'Logistics ML Forecast: Corridors Monitored'
                            : 'Logistics ML Forecast: All Routes Clear',
                        style: GoogleFonts.inter(
                          color: products.isNotEmpty ? AppColors.info : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        products.isNotEmpty
                            ? 'Siliguri-Kolkata corridor NH-27 normal. Buffer inventory active for ${products.first.name} (${products.first.batchNumber}).'
                            : 'Zero transit disruptions detected across national transport corridors. Ready for inbound receipts.',
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

        // Inventory Table or Empty State
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
                        child: const Icon(Icons.warehouse_outlined, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Consignments in Warehouse',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This facility currently has no stored inventory. Registered consignments will appear here once dispatched from manufacturers or provisioned via showcase.',
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
                            _th('CONSIGNMENT / SKU', flex: 3),
                            _th('LOCATION', flex: 2),
                            _th('ON-HAND', flex: 2, alignRight: true),
                            _th('STATUS', flex: 2),
                            _th('ACTION', flex: 1, alignRight: true),
                          ],
                        ),
                      ),
                      ...products.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        final stock = _customStockCounts[p.id] ?? 100;
                        final isLast = idx == products.length - 1;
                        final isIntaked = p.journey.any((j) => j.role.toLowerCase() == 'warehouse');

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
                                    Text(p.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text('${p.id} · ${p.batchNumber}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Aisle ${(idx % 4) + 1}, Bay ${10 + idx}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '$stock units',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
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
                                    severity: isIntaked ? 'HEALTHY' : 'IN TRANSIT',
                                    small: true,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () => _editCount(p, stock),
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

  void _editCount(ProductModel product, int currentStock) {
    final ctrl = TextEditingController(text: currentStock.toString());
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
            Text('${product.name} (${product.id})', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
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
              if (v != null) setState(() => _customStockCounts[product.id] = v);
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
class _InboundIntakeTab extends ConsumerStatefulWidget {
  const _InboundIntakeTab();

  @override
  ConsumerState<_InboundIntakeTab> createState() => _InboundIntakeTabState();
}

class _InboundIntakeTabState extends ConsumerState<_InboundIntakeTab> {
  final Set<String> _intaked = {};

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyStateView(
            title: 'No Pending Inbound Consignments',
            message: 'All incoming freight deliveries have been cleared or are awaiting dispatch from upstream suppliers.',
            icon: Icons.move_to_inbox_outlined,
          ),
        ),
      );
    }

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
                final isDone = _intaked.contains(p.id) || p.journey.any((j) => j.role.toLowerCase() == 'warehouse');
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    onPressed: () {
                                      setState(() => _intaked.add(p.id));
                                      ref.read(productsProvider.notifier).updateLocation(
                                        productId: p.id,
                                        location: 'Kolkata Central Warehouse (Bay 4)',
                                        action: 'Inbound Intake & Quality Inspection Completed',
                                        actorName: 'Kolkata Central Warehouse',
                                        notes: 'Passed automated temperature and seal audit',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Intake logged for ${p.id}. Updated on tracking ledger!')),
                                      );
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
class _RetailDispatchTab extends ConsumerStatefulWidget {
  const _RetailDispatchTab();

  @override
  ConsumerState<_RetailDispatchTab> createState() => _RetailDispatchTabState();
}

class _RetailDispatchTabState extends ConsumerState<_RetailDispatchTab> {
  String? _selectedProductId;
  final _destCtrl = TextEditingController(text: 'Metro Retailers - Store #08');
  bool _isLoading = false;

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final products = ref.read(productsProvider);
    final targetId = _selectedProductId ?? products.firstOrNull?.id;
    if (targetId == null) return;

    setState(() => _isLoading = true);
    await ref.read(productsProvider.notifier).transferProduct(
      productId: targetId,
      recipientName: _destCtrl.text.trim(),
      recipientRole: 'retailer',
      location: 'Kolkata Central Warehouse Outbound Bay',
      action: 'Dispatched to Retailer Store',
      notes: 'Outbound carrier transit release authorized',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dispatched $targetId to ${_destCtrl.text}. Live on Tracking!')),
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
            title: 'No Inventory Available to Dispatch',
            message: 'Receive or intake consignments first before authorizing retail floor movements.',
            icon: Icons.outbox_rounded,
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
                    items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.id})'))).toList(),
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
class _WarehouseHistoryTab extends ConsumerWidget {
  const _WarehouseHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final logs = <(String, String, String, Color)>[];

    for (final p in products) {
      for (final j in p.journey) {
        final role = j.role.toLowerCase();
        if (role == 'warehouse' || role == 'distributor' || role == 'retailer') {
          logs.add((
            j.action.isNotEmpty ? j.action : 'Checkpoint Logged',
            '${p.name} (${p.id}) · ${j.location}${j.notes != null && j.notes!.isNotEmpty ? ' · ' + j.notes! : ''}',
            j.timestamp,
            role == 'warehouse' ? AppColors.success : AppColors.primary,
          ));
        }
      }
    }

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyStateView(
            title: 'No Inspection Logs Recorded',
            message: 'Intake and dispatch checkpoints will be logged here in real-time as consignments move through the facility.',
            icon: Icons.fact_check_outlined,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final log = logs[i];
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
