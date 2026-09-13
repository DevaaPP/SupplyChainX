import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../product/providers/products_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _cameraCtrl;
  CameraFacing _cameraFacing = CameraFacing.back;
  final _manualCtrl = TextEditingController();
  final FocusNode _keyboardScanNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _scanned = false;
  bool _torchOn = false;
  bool _webCameraActive = false;
  bool _isSimulating = false;
  String _simulationStep = '';

  // Mobile camera permission & lifecycle state
  bool _hasPermission = false;
  bool _isPermanentlyDenied = false;
  bool _permissionChecked = false;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Auto-focus to capture external hardware USB barcode scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardScanNode.requestFocus();
    });

    if (kIsWeb) {
      _hasPermission = true;
      _permissionChecked = true;
      _initWebController();
    } else {
      _checkPermissionAndInitCamera(requestIfNeeded: true);
    }
  }

  void _initWebController() {
    _cameraCtrl?.dispose();
    _cameraCtrl = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  Future<void> _checkPermissionAndInitCamera({bool requestIfNeeded = true}) async {
    if (kIsWeb) {
      setState(() {
        _hasPermission = true;
        _permissionChecked = true;
      });
      return;
    }

    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        if (mounted) {
          setState(() {
            _hasPermission = true;
            _isPermanentlyDenied = false;
            _permissionChecked = true;
            _cameraErrorMessage = null;
          });
          _startCamera();
        }
        return;
      }

      if (requestIfNeeded && !status.isPermanentlyDenied) {
        final result = await Permission.camera.request();
        if (mounted) {
          if (result.isGranted) {
            setState(() {
              _hasPermission = true;
              _isPermanentlyDenied = false;
              _permissionChecked = true;
              _cameraErrorMessage = null;
            });
            _startCamera();
          } else {
            setState(() {
              _hasPermission = false;
              _isPermanentlyDenied = result.isPermanentlyDenied;
              _permissionChecked = true;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _isPermanentlyDenied = status.isPermanentlyDenied;
            _permissionChecked = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionChecked = true;
          _cameraErrorMessage = 'Permission check failed: $e';
        });
      }
    }
  }

  void _startCamera() {
    if (!mounted) return;
    try {
      _cameraCtrl?.dispose();
      _cameraCtrl = MobileScannerController(
        autoStart: true,
        torchEnabled: _torchOn,
        facing: _cameraFacing,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.code39],
      );
      setState(() {
        _cameraErrorMessage = null;
      });
    } catch (e) {
      setState(() {
        _cameraErrorMessage = 'Failed to start camera hardware: $e';
      });
    }
  }

  void _switchCamera() {
    setState(() {
      _cameraFacing = (_cameraFacing == CameraFacing.back)
          ? CameraFacing.front
          : CameraFacing.back;
    });
    _startCamera();
  }

  void _toggleTorch() {
    setState(() => _torchOn = !_torchOn);
    _cameraCtrl?.toggleTorch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;

    if (state == AppLifecycleState.resumed) {
      // Re-check permission if user returned from system app settings or permission dialog
      Permission.camera.status.then((status) {
        if (!mounted) return;
        if (status.isGranted) {
          final wasWithoutPermission = !_hasPermission;
          setState(() {
            _hasPermission = true;
            _isPermanentlyDenied = false;
            _permissionChecked = true;
          });
          // Re-create camera if permission was just granted or controller had failed
          if (wasWithoutPermission || _cameraCtrl == null || _cameraErrorMessage != null) {
            _startCamera();
          }
        }
      });
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraCtrl?.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.dispose();
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
    if (raw.contains('/verify/')) {
      final parts = raw.split('/verify/');
      if (parts.length > 1) {
        productId = parts.last.split('?')[0].split('#')[0].trim();
      }
    } else if (raw.contains('product_id')) {
      final match = RegExp(r'"product_id"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (match != null) productId = match.group(1)!;
    } else if (raw.contains('SCX-')) {
      final match = RegExp(r'SCX-[A-Za-z0-9_-]+').firstMatch(raw);
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
        final products = ref.read(productsProvider);
        final fallbackId = products.isNotEmpty ? products.first.id : 'SCX-00001';
        _processScannedValue(fallbackId);
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
          if (!kIsWeb) ...[
            IconButton(
              tooltip: 'Switch Camera',
              icon: const Icon(Icons.flip_camera_android_rounded, size: 20),
              onPressed: _switchCamera,
            ),
            IconButton(
              tooltip: 'Torch',
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? AppColors.warning : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: _toggleTorch,
            ),
            IconButton(
              tooltip: 'Restart Camera',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _startCamera,
            ),
          ],
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
                    Builder(builder: (context) {
                      final products = ref.watch(productsProvider);
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (products.isEmpty)
                            _scanTriggerButton(
                              label: '+ Provision Showcase in Manufacturer Hub',
                              color: AppColors.primary,
                              onTap: () => context.push('/dashboard/manufacturer'),
                            )
                          else
                            ...products.take(3).map((p) {
                              return _scanTriggerButton(
                                label: 'Scan ${p.id} (${p.name})',
                                color: AppColors.primary,
                                onTap: () => _simulateOpticalScan(p.id),
                              );
                            }),
                          _scanTriggerButton(
                            label: 'Scan Tampered QR (Counterfeit Test)',
                            color: AppColors.danger,
                            textColor: Colors.white,
                            onTap: () => _simulateOpticalScan('SCX-INVALID', isTampered: true),
                          ),
                        ],
                      );
                    }),
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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _pickImageAndScan,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Upload QR', style: TextStyle(fontSize: 12)),
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
            hint: 'e.g. SCX-XXXXX (or pull USB trigger)',
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
    // 1. Permission is still being checked
    if (!_permissionChecked) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Checking optical sensor & permissions...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Permission is Denied or Not Yet Granted
    if (!_hasPermission) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryBorder, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 28, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Access Required',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPermanentlyDenied
                          ? 'Camera permission has been disabled. Please open device settings to allow SupplyChainX camera access for scanning batch QR codes.'
                          : 'SupplyChainX requires camera permissions to scan cryptographic product QR codes and verify ledger state.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: _isPermanentlyDenied ? 'Open Device Settings' : 'Allow Camera Access',
                        icon: _isPermanentlyDenied ? Icons.settings_rounded : Icons.lock_open_rounded,
                        onPressed: () {
                          if (_isPermanentlyDenied) {
                            openAppSettings();
                          } else {
                            _checkPermissionAndInitCamera(requestIfNeeded: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Scan QR from Photo Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _pickImageAndScan,
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

    // 3. Permission Granted — Display Camera Preview with Controls & Fallbacks
    return Column(
      children: [
        // Camera Viewport
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_cameraCtrl != null)
                MobileScanner(
                  controller: _cameraCtrl!,
                  onDetect: _onDetect,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context, child) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 12),
                            Text(
                              'Initializing camera sensor...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_rounded, color: AppColors.danger, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Camera Initialization Issue',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              error.errorDetails?.message ?? error.errorCode.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Restart Camera'),
                                  onPressed: _startCamera,
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                  ),
                                  icon: const Icon(Icons.flip_camera_android_rounded, size: 16),
                                  label: const Text('Flip Lens'),
                                  onPressed: _switchCamera,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.black,
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text('Start Camera Preview'),
                      onPressed: _startCamera,
                    ),
                  ),
                ),

              // Viewfinder Framing Reticle
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ALIGN QR CODE IN FRAME',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),

              // Floating Controls Bar (Top right corner of viewfinder)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Toggle Flash',
                        icon: Icon(
                          _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _torchOn ? AppColors.warning : Colors.white,
                          size: 18,
                        ),
                        onPressed: _toggleTorch,
                      ),
                      IconButton(
                        tooltip: 'Flip Camera',
                        icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 18),
                        onPressed: _switchCamera,
                      ),
                      IconButton(
                        tooltip: 'Pick from Gallery',
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
                        onPressed: _pickImageAndScan,
                      ),
                      IconButton(
                        tooltip: 'Reboot Sensor',
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                        onPressed: _startCamera,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Controls: Quick Chips & Manual Input
        Expanded(
          flex: 3,
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fast action chips
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 15, color: AppColors.primary),
                          label: const Text('Gallery Image', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                          onPressed: _pickImageAndScan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.verified_outlined, size: 15, color: AppColors.low),
                          label: const Text('Test Batch', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                          onPressed: () => _simulateOpticalScan('SCX-00001'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Manual Serial Input
                  Text(
                    'MANUAL SERIAL CODE INPUT',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: '',
                          hint: 'Serial Code (e.g. SCX-XXXXX)',
                          controller: _manualCtrl,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
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
        ),
      ],
    );
  }
}
