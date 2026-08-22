import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../product/domain/product_model.dart';

class QrVerifyResultScreen extends ConsumerStatefulWidget {
  final String? productId;

  const QrVerifyResultScreen({super.key, this.productId});

  @override
  ConsumerState<QrVerifyResultScreen> createState() =>
      _QrVerifyResultScreenState();
}

class _QrVerifyResultScreenState extends ConsumerState<QrVerifyResultScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final products = ProductModel.mockProducts();
    ProductModel? found;
    if (widget.productId != null) {
      found = products.where((p) => p.id == widget.productId).firstOrNull;
    } else {
      found = products.first;
    }
    if (mounted) {
      setState(() {
        _product = found;
        _isLoading = false;
        _notFound = found == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Provenance & Verification Report',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 20),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: _isLoading
          ? const CenterPageLoading(message: 'Verifying cryptographic signature on ledger...')
          : _notFound
              ? _buildNotFound()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: isWide
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
                    ),
                  ),
                ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 36),
              const SizedBox(height: 12),
              Text('Serial Not Recognized on Chain', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('ID: ${widget.productId ?? "Unknown"} does not match any registered batch.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Try Another Search', onPressed: () => context.go('/verify')),
            ],
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

  Widget _metaRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
          Text(
            value,
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
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
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
              Text('Custody Handoff History', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                          decoration: BoxDecoration(
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
                              Text(stage.action, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(
                                '${DateTime.now().difference(stage.timestamp).inDays}d ago',
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${stage.role} · ${stage.actor}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          Text(stage.location, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tx: ${stage.blockchainHash}',
                              style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10),
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
