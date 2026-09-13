import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

    final isWide = context.screenWidth >= 880;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          context.isMobile ? product.id : 'Consignment Ledger: ${product.id}',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
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
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 14 : 24,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
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
                  Expanded(
                    child: Text(
                      'Specification Overview',
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
        const SizedBox(height: 16),

        // Cryptographic QR Code Packaging Sticker Card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Packaging QR Sticker',
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 26),
                    ),
                    onPressed: () => showProductQrDialog(context, p),
                    icon: const Icon(Icons.fullscreen_rounded, size: 14),
                    label: const Text('Enlarge', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: QrImageView(
                  data: 'https://supplychainx.com/verify/${p.id}',
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'https://supplychainx.com/verify/${p.id}',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Tamper-evident cryptographic anchor · Stays on physical packaging',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
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
                          Text(j.action, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          Text('${j.role} · ${j.actor} · ${j.location}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                          Text(
                            'Tx: ${j.blockchainHash.length > 20 ? "${j.blockchainHash.substring(0, 10)}...${j.blockchainHash.substring(j.blockchainHash.length - 8)}" : j.blockchainHash}',
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
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
