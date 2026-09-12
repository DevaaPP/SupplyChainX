import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class NotFoundScreen extends StatefulWidget {
  final String? uri;
  const NotFoundScreen({super.key, this.uri});

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      context.go('/verify/$query');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Route Not Found · 404',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      color: AppColors.warning,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Page or Resource Not Found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.uri != null
                        ? 'The requested endpoint "${widget.uri}" is not recognized on this terminal.'
                        : 'The link you followed may be broken or the resource has been relocated.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Quick Serial / Page Lookup',
                    hint: 'Enter Product Serial (e.g. SCX-XXXXX)',
                    controller: _searchCtrl,
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: 'Search Consignment',
                    icon: Icons.search,
                    onPressed: _search,
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_outlined, size: 16),
                      label: const Text('Return to Operational Home', style: TextStyle(fontSize: 13)),
                    ),
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
