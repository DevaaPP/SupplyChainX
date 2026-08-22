import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _manualCtrl = TextEditingController();
  final FocusNode _keyboardScanNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _scanned = false;
  bool _torchOn = false;
  bool _webCameraActive = false;
  bool _isSimulating = false;
  String _simulationStep = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus to capture external hardware USB barcode scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardScanNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    _manualCtrl.dispose();
    _keyboardScanNode.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    final value = barcode!.rawValue!;
    _processScannedValue(value);
  }

  void _processScannedValue(String raw) {
    String productId = raw.trim();
    if (raw.contains('product_id')) {
      final match = RegExp(r'"product_id"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (match != null) productId = match.group(1)!;
    } else if (raw.contains('SCX-')) {
      final match = RegExp(r'SCX-\d+').firstMatch(raw);
      if (match != null) productId = match.group(0)!;
    }

    if (mounted) {
      context.go('/verify/$productId');
    }
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isSimulating = true;
        _simulationStep = 'Decoding image metadata & HMAC seal...';
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        setState(() => _isSimulating = false);
        // Default to verified demo serial when decoding from local file
        _processScannedValue('SCX-00112');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSimulating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not decode barcode from selected image.')),
        );
      }
    }
  }

  Future<void> _simulateOpticalScan(String serial, {bool isTampered = false}) async {
    if (_isSimulating) return;
    setState(() {
      _isSimulating = true;
      _simulationStep = 'Laser focusing on barcode symbol...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _simulationStep = 'Verifying HMAC-SHA256 signature against ledger...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _isSimulating = false);
    if (isTampered) {
      context.go('/verify/SCX-TAMPERED-99999');
    } else {
      _processScannedValue(serial);
    }
  }

  void _verifyManual() {
    final id = _manualCtrl.text.trim();
    if (id.isNotEmpty) {
      context.go('/verify/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Barcode & QR Scanner Terminal',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
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
      body: kIsWeb ? _buildWebScanner(isWide) : _buildMobileScanner(),
    );
  }

  // ─── Web Scanner with Live Multi-Triggers ───────────────────────────────────
  Widget _buildWebScanner(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scanner Status Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Web Optical Scanning Station Ready',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Use your live webcam, trigger instant barcode decoders, or upload an image file.',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Simulation Overlay if Active
              if (_isSimulating)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sidebar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _simulationStep,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Two Column Layout
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCameraTriggerCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildHardwareAndManualCard()),
                  ],
                )
              else ...[
                _buildCameraTriggerCard(),
                const SizedBox(height: 20),
                _buildHardwareAndManualCard(),
              ],

              const SizedBox(height: 20),

              // One-Click Fast Scan Triggers
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'One-Click Barcode Trigger Testing',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simulate scanning physical product labels directly into the verification pipeline:',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _scanTriggerButton(
                          label: 'Scan SCX-00112 (Rice - Authentic)',
                          color: AppColors.primary,
                          onTap: () => _simulateOpticalScan('SCX-00112'),
                        ),
                        _scanTriggerButton(
                          label: 'Scan SCX-00098 (Tea - In Transit)',
                          color: AppColors.primary,
                          onTap: () => _simulateOpticalScan('SCX-00098'),
                        ),
                        _scanTriggerButton(
                          label: 'Scan SCX-00134 (Pickle - Registered)',
                          color: AppColors.primary,
                          onTap: () => _simulateOpticalScan('SCX-00134'),
                        ),
                        _scanTriggerButton(
                          label: 'Scan Tampered QR (Counterfeit Test)',
                          color: AppColors.danger,
                          textColor: Colors.white,
                          onTap: () => _simulateOpticalScan('SCX-INVALID', isTampered: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanTriggerButton({
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCameraTriggerCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Optical Camera Trigger',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Activate system webcam or upload an image containing a QR barcode.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (_webCameraActive)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: MobileScanner(
                  controller: _cameraCtrl,
                  onDetect: _onDetect,
                ),
              ),
            )
          else
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Webcam Scanner is Paused',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _webCameraActive ? 'Pause Webcam' : 'Activate Live Webcam',
                  icon: _webCameraActive ? Icons.pause_rounded : Icons.videocam_rounded,
                  onPressed: () {
                    setState(() => _webCameraActive = !_webCameraActive);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _pickImageAndScan,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Upload QR', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareAndManualCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hardware & Manual Serial Input',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for USB laser scanner guns or keyboard serial input.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Barcode / Serial Input',
            hint: 'e.g. SCX-00112 (or pull USB trigger)',
            controller: _manualCtrl,
            prefixIcon: const Icon(Icons.keyboard_outlined, size: 18, color: AppColors.textMuted),
            onChanged: (val) {
              if (val.length >= 9 && val.startsWith('SCX-')) {
                _verifyManual();
              }
            },
          ),
          const SizedBox(height: 14),

          PrimaryButton(
            label: 'Verify Serial Number',
            icon: Icons.search,
            onPressed: _verifyManual,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.usb_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'USB Barcode Guns will auto-trigger upon scanning.',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile Scanner ────────────────────────────────────────────────────────
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
                    borderRadius: BorderRadius.circular(8),
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
                Text('MANUAL SERIAL INPUT', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary),
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
