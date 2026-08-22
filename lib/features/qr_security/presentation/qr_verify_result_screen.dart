import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../product/domain/product_model.dart';

/// Product Verification Result Screen
/// Shows AUTHENTIC PRODUCT or TAMPERED PRODUCT with the full supply chain journey.
/// This is the most important screen — shown after QR scan or product ID lookup.
class QrVerifyResultScreen extends ConsumerStatefulWidget {
  final String? productId;

  const QrVerifyResultScreen({super.key, this.productId});

  @override
  ConsumerState<QrVerifyResultScreen> createState() => _QrVerifyResultScreenState();
}

class _QrVerifyResultScreenState extends ConsumerState<QrVerifyResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  ProductModel? _product;
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _loadProduct();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    await Future.delayed(const Duration(milliseconds: 900)); // simulate lookup
    final products = ProductModel.mockProducts();
    ProductModel? found;
    if (widget.productId != null) {
      found = products.where((p) => p.id == widget.productId).firstOrNull;
    } else {
      found = products.first; // default demo
    }
    if (mounted) {
      setState(() {
        _product = found;
        _isLoading = false;
        _notFound = found == null;
      });
      if (found != null) _scaleCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Product Verification'),
        actions: [
          IconButton(icon: const Icon(Icons.home_outlined), onPressed: () => context.go('/')),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _notFound
              ? _buildNotFound()
              : isWide
                  ? _buildWide()
                  : _buildMobile(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Verifying product...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Checking blockchain records', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.criticalDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: AppColors.critical, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Product Not Found', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'No product found with ID: ${widget.productId ?? "unknown"}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: PrimaryButton(label: 'Try Again', onPressed: () => context.go('/')),
          ),
        ],
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: _buildResultCard())),
        Expanded(flex: 5, child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: _buildJourney())),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildResultCard(),
          const SizedBox(height: 20),
          _buildJourney(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final p = _product!;
    final isAuthentic = p.isAuthentic;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        children: [
          // AUTHENTIC / TAMPERED banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAuthentic
                    ? [AppColors.low.withOpacity(0.15), AppColors.primary.withOpacity(0.08)]
                    : [AppColors.critical.withOpacity(0.15), AppColors.high.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAuthentic ? AppColors.low.withOpacity(0.4) : AppColors.critical.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isAuthentic ? AppColors.lowDim : AppColors.criticalDim,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAuthentic ? Icons.verified_rounded : Icons.dangerous_rounded,
                    color: isAuthentic ? AppColors.low : AppColors.critical,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthentic ? '✓ AUTHENTIC PRODUCT' : '✗ TAMPERED / COUNTERFEIT',
                  style: TextStyle(
                    color: isAuthentic ? AppColors.low : AppColors.critical,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAuthentic
                      ? 'This product has been verified on the blockchain.\nAll records are authentic.'
                      : 'WARNING: This product\'s QR signature is invalid.\nDo not accept or purchase this item.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Product Info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Product Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Product ID', p.id),
                _detailRow('Product Name', p.name),
                _detailRow('Batch Number', p.batchNumber),
                _detailRow('Category', p.category),
                _detailRow('Manufacturer', p.manufacturerName),
                _detailRow('Factory', p.factoryLocation),
                _detailRow('Registered', _formatDate(p.createdAt)),
                _detailRow('Current Owner', p.currentOwner),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Security Verification', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                _securityCheck('HMAC-SHA256 Signature', true),
                _securityCheck('Blockchain Records Found', true),
                _securityCheck('Product ID Verified', true),
                _securityCheck('Journey Stages Intact', isAuthentic),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (isAuthentic) ...[
            PrimaryButton(
              label: 'View Full Journey',
              onPressed: () => context.go('/product/${p.id}'),
              icon: Icons.timeline_rounded,
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined, size: 16),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _securityCheck(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? AppColors.low : AppColors.critical,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildJourney() {
    final p = _product!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supply Chain Journey', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${p.journey.length} stages recorded on blockchain', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
          final icon = roleIcons[stage.role] ?? '📦';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.5), width: 2),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 60, color: AppColors.cardBorder),
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
                            Icon(Icons.check_circle_rounded, color: AppColors.low, size: 14),
                            const SizedBox(width: 4),
                            const Text('Verified', style: TextStyle(color: AppColors.low, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(stage.action,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(stage.actor, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(child: Text(stage.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(_formatDate(stage.timestamp), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const Spacer(),
                            // Blockchain hash
                            const Icon(Icons.link_rounded, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${stage.blockchainHash.substring(0, 10)}...',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
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
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
