import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../product/domain/product_model.dart';
import 'dashboard_shell.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _distReceivedSetProvider = StateProvider<Set<String>>((ref) => {});

// ─── Main Widget ──────────────────────────────────────────────────────────────

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
      title: 'Distributor Dashboard',
      tabs: const [
        DashboardTab(
          icon: Icons.inbox_outlined,
          activeIcon: Icons.inbox_rounded,
          label: 'Received',
        ),
        DashboardTab(
          icon: Icons.swap_horiz_outlined,
          activeIcon: Icons.swap_horiz_rounded,
          label: 'Transfer',
        ),
        DashboardTab(
          icon: Icons.location_on_outlined,
          activeIcon: Icons.location_on_rounded,
          label: 'Location',
        ),
        DashboardTab(
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          label: 'History',
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

// ─── Top Stats Row ────────────────────────────────────────────────────────────

class _DistributorStatsRow extends StatelessWidget {
  const _DistributorStatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Received',
              value: '8',
              icon: Icons.inbox_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Transferred',
              value: '5',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Pending',
              value: '3',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Received Products ─────────────────────────────────────────────────

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
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Incoming Shipments'),
        ),
        const SizedBox(height: 12),
        ...products.map((p) {
          final isReceived = receivedSet.contains(p.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              color: isReceived ? AppColors.success.withOpacity(0.08) : null,
              borderColor:
                  isReceived ? AppColors.success.withOpacity(0.35) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.distributor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.distributor, size: 22),
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
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Batch: ${p.batchNumber}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text('From: ${p.manufacturerName}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        if (isReceived)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: AppColors.success, size: 14),
                                SizedBox(width: 5),
                                Text('Received',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Accept',
                                  style: TextStyle(fontSize: 13)),
                              onPressed: () {
                                ref
                                    .read(_distReceivedSetProvider.notifier)
                                    .update((s) => {...s, p.id});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                side: BorderSide(
                                    color: AppColors.primary.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                      ],
                    ),
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

// ─── Tab 2: Transfer Product ──────────────────────────────────────────────────

class _TransferProductTab extends ConsumerStatefulWidget {
  const _TransferProductTab();

  @override
  ConsumerState<_TransferProductTab> createState() =>
      _TransferProductTabState();
}

class _TransferProductTabState extends ConsumerState<_TransferProductTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _transferToCtrl = TextEditingController();
  String _selectedRole = 'Warehouse';
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _transferToCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isLoading = false);
    if (!mounted) return;
    _transferToCtrl.clear();
    _notesCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Product transferred to $_selectedRole successfully!',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DistributorStatsRow(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer Product',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    // Product selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Product',
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
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
                                      child: Text(
                                          '${p.name} — ${p.batchNumber}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProductId = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Transfer To',
                      hint: 'Enter recipient name or ID',
                      controller: _transferToCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Role selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transfer To Role',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Warehouse', 'Retailer'].map((role) {
                            final selected = _selectedRole == role;
                            final color = role == 'Warehouse'
                                ? AppColors.warehouse
                                : AppColors.retailer;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedRole = role),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? color.withOpacity(0.15)
                                          : AppColors.surfaceElevated,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: selected
                                              ? color.withOpacity(0.5)
                                              : AppColors.cardBorder),
                                    ),
                                    child: Text(
                                      role,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selected
                                            ? color
                                            : AppColors.textSecondary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Notes (optional)',
                      hint: 'Add transfer notes...',
                      controller: _notesCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Transfer Product',
                      icon: Icons.swap_horiz_rounded,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Update Location ───────────────────────────────────────────────────

class _UpdateLocationTab extends ConsumerStatefulWidget {
  const _UpdateLocationTab();

  @override
  ConsumerState<_UpdateLocationTab> createState() => _UpdateLocationTabState();
}

class _UpdateLocationTabState extends ConsumerState<_UpdateLocationTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _locationCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedProductId = _products.first.id;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _success = false;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoading = false;
      _success = true;
    });
    _locationCtrl.clear();
    _latCtrl.clear();
    _lngCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DistributorStatsRow(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Product Location',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Product',
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
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
                                      child: Text(
                                          '${p.name} — ${p.batchNumber}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProductId = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'New Location',
                      hint: 'e.g. Delhi Distribution Hub',
                      controller: _locationCtrl,
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 18),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GPS Coordinates (optional)',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Latitude',
                            hint: '28.6139',
                            controller: _latCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Longitude',
                            hint: '77.2090',
                            controller: _lngCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_success)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          color: AppColors.success.withOpacity(0.08),
                          borderColor: AppColors.success.withOpacity(0.35),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success, size: 18),
                              SizedBox(width: 10),
                              Text('Location updated successfully!',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    PrimaryButton(
                      label: 'Update Location',
                      icon: Icons.location_on_rounded,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 4: View History ──────────────────────────────────────────────────────

class _ViewHistoryTab extends StatelessWidget {
  const _ViewHistoryTab();

  static const _mockHistory = [
    (
      action: 'Accepted Shipment',
      product: 'Organic Rice 5kg',
      time: '2 hours ago',
      location: 'Guwahati Hub',
      icon: Icons.inbox_rounded,
      color: AppColors.primary,
    ),
    (
      action: 'Transferred to Warehouse',
      product: 'Darjeeling Tea 250g',
      time: '5 hours ago',
      location: 'Kolkata Warehouse-4',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.success,
    ),
    (
      action: 'Location Updated',
      product: 'Mango Pickle 500ml',
      time: 'Yesterday, 3:42 PM',
      location: 'Delhi Distribution Hub',
      icon: Icons.location_on_rounded,
      color: AppColors.secondary,
    ),
    (
      action: 'Transferred to Retailer',
      product: 'Organic Rice 5kg',
      time: 'Yesterday, 11:10 AM',
      location: 'South City Mall',
      icon: Icons.storefront_outlined,
      color: AppColors.retailer,
    ),
    (
      action: 'Accepted Shipment',
      product: 'Mango Pickle 500ml',
      time: '2 days ago',
      location: 'Siliguri Distribution Center',
      icon: Icons.inbox_rounded,
      color: AppColors.primary,
    ),
    (
      action: 'Location Updated',
      product: 'Darjeeling Tea 250g',
      time: '3 days ago',
      location: 'Patna Logistics Center',
      icon: Icons.location_on_rounded,
      color: AppColors.secondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _DistributorStatsRow(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Activity Timeline'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(_mockHistory.length, (i) {
              final item = _mockHistory[i];
              final isLast = i == _mockHistory.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: item.color.withOpacity(0.5)),
                            ),
                            child:
                                Icon(item.icon, color: item.color, size: 14),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.cardBorder,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.action,
                                style: TextStyle(
                                    color: item.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(item.product,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(item.location,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                  const Spacer(),
                                  Text(item.time,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
