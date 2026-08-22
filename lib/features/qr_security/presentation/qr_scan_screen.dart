import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final _manualCtrl = TextEditingController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _cameraCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    final value = barcode!.rawValue!;
    String productId = value;
    if (value.contains('product_id')) {
      final match = RegExp(r'"product_id"\s*:\s*"([^"]+)"').firstMatch(value);
      if (match != null) productId = match.group(1)!;
    }
    if (mounted) context.go('/verify/$productId');
  }

  void _verifyManual() {
    final id = _manualCtrl.text.trim();
    if (id.isNotEmpty) {
      context.go('/verify/$id');
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
        title: Text('Optical Barcode & QR Verification', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, size: 20),
              onPressed: () {
                setState(() => _torchOn = !_torchOn);
                _cameraCtrl.toggleTorch();
              },
            ),
        ],
      ),
      body: kIsWeb ? _buildWebScanner() : _buildMobileScanner(),
    );
  }

  Widget _buildWebScanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.navy, size: 24),
                ),
                const SizedBox(height: 16),
                Text('Optical Barcode Terminal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'On web workstations, enter the physical carton serial or use an attached USB barcode scanner.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Scanned Serial ID',
                  hint: 'e.g. SCX-00112',
                  controller: _manualCtrl,
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Execute Verification Check',
                  icon: Icons.check_circle_outline,
                  onPressed: _verifyManual,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Demo Serials: ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                    ...['SCX-00112', 'SCX-00098'].map((id) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              _manualCtrl.text = id;
                              _verifyManual();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(id, style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScanner() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(controller: _cameraCtrl, onDetect: _onDetect),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MANUAL INPUT FALLBACK', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: '',
                        hint: 'Serial Code (e.g. SCX-00112)',
                        controller: _manualCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        onPressed: _verifyManual,
                        child: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
