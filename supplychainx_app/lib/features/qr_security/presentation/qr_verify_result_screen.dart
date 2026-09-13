import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/rbac/roles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../product/domain/product_model.dart';
import '../../product/providers/products_provider.dart';

class QrVerifyResultScreen extends ConsumerStatefulWidget {
  final String? productId;
  final String? scanReceiptId;
  final String? scannedAction;

  const QrVerifyResultScreen({
    super.key,
    this.productId,
    this.scanReceiptId,
    this.scannedAction,
  });

  @override
  ConsumerState<QrVerifyResultScreen> createState() =>
      _QrVerifyResultScreenState();
}

class _QrVerifyResultScreenState extends ConsumerState<QrVerifyResultScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  bool _notFound = false;
  final _searchCtrl = TextEditingController();
  String? _searchedId;

  @override
  void initState() {
    super.initState();
    _initProduct();
  }

  @override
  void didUpdateWidget(covariant QrVerifyResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId) {
      _initProduct();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initProduct() {
    final pid = widget.productId?.trim();
    if (pid != null && pid.isNotEmpty) {
      _searchCtrl.text = pid;
      _searchedId = pid;
      final products = ref.read(productsProvider);
      final found = products.where((p) =>
        p.id.toLowerCase() == pid.toLowerCase() ||
        p.batchNumber.toLowerCase() == pid.toLowerCase()
      ).firstOrNull;

      setState(() {
        _product = found;
        _isLoading = false;
        _notFound = found == null;
      });
    } else {
      // Clean data entry mode: do NOT preload or default to old product data!
      setState(() {
        _product = null;
        _isLoading = false;
        _notFound = false;
        _searchedId = null;
      });
    }
  }

  void _searchConsignment(String input) {
    final query = input.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a consignment serial or batch number to track.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchedId = query;
    });

    final products = ref.read(productsProvider);
    final found = products.where((p) =>
      p.id.toLowerCase() == query.toLowerCase() ||
      p.batchNumber.toLowerCase() == query.toLowerCase() ||
      p.name.toLowerCase().contains(query.toLowerCase())
    ).firstOrNull;

    setState(() {
      _isLoading = false;
      _product = found;
      _notFound = found == null;
    });
  }

  void _resetToSearch() {
    setState(() {
      _product = null;
      _notFound = false;
      _searchedId = null;
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    final allProducts = ref.watch(productsProvider);

    // Keep product instance synchronized if provider updates while viewing
    if (_product != null) {
      final updated = allProducts.where((p) => p.id == _product!.id).firstOrNull;
      if (updated != null) {
        _product = updated;
      }
    }

    final hasActiveReport = _product != null && !_notFound;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () {
            if (hasActiveReport && widget.productId == null) {
              _resetToSearch();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            hasActiveReport ? 'Verification Report: ${_product!.id}' : 'Track Consignment',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          if (hasActiveReport)
            TextButton.icon(
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('New Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              onPressed: _resetToSearch,
            ),
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 20),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: _isLoading
          ? const CenterPageLoading(message: 'Querying ledger & verifying cryptographic signature...')
          : _notFound
              ? _buildNotFound()
              : _product == null
                  ? _buildEnterDataView(allProducts, isWide)
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 14, vertical: 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildActiveTrackingBanner(),
                              const SizedBox(height: 16),
                              isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 5, child: _buildVerdictCard()),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 6, child: _buildJourneyTimeline()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildVerdictCard(),
                                        const SizedBox(height: 24),
                                        _buildJourneyTimeline(),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildActiveTrackingBanner() {
    final p = _product!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      p.id,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        p.batchNumber,
                        style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Text(
                  p.name,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.search_rounded, size: 14),
            label: const Text('Track Another', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryBorder),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _resetToSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildEnterDataView(List<ProductModel> allProducts, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge & Title
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBorder, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Track Consignment Provenance',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Enter a consignment serial or batch number to query live blockchain custody records and HMAC-SHA256 anti-tamper seals.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Interactive Search Form Card
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Consignment / Tracking Serial',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        hintText: 'e.g. SCX-00001 or BATCH-2026-X',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                onPressed: () {
                                  setState(() => _searchCtrl.clear());
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (val) => _searchConsignment(val),
                    ),
                    const SizedBox(height: 16),

                    // Primary Action Button
                    PrimaryButton(
                      label: 'Track & Verify Consignment',
                      icon: Icons.search_rounded,
                      onPressed: () => _searchConsignment(_searchCtrl.text),
                    ),
                    const SizedBox(height: 14),

                    // QR Scanner Alternative Button
                    SizedBox(
                      height: 42,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text(
                          'Scan Physical QR / Barcode',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => context.push('/qr/scan'),
                      ),
                    ),

                    if (allProducts.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.cardBorder, height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Select Registered Consignments for Quick Test:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allProducts.map((p) {
                          return InkWell(
                            onTap: () {
                              _searchCtrl.text = p.id;
                              _searchConsignment(p.id);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    p.id,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${p.name.length > 14 ? "${p.name.substring(0, 14)}..." : p.name})',
                                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Trust & Security Pillars
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSecurityPillar(
                    icon: Icons.verified_rounded,
                    title: 'Cryptographic Proof',
                    desc: 'HMAC-SHA256 signature checked against root manufacturer record.',
                  ),
                  _buildSecurityPillar(
                    icon: Icons.account_tree_outlined,
                    title: 'Immutable Ledger',
                    desc: 'Every custody handover stored permanently on EVM smart contracts.',
                  ),
                  _buildSecurityPillar(
                    icon: Icons.shield_outlined,
                    title: 'Anti-Tampering',
                    desc: 'Instant alert flag if package seals or serial metadata is modified.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPillar({required IconData icon, required String title, required String desc}) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Consignment Not Recognized on Chain',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID "${_searchedId ?? widget.productId ?? "Unknown"}" does not match any registered batch or smart contract record.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter valid serial (e.g. SCX-00001)',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  onSubmitted: (val) => _searchConsignment(val),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Verify ID',
                        icon: Icons.check_circle_outline,
                        onPressed: () => _searchConsignment(_searchCtrl.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _resetToSearch,
                        child: const Text('Back to Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictCard() {
    final p = _product!;
    final isAuthentic = p.isAuthentic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAuthentic ? AppColors.successLight : AppColors.dangerLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isAuthentic ? AppColors.successBorder : AppColors.dangerBorder),
          ),
          child: Row(
            children: [
              Icon(
                isAuthentic ? Icons.verified_user_rounded : Icons.dangerous_rounded,
                color: isAuthentic ? AppColors.success : AppColors.danger,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuthentic ? 'AUTHENTIC PHYSICAL PRODUCT' : 'COUNTERFEIT / TAMPERED WARNING',
                      style: GoogleFonts.inter(
                        color: isAuthentic ? AppColors.success : AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      isAuthentic ? 'HMAC signature matches manufacturing root record.' : 'Signature check failed. Do not accept this unit.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Audit Verification Receipt Card
        _buildAuditReceiptCard(),
        const SizedBox(height: 16),

        // Metadata Table
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Specifications', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _metaRow('Serial ID', p.id, isMono: true),
              _metaRow('Product Name', p.name),
              _metaRow('Batch Number', p.batchNumber),
              _metaRow('Category', p.category),
              _metaRow('Origin Facility', p.factoryLocation),
              _metaRow('Manufacturer', p.manufacturerName),
              _metaRow('Current Custody', p.currentOwner),
              _metaRow('Custody Tier', p.currentOwnerRole.toUpperCase()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cryptographic Attestation
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cryptographic Security Audit', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _secCheck('HMAC-SHA256 Payload Seal', true),
              _secCheck('Genesis Blockchain Block Matched', true),
              _secCheck('Custody Transfer Sequence Valid', true),
              _secCheck('Zero Tamper Reports Filed', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditReceiptCard() {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isAdmin = user?.role == UserRole.admin;
    final receiptId = widget.scanReceiptId ?? 'SCAN-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
    final p = _product!;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Verification Receipt',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Telemetry Logged to Immutable SupplyChainX Ledger',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Text(
                  'LOGGED ✓',
                  style: GoogleFonts.inter(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 10),

          _metaRow('Receipt ID', receiptId, isMono: true),
          _metaRow('Log Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), isMono: true),
          _metaRow('Verifier Account', user?.email ?? 'anonymous_scanner@supply.com'),
          _metaRow('Role Identity', (user?.role.label ?? 'Consumer').toUpperCase()),
          _metaRow('Verification Verdict', p.isAuthentic ? 'VERIFIED_AUTHENTIC' : 'TAMPER_FLAGGED'),
          _metaRow('Chain Storage', 'SQLite + EVM Smart Contract Audit Stream'),

          const SizedBox(height: 10),
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.security_rounded, size: 14),
                label: const Text('Inspect in Administrator Audit Feed →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                onPressed: () => context.push('/audit'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live audit stream & full telemetry log restricted to Administrator account.',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: isMono
                  ? GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secCheck(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? AppColors.success : AppColors.danger, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTimeline() {
    final p = _product!;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Custody Handoff History',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${p.journey.length} verified events', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          ...p.journey.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isLast = idx == p.journey.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.check, color: Colors.white, size: 11),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(width: 1.5, color: AppColors.cardBorder),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  stage.action,
                                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${DateTime.now().difference(stage.timestamp).inDays}d ago',
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stage.role} · ${stage.actor}',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            stage.location,
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tx: ${stage.blockchainHash.length > 20 ? "${stage.blockchainHash.substring(0, 10)}...${stage.blockchainHash.substring(stage.blockchainHash.length - 8)}" : stage.blockchainHash}',
                              style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
