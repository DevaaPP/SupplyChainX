import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/product_model.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ProductModel.mockProducts();
    final product =
        products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/'),
          ),
          title: const Text('Product Not Found'),
        ),
        body: const EmptyState(
          message: 'Product not found',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(product.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.qr_code_rounded, size: 16),
            label: const Text('Verify QR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => context.go('/verify/${product.id}'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildInfoPanel(context, product),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildJourneyPanel(product),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoPanel(context, product),
                  const SizedBox(height: 20),
                  _buildJourneyPanel(product),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, ProductModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('AUTHENTIC PRODUCT',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                    '${p.journey.length}/5 Stages',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Product info
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product Information',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _row('Product ID', p.id),
              _row('Name', p.name),
              _row('Batch', p.batchNumber),
              _row('Category', p.category),
              _row('Factory', p.factoryLocation),
              _row('Manufacturer', p.manufacturerName),
              _row('Current Owner', p.currentOwner),
              _row('Role', p.currentOwnerRole),
              _row('Registered',
                  _fmtDate(p.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Journey progress
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Journey Progress',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.journey.length} of 5 stages completed',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                      '${(p.journey.length / 5 * 100).round()}%',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.journey.length / 5,
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['🏭', '🚛', '🏪', '🏬', '👤']
                    .asMap()
                    .entries
                    .map((e) => Column(
                          children: [
                            Text(e.value,
                                style: TextStyle(
                                    fontSize: 20,
                                    color: e.key < p.journey.length
                                        ? null
                                        : const Color(0x44FFFFFF))),
                          ],
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        PrimaryButton(
          label: 'Verify Authenticity',
          onPressed: () => context.go('/verify/${p.id}'),
          icon: Icons.verified_rounded,
        ),
      ],
    );
  }

  Widget _buildJourneyPanel(ProductModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supply Chain Journey',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('All stages verified on blockchain',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 20),
        ...List.generate(p.journey.length, (i) {
          final stage = p.journey[i];
          final isLast = i == p.journey.length - 1;
          final roleColors = {
            'Manufacturer': AppColors.manufacturer,
            'Distributor': AppColors.distributor,
            'Warehouse': AppColors.warehouse,
            'Retailer': AppColors.retailer,
            'Customer': AppColors.customer,
          };
          final color = roleColors[stage.role] ?? AppColors.primary;
          final roleIcons = {
            'Manufacturer': '🏭',
            'Distributor': '🚛',
            'Warehouse': '🏪',
            'Retailer': '🏬',
            'Customer': '👤',
          };

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(roleIcons[stage.role] ?? '📦',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  if (!isLast)
                    Container(
                        width: 2, height: 64, color: AppColors.cardBorder),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RoleBadge(role: stage.role, small: true),
                            const Spacer(),
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.low, size: 14),
                            const SizedBox(width: 4),
                            const Text('Verified',
                                style: TextStyle(
                                    color: AppColors.low, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(stage.action,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        _stageRow(Icons.person_outline_rounded, stage.actor),
                        _stageRow(
                            Icons.location_on_outlined, stage.location),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(_fmtDate(stage.timestamp),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                            const Spacer(),
                            const Icon(Icons.link_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${stage.blockchainHash.substring(0, 12)}...',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),

        // Remaining stages (greyed out)
        ...List.generate(5 - p.journey.length, (i) {
          final roleNames = [
            'Manufacturer', 'Distributor', 'Warehouse', 'Retailer', 'Customer'
          ];
          final roleIcons = ['🏭', '🚛', '🏪', '🏬', '👤'];
          final idx = p.journey.length + i;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.cardBorder, width: 2),
                    ),
                    child: Center(
                      child: Text(roleIcons[idx],
                          style: const TextStyle(
                              fontSize: 18, color: Color(0x55FFFFFF))),
                    ),
                  ),
                  if (i < 5 - p.journey.length - 1)
                    Container(
                        width: 2, height: 64, color: AppColors.cardBorder),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: i < 5 - p.journey.length - 1 ? 16 : 0),
                  child: GlassCard(
                    color: AppColors.surfaceElevated.withOpacity(0.4),
                    borderColor: AppColors.cardBorder.withOpacity(0.4),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        RoleBadge(
                            role: roleNames[idx], small: true),
                        const Spacer(),
                        const Text('Pending',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _stageRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12))),
          ],
        ),
      );

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
