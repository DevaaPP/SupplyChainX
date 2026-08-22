import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

/// QR Scanner Screen — camera on Android, manual entry on Web
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
    // Extract product ID from QR value (format: SCX-XXXXX or full JSON)
    String productId = value;
    if (value.contains('product_id')) {
      // Parse JSON-style QR
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Scan QR Code'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: AppColors.textSecondary),
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

  // ─── Web — manual entry only ──────────────────────────────────────────────
  Widget _buildWebScanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Enter Product ID', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'On web, scan using your phone or enter the product ID manually.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AppTextField(
                label: 'Product ID',
                hint: 'SCX-00112',
                controller: _manualCtrl,
                prefixIcon: const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Verify Product',
                onPressed: _verifyManual,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 24),
              const Text('Demo Product IDs:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['SCX-00112', 'SCX-00098', 'SCX-00134'].map((id) {
                  return ActionChip(
                    label: Text(id, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                    backgroundColor: AppColors.primaryDim,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    onPressed: () => _manualCtrl.text = id,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile — full camera scanner ────────────────────────────────────────
  Widget _buildMobileScanner() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(
                controller: _cameraCtrl,
                onDetect: _onDetect,
              ),
              // Scan overlay
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Corner decorations
                      const SizedBox(),
                    ],
                  ),
                ),
              ),
              // Top overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const Text(
                    'Point camera at QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              // Animated scan line
              _ScanLine(),
            ],
          ),
        ),
        // Manual entry fallback
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OR ENTER MANUALLY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: '',
                        hint: 'Product ID (e.g. SCX-00112)',
                        controller: _manualCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _verifyManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['SCX-00112', 'SCX-00098'].map((id) {
                    return ActionChip(
                      label: Text(id, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      backgroundColor: AppColors.primaryDim,
                      onPressed: () => _manualCtrl.text = id,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: 80 + _anim.value * 240,
        left: MediaQuery.of(context).size.width / 2 - 120,
        child: Container(
          width: 240,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.primary, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
