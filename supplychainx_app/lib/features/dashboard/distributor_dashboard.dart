import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
import '../product/providers/products_provider.dart';
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
class _DistributorStatsRow extends ConsumerWidget {
  const _DistributorStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final inTransit = products.where((p) => p.currentOwnerRole == 'distributor').length;
    final totalHub = products.where((p) => p.journey.any((j) => j.role.toLowerCase() == 'distributor')).length;
    final exceptions = products.where((p) => !p.isAuthentic).length;

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
              label: 'In Transit',
              value: '$inTransit',
              color: AppColors.primary,
              subtitle: inTransit == 0 ? 'No active dispatches' : '$inTransit units en route',
            ),
            StatCard(
              label: 'Delivered to Hub',
              value: '$totalHub',
              color: AppColors.success,
              subtitle: totalHub == 0 ? 'Awaiting intake' : '$totalHub received at terminal',
            ),
            StatCard(
              label: 'Route Exceptions',
              value: '$exceptions',
              color: exceptions > 0 ? AppColors.danger : AppColors.textMuted,
              subtitle: exceptions == 0 ? 'Clear weather routes' : 'Disruption flagged',
            ),
            StatCard(
              label: 'Fleet Status',
              value: products.isEmpty ? 'Ready' : 'Active',
              color: AppColors.textPrimary,
              subtitle: products.isEmpty ? 'Fleet in depot' : 'Fleet deployed',
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
    final products = ref.watch(productsProvider);
    final receivedSet = ref.watch(_distReceivedSetProvider);

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
                    'assets/images/logistics_fleet.jpg',
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
                              'INTERSTATE ARTERIAL FLEET',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textOnPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Northeast Transit Corridor NH-27',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Siliguri Logistics Freight Operations',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live GPS Waypoint Broadcasting · Route Congestion & Weather Dynamic Bypass',
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _DistributorStatsRow(),
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
                    Text(
                      'Live Transit Inventory',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${products.length} Units on Ledger',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
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
                      _th('CONSIGNMENT', flex: 2),
                      _th('ORIGIN / NODE', flex: 2),
                      _th('PROGRESS', flex: 2),
                      _th('ACTION', flex: 1, alignRight: true),
                    ],
                  ),
                ),
                // Rows or Empty State
                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No Dispatches in Transit',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Awaiting consignment handovers from manufacturing facilities.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                ...products.map((p) {
                  final isReceived = receivedSet.contains(p.id) || p.journey.any((j) => j.role.toLowerCase() == 'distributor');
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
                          child: Text(p.journey.lastOrNull?.location ?? p.factoryLocation, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isReceived ? AppColors.success : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isReceived ? 'In Transit' : 'Pickup Pending',
                                style: GoogleFonts.inter(
                                  color: isReceived ? AppColors.success : AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isReceived
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
                                        foregroundColor: AppColors.textOnPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () {
                                        ref.read(_distReceivedSetProvider.notifier).update((s) => {...s, p.id});
                                        ref.read(productsProvider.notifier).updateLocation(
                                          productId: p.id,
                                          location: 'Siliguri Logistics Hub (NH-27)',
                                          action: 'Consignment Accepted & Loaded on Carrier',
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Accepted pickup for ${p.id}. Updated on tracking ledger!')),
                                        );
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
class _TransferProductTab extends ConsumerStatefulWidget {
  const _TransferProductTab();

  @override
  ConsumerState<_TransferProductTab> createState() => _TransferProductTabState();
}

class _TransferProductTabState extends ConsumerState<_TransferProductTab> {
  String? _selectedProductId;
  final _destCtrl = TextEditingController(text: 'Central Warehouse - Hub 4');
  String _destRole = 'Warehouse';
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
      recipientRole: _destRole.toLowerCase(),
      location: 'Eastern Regional Corridor (Transit Point)',
      action: 'Dispatched to $_destRole',
      notes: 'Terminal handoff signed by Carrier',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Handoff confirmed for $targetId to $_destRole. Live on Tracking!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    if (_selectedProductId == null && products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }

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
                    items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.id})'))).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Destination Name / Hub Facility',
                  controller: _destCtrl,
                ),
                const SizedBox(height: 14),

                Text('Target Role in Chain', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: ['Warehouse', 'Retailer'].map((r) {
                    final isSel = _destRole == r;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: r == 'Warehouse' ? 8 : 0),
                        child: InkWell(
                          onTap: () => setState(() => _destRole = r),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary.withAlpha(40) : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                            ),
                            child: Text(
                              r,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
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
class _UpdateLocationTab extends ConsumerStatefulWidget {
  const _UpdateLocationTab();

  @override
  ConsumerState<_UpdateLocationTab> createState() => _UpdateLocationTabState();
}

class _UpdateLocationTabState extends ConsumerState<_UpdateLocationTab> {
  String? _selectedProductId;
  final _locCtrl = TextEditingController(text: 'Siliguri Checkpoint 2 (NH-27)');
  final _gpsCtrl = TextEditingController(text: '26.7271° N, 88.3953° E');
  bool _isLoading = false;

  @override
  void dispose() {
    _locCtrl.dispose();
    _gpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final products = ref.read(productsProvider);
    final targetId = _selectedProductId ?? products.firstOrNull?.id;
    if (targetId == null) return;

    setState(() => _isLoading = true);
    await ref.read(productsProvider.notifier).updateLocation(
      productId: targetId,
      location: '${_locCtrl.text.trim()} [${_gpsCtrl.text.trim()}]',
      action: 'Transit Waypoint GPS Broadcasted',
      notes: 'Real-time telemetry updated by distributor carrier',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('GPS ping broadcasted for $targetId! Updated in live tracking.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    if (_selectedProductId == null && products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }

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
                    items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.id})'))).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
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
