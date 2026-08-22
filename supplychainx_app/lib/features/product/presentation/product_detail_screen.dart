import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/product_model.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final product = products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Consignment Not Found'),
        ),
        body: const EmptyState(message: 'No consignment matching ID was located.'),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Consignment Ledger: ${product.id}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.qr_code_rounded, size: 14),
              label: const Text('Verify QR', style: TextStyle(fontSize: 12)),
              onPressed: () => context.push('/verify/${product.id}'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: _buildInfoCard(context, product)),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: _buildJourneyTimeline(product)),
                    ],
                  )
                : Column(
                    children: [
                      _buildInfoCard(context, product),
                      const SizedBox(height: 20),
                      _buildJourneyTimeline(product),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ProductModel p) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Specification Overview', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SeverityBadge(severity: 'AUTHENTIC', small: true),
                ],
              ),
              const SizedBox(height: 12),
              _meta('Serial ID', p.id, isMono: true),
              _meta('Product Name', p.name),
              _meta('Batch Code', p.batchNumber),
              _meta('Category', p.category),
              _meta('Facility', p.factoryLocation),
              _meta('Origin Manufacturer', p.manufacturerName),
              _meta('Current Custody', p.currentOwner),
              _meta('Lifecycle Stage', '${p.journey.length} of 5 Completed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(String label, String value, {bool isMono = false}) {
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

  Widget _buildJourneyTimeline(ProductModel p) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custody Provenance Ledger', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...p.journey.asMap().entries.map((entry) {
            final idx = entry.key;
            final j = entry.value;
            final isLast = idx == p.journey.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.check, color: Colors.white, size: 10)),
                        ),
                        if (!isLast) Expanded(child: Container(width: 1.5, color: AppColors.cardBorder)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(j.action, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${j.role} · ${j.actor} · ${j.location}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          Text('Tx: ${j.blockchainHash}', style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10)),
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
