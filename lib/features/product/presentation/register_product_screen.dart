import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/product_model.dart';

class RegisterProductScreen extends ConsumerStatefulWidget {
  const RegisterProductScreen({super.key});

  @override
  ConsumerState<RegisterProductScreen> createState() =>
      _RegisterProductScreenState();
}

class _RegisterProductScreenState
    extends ConsumerState<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Food & Agriculture';
  bool _isLoading = false;
  final String _productId =
      'SCX-${(10000 + (const Uuid().v4().hashCode.abs() % 89999)).toString()}';

  static const _categories = [
    'Food & Agriculture',
    'Beverages',
    'Electronics',
    'Textiles',
    'Pharmaceuticals',
    'Chemicals',
    'Machinery',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
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
                'Product $_productId registered successfully. QR code generated.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    if (mounted) context.pop();
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard/manufacturer'),
        ),
        title: const Text('Register Product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isWide ? 680 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  GlassCard(
                    color: AppColors.primaryDim,
                    borderColor: AppColors.primary.withOpacity(0.3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_box_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Register New Product',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text(
                                  'Product will be recorded on the blockchain and a signed QR code will be generated.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auto Product ID
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Product ID',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _productId,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace'),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDim,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('AUTO-GENERATED',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form fields
                  AppTextField(
                    label: 'Product Name *',
                    hint: 'e.g. Organic Rice 5kg',
                    controller: _nameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Product name required' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Batch Number *',
                          hint: 'e.g. B-2024-001',
                          controller: _batchCtrl,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Batch number required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category *',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _category,
                              dropdownColor: AppColors.surfaceElevated,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.cardBorder)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.cardBorder)),
                              ),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _category = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Factory Location *',
                    hint: 'e.g. Guwahati Manufacturing Plant',
                    controller: _locationCtrl,
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.textMuted),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Location required' : null,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Description',
                    hint: 'Brief description of the product...',
                    controller: _descCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // What happens next info
                  GlassCard(
                    color: AppColors.secondaryDim,
                    borderColor: AppColors.secondary.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.secondary, size: 16),
                            SizedBox(width: 8),
                            Text('What happens after registration:',
                                style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...[
                          '1. Product recorded on the blockchain ledger',
                          '2. HMAC-SHA256 signed QR code generated',
                          '3. Product ID assigned and tracked',
                          '4. Audit log entry created',
                        ].map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'Register Product',
                    onPressed: _isLoading ? null : _register,
                    isLoading: _isLoading,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
