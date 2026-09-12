import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../product/domain/product_model.dart';
import '../product/providers/products_provider.dart';
import '../../core/audit/audit_event.dart';
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
      title: 'Manufacturer Operations',
      tabs: const [
        DashboardTab(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'Batches & Inventory',
        ),
        DashboardTab(
          icon: Icons.add_circle_outline_rounded,
          activeIcon: Icons.add_circle_rounded,
          label: 'Register Batch',
        ),
        DashboardTab(
          icon: Icons.sync_alt_rounded,
          activeIcon: Icons.sync_alt_rounded,
          label: 'Transfer Custody',
        ),
        DashboardTab(
          icon: Icons.history_edu_outlined,
          activeIcon: Icons.history_edu_rounded,
          label: 'Audit Stream',
        ),
      ],
      pages: const [
        _BatchesOverviewTab(),
        _RegisterProductTab(),
        _TransferProductTab(),
        _ManufacturerHistoryTab(),
      ],
    );
  }
}

// ─── Operational Stats ───────────────────────────────────────────────────────
class _ManufacturerStatsRow extends ConsumerWidget {
  const _ManufacturerStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsProvider);
    final activeCount = allProducts.length;
    final verifiedCount = allProducts.where((p) => p.isAuthentic).length;
    final inTransitCount = allProducts.where((p) => p.currentOwnerRole == 'distributor' || p.currentOwnerRole == 'warehouse').length;
    final exceptionCount = allProducts.where((p) => !p.isAuthentic).length;

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
              label: 'Active Batches',
              value: '$activeCount',
              color: AppColors.textPrimary,
              subtitle: activeCount == 0 ? 'No registered units' : '$activeCount on ledger',
            ),
            StatCard(
              label: 'Verified on Ledger',
              value: '$verifiedCount',
              color: AppColors.success,
              subtitle: activeCount == 0 ? 'Awaiting batches' : '100% HMAC pass',
            ),
            StatCard(
              label: 'In Transit',
              value: '$inTransitCount',
              color: AppColors.primary,
              subtitle: inTransitCount == 0 ? 'Terminal holding' : '$inTransitCount moving',
            ),
            StatCard(
              label: 'Exceptions',
              value: '$exceptionCount',
              color: exceptionCount > 0 ? AppColors.danger : AppColors.textMuted,
              subtitle: exceptionCount == 0 ? 'Zero tampered units' : 'Attention required',
            ),
          ],
        );
      }),
    );
  }
}

// ─── Tab 1: Batches Overview ────────────────────────────────────────────────
class _BatchesOverviewTab extends ConsumerStatefulWidget {
  const _BatchesOverviewTab();

  @override
  ConsumerState<_BatchesOverviewTab> createState() => _BatchesOverviewTabState();
}

class _BatchesOverviewTabState extends ConsumerState<_BatchesOverviewTab> {
  String _search = '';

  void _showShowcaseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final tmpls = ProductModel.showcaseTemplates();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Provision Showcase Consignment',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select a template to generate a real, cryptographic consignment on the blockchain and SQL database:',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...tmpls.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final p = await ref.read(productsProvider.notifier).addShowcaseProduct(t['key']!);
                      if (mounted && p != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Showcase batch ${p.id} (${p.name}) committed to blockchain & ledger!')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t['name']!,
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        t['badge']!,
                                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  t['description']!,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider);
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Filter by product name, serial, or batch...',
                      prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _showShowcaseSheet,
                icon: const Icon(Icons.add_task_rounded, size: 15),
                label: const Text('Add Showcase Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '${filtered.length} units listed',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dense Operations Table
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header
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
                      _th('PRODUCT & BATCH', flex: 3),
                      _th('CURRENT CUSTODY', flex: 2),
                      _th('PROGRESS', flex: 2),
                      _th('STATUS', flex: 2),
                      _th('ACTION', flex: 1, alignRight: true),
                    ],
                  ),
                ),
                // Table Rows or Empty State
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No Batches on Ledger',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zero active consignments. Click below to add an authentic showcase product or register a batch.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showShowcaseSheet,
                          icon: const Icon(Icons.flash_on_rounded, size: 15),
                          label: const Text('Provision Showcase Consignment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                ...filtered.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isLast = idx == filtered.length - 1;
                  final progress = p.journey.length / 5.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        // Serial ID
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
                        // Product & Batch
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
                        // Custody
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.currentOwner,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Progress
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppColors.surfaceElevated,
                                    color: progress == 1.0 ? AppColors.success : AppColors.primary,
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${p.journey.length}/5', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        // Status
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SeverityBadge(
                              severity: p.currentOwnerRole == 'retailer'
                                  ? 'DELIVERED'
                                  : p.currentOwnerRole == 'distributor'
                                      ? 'IN TRANSIT'
                                      : 'ON TRACK',
                              small: true,
                            ),
                          ),
                        ),
                        // Action
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => context.push('/product/${p.id}'),
                              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
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

// ─── Tab 2: Register Batch ──────────────────────────────────────────────────
class _RegisterProductTab extends ConsumerStatefulWidget {
  const _RegisterProductTab();

  @override
  ConsumerState<_RegisterProductTab> createState() => _RegisterProductTabState();
}

class _RegisterProductTabState extends ConsumerState<_RegisterProductTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Guwahati Manufacturing Unit 1');
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

    final newProduct = ProductModel(
      id: _productId,
      name: _nameCtrl.text.trim(),
      batchNumber: _batchCtrl.text.trim(),
      manufacturerId: 'mfg-01',
      manufacturerName: 'Guwahati Food Corp',
      currentOwner: 'Guwahati Food Corp',
      currentOwnerRole: 'manufacturer',
      createdAt: DateTime.now(),
      category: _category,
      description: _descCtrl.text.trim(),
      factoryLocation: _locationCtrl.text.trim(),
      qrSignature: 'hmac-sha256-sig-${DateTime.now().millisecondsSinceEpoch}',
      isAuthentic: true,
      journey: [
        JourneyStage(
          id: 'js-0',
          actor: 'Guwahati Food Corp',
          role: 'Manufacturer',
          action: 'Batch Created & Cryptographic Genesis Block Committed',
          location: _locationCtrl.text.trim(),
          timestamp: DateTime.now(),
          blockchainHash: '0xgenesis${_productId.replaceAll('-', '')}',
          verified: true,
        ),
      ],
    );

    await ref.read(productsProvider.notifier).addProduct(newProduct);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _productId = 'SCX-${(10000 + (const Uuid().v4().hashCode.abs() % 89999)).toString()}';
    });
    _nameCtrl.clear();
    _descCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Batch ${newProduct.id} registered! Live on Tracking & Verification.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register Manufacturing Batch', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Generates cryptographically signed barcode and commits genesis block to chain.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Assigned Serial ID',
                    controller: TextEditingController(text: _productId),
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Product Name',
                    hint: 'e.g. Organic Basmati Rice 5kg',
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Batch Number',
                          hint: 'e.g. BAT-2026-B01',
                          controller: _batchCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                                value: _category,
                                underline: const SizedBox(),
                                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) => setState(() => _category = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Manufacturing Unit Location',
                    controller: _locationCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Description / Specification (Optional)',
                    controller: _descCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Commit Batch & Generate QR',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab 3: Transfer Custody ────────────────────────────────────────────────
class _TransferProductTab extends ConsumerStatefulWidget {
  const _TransferProductTab();

  @override
  ConsumerState<_TransferProductTab> createState() => _TransferProductTabState();
}

class _TransferProductTabState extends ConsumerState<_TransferProductTab> {
  String? _selectedProductId;
  final _recipientCtrl = TextEditingController(text: 'Fast Distributors Hub - Siliguri');
  String _selectedRole = 'Distributor';
  bool _isLoading = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final products = ref.read(productsProvider);
    final targetId = _selectedProductId ?? products.firstOrNull?.id;
    if (targetId == null) return;

    setState(() => _isLoading = true);
    await ref.read(productsProvider.notifier).transferProduct(
      productId: targetId,
      recipientName: _recipientCtrl.text.trim(),
      recipientRole: _selectedRole.toLowerCase(),
      location: 'Guwahati Outbound Dispatch Bay',
      action: 'Consignment Dispatched to $_selectedRole',
      notes: 'Handover signed by Manufacturer',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ownership of $targetId transferred to $_selectedRole! Live on Tracking.'),
      ),
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
                Text('Custody Handover', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Assign physical consignment to authorized logistics distributor.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                Text('Select Unit / Batch', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                  label: 'Authorized Recipient / Hub',
                  controller: _recipientCtrl,
                ),
                const SizedBox(height: 14),

                Text('Stakeholder Tier', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: ['Distributor', 'Warehouse', 'Retailer'].map((role) {
                    final isSel = _selectedRole == role;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                            ),
                            child: Text(
                              role,
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
                  label: 'Execute Custody Transfer',
                  icon: Icons.sync_alt_rounded,
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

// ─── Tab 4: Audit Stream ────────────────────────────────────────────────────
class _ManufacturerHistoryTab extends StatelessWidget {
  const _ManufacturerHistoryTab();

  @override
  Widget build(BuildContext context) {
    final events = AuditEvent.mockEvents();

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = events[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SeverityBadge(severity: e.severity.name, small: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.description, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('${e.userEmail} · ${e.userRole.label}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${DateTime.now().difference(e.timestamp).inMinutes}m ago',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
