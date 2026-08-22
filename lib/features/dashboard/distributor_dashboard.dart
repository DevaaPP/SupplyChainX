import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
import 'dashboard_shell.dart';

final _distReceivedSetProvider = StateProvider<Set<String>>((ref) => {});

class DistributorDashboard extends ConsumerStatefulWidget {
  const DistributorDashboard({super.key});

  @override
  ConsumerState<DistributorDashboard> createState() =>
      _DistributorDashboardState();
}

class _DistributorDashboardState extends ConsumerState<DistributorDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Distributor Logistics',
      tabs: const [
        DashboardTab(
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping_rounded,
          label: 'Transit Manifest',
        ),
        DashboardTab(
          icon: Icons.sync_alt_rounded,
          activeIcon: Icons.sync_alt_rounded,
          label: 'Transfer Handoff',
        ),
        DashboardTab(
          icon: Icons.add_location_alt_outlined,
          activeIcon: Icons.add_location_alt_rounded,
          label: 'GPS & Location',
        ),
        DashboardTab(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Route Activity',
        ),
      ],
      pages: const [
        _ReceivedProductsTab(),
        _TransferProductTab(),
        _UpdateLocationTab(),
        _ViewHistoryTab(),
      ],
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────
class _DistributorStatsRow extends StatelessWidget {
  const _DistributorStatsRow();

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
              label: 'In Transit',
              value: '8',
              color: AppColors.primary,
              subtitle: '2 arriving today',
            ),
            StatCard(
              label: 'Delivered to Hub',
              value: '5',
              color: AppColors.success,
              subtitle: 'Avg transit: 2.1 days',
            ),
            StatCard(
              label: 'Route Exceptions',
              value: '1',
              color: AppColors.warning,
              subtitle: 'Siliguri heavy rain',
            ),
            StatCard(
              label: 'Fleet Utilization',
              value: '87.4%',
              color: AppColors.textPrimary,
              subtitle: '6 active trucks',
            ),
          ],
        );
      }),
    );
  }
}

// ─── Tab 1: Transit Manifest ────────────────────────────────────────────────
class _ReceivedProductsTab extends ConsumerWidget {
  const _ReceivedProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ProductModel.mockProducts();
    final receivedSet = ref.watch(_distReceivedSetProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _DistributorStatsRow(),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      _th('SERIAL ID', flex: 2),
                      _th('CONSIGNMENT', flex: 3),
                      _th('ORIGIN / FACTORY', flex: 2),
                      _th('STATUS', flex: 2),
                      _th('ACTION', flex: 2, alignRight: true),
                    ],
                  ),
                ),
                ...products.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isDone = receivedSet.contains(p.id);
                  final isLast = idx == products.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.id,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                            alignment: Alignment.centerLeft,
                            child: SeverityBadge(
                              severity: isDone ? 'RECEIVED' : 'IN TRANSIT',
                              small: true,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isDone
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('ACCEPTED ✓', style: GoogleFonts.inter(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                                  )
                                : SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () {
                                        ref.read(_distReceivedSetProvider.notifier).update((s) => {...s, p.id});
                                      },
                                      child: const Text('Accept Pickup', style: TextStyle(fontSize: 11)),
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
        ),
      ],
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

// ─── Tab 2: Transfer Handoff ────────────────────────────────────────────────
class _TransferProductTab extends StatefulWidget {
  const _TransferProductTab();

  @override
  State<_TransferProductTab> createState() => _TransferProductTabState();
}

class _TransferProductTabState extends State<_TransferProductTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _destCtrl = TextEditingController(text: 'Central Warehouse - Hub 4');
  String _destRole = 'Warehouse';
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
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Handoff confirmed for $_selectedProductId to $_destRole.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Logistics Handoff Confirmation', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Record terminal delivery to destination warehouse or distribution node.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                Text('Consignment Serial ID', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                    items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} — ${p.id}'))).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v!),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Destination Receiving Facility',
                  controller: _destCtrl,
                ),
                const SizedBox(height: 14),

                Text('Recipient Facility Tier', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: ['Warehouse', 'Retailer'].map((r) {
                    final isSel = _destRole == r;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _destRole = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                            ),
                            child: Text(
                              r,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: isSel ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  label: 'Confirm Handoff on Chain',
                  icon: Icons.check_circle_outline,
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

// ─── Tab 3: GPS & Location ──────────────────────────────────────────────────
class _UpdateLocationTab extends StatefulWidget {
  const _UpdateLocationTab();

  @override
  State<_UpdateLocationTab> createState() => _UpdateLocationTabState();
}

class _UpdateLocationTabState extends State<_UpdateLocationTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _locCtrl = TextEditingController(text: 'Siliguri Checkpoint 2 (NH-27)');
  final _gpsCtrl = TextEditingController(text: '26.7271° N, 88.3953° E');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    _gpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS ping and waypoint broadcasted to ledger.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Broadcast Waypoint Location', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Updates live transit status for customer and warehouse tracking telemetry.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                Text('Active Consignment', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                  label: 'Checkpoint / Node Description',
                  controller: _locCtrl,
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'GPS Coordinates',
                  controller: _gpsCtrl,
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  label: 'Broadcast Transit Waypoint',
                  icon: Icons.broadcast_on_personal_rounded,
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

// ─── Tab 4: Route Activity ──────────────────────────────────────────────────
class _ViewHistoryTab extends StatelessWidget {
  const _ViewHistoryTab();

  static const _history = [
    ('Waypoint Logged', 'Siliguri Checkpoint 2 (NH-27)', 'SCX-00098', '8 min ago', AppColors.primary),
    ('Handoff Completed', 'Central Warehouse Kolkata', 'SCX-00112', '2h ago', AppColors.success),
    ('Pickup Confirmed', 'Guwahati Manufacturing Plant', 'SCX-00134', '5h ago', AppColors.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _history[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SeverityBadge(severity: item.$1, small: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('Unit: ${item.$3}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(item.$4, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
