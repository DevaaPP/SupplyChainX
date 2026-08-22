import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../product/domain/product_model.dart';
import '../../core/audit/audit_event.dart';
import '../../core/rbac/roles.dart';
import 'dashboard_shell.dart';

class ManufacturerDashboard extends ConsumerStatefulWidget {
  const ManufacturerDashboard({super.key});

  @override
  ConsumerState<ManufacturerDashboard> createState() =>
      _ManufacturerDashboardState();
}

class _ManufacturerDashboardState
    extends ConsumerState<ManufacturerDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Manufacturer Dashboard',
      tabs: const [
        DashboardTab(
          icon: Icons.add_box_outlined,
          activeIcon: Icons.add_box_rounded,
          label: 'Register',
        ),
        DashboardTab(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'My Products',
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
        _RegisterProductTab(),
        _MyProductsTab(),
        _TransferProductTab(),
        _ManufacturerHistoryTab(),
      ],
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────
class _ManufacturerStatsRow extends StatelessWidget {
  const _ManufacturerStatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Products',
              value: '12',
              icon: Icons.inventory_2_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Verified',
              value: '9',
              icon: Icons.verified_rounded,
              color: AppColors.low,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'In Transit',
              value: '3',
              icon: Icons.local_shipping_rounded,
              color: AppColors.medium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Register Product ───────────────────────────────────────────────
class _RegisterProductTab extends ConsumerStatefulWidget {
  const _RegisterProductTab();

  @override
  ConsumerState<_RegisterProductTab> createState() =>
      _RegisterProductTabState();
}

class _RegisterProductTabState extends ConsumerState<_RegisterProductTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Guwahati Factory Plant 1');
  final _descCtrl = TextEditingController();
  String _category = 'Food & Agriculture';
  bool _isLoading = false;
  String _productId = 'SCX-${(10000 + (const Uuid().v4().hashCode.abs() % 89999)).toString()}';

  static const _categories = [
    'Food & Agriculture',
    'Beverages',
    'Electronics',
    'Textiles',
    'Pharmaceuticals',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _productId = 'SCX-${(10000 + (const Uuid().v4().hashCode.abs() % 89999)).toString()}';
    });
    _nameCtrl.clear();
    _batchCtrl.clear();
    _descCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.low, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Product registered successfully! QR code generated and recorded on blockchain.',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            const _ManufacturerStatsRow(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_box_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register New Product',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Product ID display
                    AppTextField(
                      label: 'Product ID (Auto-Generated)',
                      controller: TextEditingController(text: _productId),
                      readOnly: true,
                      prefixIcon: const Icon(Icons.qr_code_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Product Name',
                      hint: 'e.g. Organic Black Tea 500g',
                      controller: _nameCtrl,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Batch Number',
                            hint: 'e.g. B-2026-X01',
                            controller: _batchCtrl,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _category,
                                  dropdownColor: AppColors.surfaceElevated,
                                  underline: const SizedBox(),
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13),
                                  items: _categories
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _category = v!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Factory Location',
                      hint: 'e.g. Guwahati Manufacturing Plant',
                      controller: _locationCtrl,
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 18),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Description',
                      hint: 'Product details, specifications, etc.',
                      controller: _descCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Register Product & Generate QR',
                      icon: Icons.qr_code_2_rounded,
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

// ─── Tab 2: My Products ───────────────────────────────────────────────────
class _MyProductsTab extends ConsumerStatefulWidget {
  const _MyProductsTab();

  @override
  ConsumerState<_MyProductsTab> createState() => _MyProductsTabState();
}

class _MyProductsTabState extends ConsumerState<_MyProductsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allProducts = ProductModel.mockProducts();
    final filtered = allProducts
        .where((p) =>
            p.name.toLowerCase().contains(_search.toLowerCase()) ||
            p.id.toLowerCase().contains(_search.toLowerCase()) ||
            p.batchNumber.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _ManufacturerStatsRow(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search,
                            color: AppColors.textMuted, size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search products by name, ID, batch...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...filtered.map((p) {
          final progress = p.journey.length / 5.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              onTap: () => context.push('/product/${p.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.id,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RoleBadge(role: p.currentOwnerRole, small: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Batch: ${p.batchNumber}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text('Current: ${p.currentOwner}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.surfaceElevated,
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${p.journey.length}/5 Stages',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
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

// ─── Tab 3: Transfer Product ───────────────────────────────────────────────
class _TransferProductTab extends ConsumerStatefulWidget {
  const _TransferProductTab();

  @override
  ConsumerState<_TransferProductTab> createState() =>
      _TransferProductTabState();
}

class _TransferProductTabState extends ConsumerState<_TransferProductTab> {
  final _products = ProductModel.mockProducts();
  late String _selectedProductId;
  final _transferToCtrl = TextEditingController(text: 'Fast Distributors Hub');
  String _selectedRole = 'Distributor';
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.low, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Product $_selectedProductId transferred to $_selectedRole successfully!',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            const _ManufacturerStatsRow(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer Product Ownership',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                      child: Text(
                                          '${p.name} (${p.id})',
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
                      label: 'Transfer To (Recipient Name / Center)',
                      controller: _transferToCtrl,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recipient Role',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Distributor', 'Warehouse', 'Retailer']
                              .map((role) {
                            final selected = _selectedRole == role;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedRole = role),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryDim
                                          : AppColors.surfaceElevated,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
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
                      label: 'Notes (Optional)',
                      hint: 'Special handling instructions...',
                      controller: _notesCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Execute Transfer on Chain',
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

// ─── Tab 4: History ───────────────────────────────────────────────────────
class _ManufacturerHistoryTab extends StatelessWidget {
  const _ManufacturerHistoryTab();

  @override
  Widget build(BuildContext context) {
    final events = AuditEvent.mockEvents()
        .where((e) =>
            e.userRole == UserRole.manufacturer ||
            e.type == AuditEventType.productRegistered ||
            e.type == AuditEventType.qrGenerated)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _ManufacturerStatsRow(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'Manufacturer Audit Logs'),
        ),
        const SizedBox(height: 12),
        ...events.map((e) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.type.label,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SeverityBadge(
                                  severity: e.severity.name, small: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(e.description,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '${e.userEmail} · ${_formatTime(e.timestamp)}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
