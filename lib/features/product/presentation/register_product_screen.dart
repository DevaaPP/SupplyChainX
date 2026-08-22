import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class RegisterProductScreen extends ConsumerStatefulWidget {
  const RegisterProductScreen({super.key});

  @override
  ConsumerState<RegisterProductScreen> createState() =>
      _RegisterProductScreenState();
}

class _RegisterProductScreenState extends ConsumerState<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController(text: 'BAT-2026-X102');
  final _locationCtrl = TextEditingController(text: 'Guwahati Manufacturing Unit 1');
  final _descCtrl = TextEditingController();
  String _category = 'Food & Agriculture';
  bool _isLoading = false;
  final String _productId = 'SCX-${(10000 + (const Uuid().v4().hashCode.abs() % 89999)).toString()}';

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product $_productId committed to chain.')),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard/manufacturer'),
        ),
        title: Text('Register Manufacturing Consignment', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    AppTextField(
                      label: 'Auto-Generated Serial Code',
                      controller: TextEditingController(text: _productId),
                      readOnly: true,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Product Name',
                      hint: 'e.g. Organic Basmati Rice 5kg',
                      controller: _nameCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Batch Number',
                            controller: _batchCtrl,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      label: 'Manufacturing Facility',
                      controller: _locationCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Notes / Specifications',
                      controller: _descCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: 'Register Consignment & Generate QR',
                      icon: Icons.check_circle_outline,
                      isLoading: _isLoading,
                      onPressed: _register,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
