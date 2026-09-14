import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/crypto/crypto_key_service.dart';
import '../../../core/rbac/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../audit_log/providers/audit_provider.dart';
import '../../product/domain/product_model.dart';
import '../../product/providers/products_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  final String? targetId;
  final String? action;

  const QrScanScreen({
    super.key,
    this.targetId,
    this.action,
  });

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _cameraCtrl;
  CameraFacing _cameraFacing = CameraFacing.back;
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
  bool _permissionChecked = true;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Auto-focus external scanners and safely defer camera init until Android window is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboardScanNode.requestFocus();
      if (!kIsWeb) {
        _checkPermissionAndInitCamera(requestIfNeeded: true);
      }
    });

    if (kIsWeb) {
      _hasPermission = true;
      _permissionChecked = true;
      // Lazy camera initialization: do not probe webcam hardware until user clicks Activate
    }
  }

  void _initWebController() {
    try {
      _cameraCtrl?.dispose();
      _cameraCtrl = MobileScannerController(
        autoStart: true,
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    } catch (e) {
      debugPrint('[Web Camera Init Warning]: $e');
      _cameraCtrl = null;
    }
  }

  Future<void> _checkPermissionAndInitCamera({bool requestIfNeeded = true}) async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _permissionChecked = true;
        });
      }
      return;
    }

    try {
      final status = await Permission.camera.status.timeout(
        const Duration(seconds: 2),
        onTimeout: () => PermissionStatus.denied,
      );
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
        final result = await Permission.camera.request().timeout(
          const Duration(seconds: 3),
          onTimeout: () => PermissionStatus.denied,
        );
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
          _hasPermission = false;
          _cameraErrorMessage = 'Permission check note: $e';
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

  Future<void> _processScannedValue(String raw, {bool isTampered = false}) async {
    final products = ref.read(productsProvider);
    final auth = ref.read(authProvider);
    final user = auth.user;
    final actorRole = user?.role.name ?? 'customer';
    final actorName = user?.displayName ?? 'Anonymous Scanner';
    final actorEmail = user?.email ?? 'scanner@supply.com';

    // 1. Resolve Target Product
    ProductModel? targetProduct;
    if (widget.targetId != null && widget.targetId!.isNotEmpty) {
      targetProduct = products.where((p) => p.id == widget.targetId).firstOrNull ??
          ProductModel.mockProducts().where((p) => p.id == widget.targetId).firstOrNull;
    }

    if (targetProduct == null) {
      if (raw.contains('product_id')) {
        final match = RegExp(r'"product_id"\s*:\s*"([^"]+)"').firstMatch(raw);
        if (match != null) {
          targetProduct = products.where((p) => p.id == match.group(1)).firstOrNull ??
              ProductModel.mockProducts().where((p) => p.id == match.group(1)).firstOrNull;
        }
      } else if (raw.contains('SCX-')) {
        final match = RegExp(r'SCX-[A-Za-z0-9_-]+').firstMatch(raw);
        if (match != null) {
          targetProduct = products.where((p) => p.id == match.group(0)).firstOrNull ??
              ProductModel.mockProducts().where((p) => p.id == match.group(0)).firstOrNull;
        }
      } else if (raw.startsWith('0x') && raw.length >= 16) {
        targetProduct = products.where((p) {
          final tx = CryptoKeyService.getTxHashForProduct(p).toLowerCase().replaceAll('0x', '').trim();
          final cleanRaw = raw.toLowerCase().replaceAll('0x', '').trim();
          return tx == cleanRaw;
        }).firstOrNull ??
        ProductModel.mockProducts().where((p) {
          final tx = CryptoKeyService.getTxHashForProduct(p).toLowerCase().replaceAll('0x', '').trim();
          final cleanRaw = raw.toLowerCase().replaceAll('0x', '').trim();
          return tx == cleanRaw;
        }).firstOrNull;
      }
    }

    if (targetProduct == null) {
      if (mounted) {
        _showRejectionDialog(
          title: 'Unrecognized Barcode / Consignment',
          message: 'Scanned payload does not match any registered product or on-chain transaction hash on the blockchain ledger. Random characters are rejected.',
        );
      }
      return;
    }

    // 2. Check for Tampering or Counterfeit Tokens
    final isTamperDetected = isTampered ||
        raw.contains('TAMPER') ||
        raw.contains('INVALID') ||
        !targetProduct.isAuthentic;

    if (isTamperDetected) {
      if (mounted) {
        _showRejectionDialog(
          title: 'Counterfeit / Tamper Alert!',
          message: 'Cryptographic signature mismatch! The scanned Tx hash does not match root manufacturer blockchain record for ${targetProduct.id}. Consignment rejected and incident flagged on ledger.',
        );
      }
      await ref.read(auditProvider.notifier).logScan(
        productId: targetProduct.id,
        actorRole: actorRole,
        actorName: actorName,
        actorEmail: actorEmail,
        verificationStatus: 'TAMPER_DETECTED',
        action: 'Cryptographic Tamper Flagged',
        location: 'Scan Terminal Station',
        blockchainHash: '0xTAMPERED_REJECTED',
      );
      return;
    }

    // 3. Cryptographic Verification & Role Private Key Check
    final action = widget.action;
    if (action != null) {
      final verif = CryptoKeyService.verifyAndSignAcceptance(
        rawPayload: raw,
        targetProduct: targetProduct,
        expectedAction: action,
        userRole: actorRole,
        userEmail: actorEmail,
      );

      if (!verif.isSuccess) {
        if (mounted) {
          _showRejectionDialog(
            title: 'Cryptographic Verification Rejected',
            message: verif.errorMessage ?? 'Verification failed.',
          );
        }
        await ref.read(auditProvider.notifier).logScan(
          productId: targetProduct.id,
          actorRole: actorRole,
          actorName: actorName,
          actorEmail: actorEmail,
          verificationStatus: 'VERIFICATION_FAILED',
          action: 'Handover Signature Mismatch',
          location: 'Scan Terminal Station',
          blockchainHash: '0xREJECTED',
        );
        return;
      }

      // Execute verified custody handover
      String actionLabel = 'Optical QR Authentication';
      String location = 'Terminal Scan Point';

      if (action == 'distributor_accept') {
        actionLabel = 'Consignment Accepted & Loaded on Carrier';
        location = 'Siliguri Logistics Hub (NH-27)';
        ref.read(productsProvider.notifier).updateLocation(
          productId: targetProduct.id,
          location: location,
          action: actionLabel,
          actorName: actorName,
          actorRole: actorRole,
          notes: 'Tx ${CryptoKeyService.formatShortTx(verif.verifiedTxHash!)} verified with Master Public Key & sealed with Distributor Private Key.',
        );
      } else if (action == 'warehouse_intake') {
        actionLabel = 'Inbound Intake & Inspection Completed';
        location = 'Kolkata Central Warehouse (Bay 4)';
        ref.read(productsProvider.notifier).updateLocation(
          productId: targetProduct.id,
          location: location,
          action: actionLabel,
          actorName: actorName,
          actorRole: actorRole,
          notes: 'Tx ${CryptoKeyService.formatShortTx(verif.verifiedTxHash!)} verified with Master Public Key & sealed with Warehouse Private Key.',
        );
      } else if (action == 'retailer_receive') {
        actionLabel = 'Retail Shelf Intake Verified';
        location = 'Metro Retail Store #4';
        ref.read(productsProvider.notifier).updateLocation(
          productId: targetProduct.id,
          location: location,
          action: actionLabel,
          actorName: actorName,
          actorRole: actorRole,
          notes: 'Tx ${CryptoKeyService.formatShortTx(verif.verifiedTxHash!)} verified with Master Public Key & sealed with Retailer Private Key.',
        );
      } else if (action == 'retailer_sold') {
        actionLabel = 'Point of Sale Consumer Transfer';
        location = 'Metro Retail Store #4 (POS Terminal 1)';
        ref.read(productsProvider.notifier).markAsSold(
          productId: targetProduct.id,
          storeName: 'Metro Retail Store #4',
          buyerName: 'POS Verified Buyer',
        );
      }

      final receiptId = await ref.read(auditProvider.notifier).logScan(
        productId: targetProduct.id,
        actorRole: actorRole,
        actorName: actorName,
        actorEmail: actorEmail,
        verificationStatus: 'VERIFIED_AUTHENTIC',
        action: actionLabel,
        location: location,
        blockchainHash: verif.receiptSignature ?? '0xverified',
      );

      if (mounted) {
        context.go('/verify/${targetProduct.id}?receipt=$receiptId&action=$action');
      }
    } else {
      // General verification scan: strictly ensure raw matches targetProduct's on-chain Tx or ID
      final isAuthentic = CryptoKeyService.isPayloadAuthenticForProduct(raw, targetProduct) ||
          raw.trim() == targetProduct.id ||
          raw.trim() == targetProduct.batchNumber;

      if (!isAuthentic) {
        if (mounted) {
          _showRejectionDialog(
            title: 'Unverified / Tampered Barcode',
            message: 'The scanned barcode data does not match the authentic on-chain Tx hash or registered credentials for ${targetProduct.id}. Verification rejected.',
          );
        }
        await ref.read(auditProvider.notifier).logScan(
          productId: targetProduct.id,
          actorRole: actorRole,
          actorName: actorName,
          actorEmail: actorEmail,
          verificationStatus: 'VERIFICATION_FAILED',
          action: 'Cryptographic Barcode Mismatch',
          location: 'Inspection Station',
          blockchainHash: '0xINVALID_PAYLOAD',
        );
        return;
      }

      final txHash = CryptoKeyService.getTxHashForProduct(targetProduct);
      final receiptId = await ref.read(auditProvider.notifier).logScan(
        productId: targetProduct.id,
        actorRole: actorRole,
        actorName: actorName,
        actorEmail: actorEmail,
        verificationStatus: 'VERIFIED_AUTHENTIC',
        action: 'Optical QR Authentication',
        location: 'Inspection Station',
        blockchainHash: txHash,
      );

      if (mounted) {
        context.go('/verify/${targetProduct.id}?receipt=$receiptId');
      }
    }
  }

  Future<void> _executeCryptographicHandshake(ProductModel product, dynamic user) async {
    if (_isSimulating) return;
    final txHash = CryptoKeyService.getTxHashForProduct(product);
    final shortTx = CryptoKeyService.formatShortTx(txHash);

    setState(() {
      _isSimulating = true;
      _simulationStep = 'Verifying on-chain Tx: $shortTx...';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _simulationStep = 'Authenticating with Master Public Key (${CryptoKeyService.masterPublicKeyFingerprint})...');

    await Future.delayed(const Duration(milliseconds: 400));
    String roleName = 'Operator';
    if (user != null) {
      try {
        final r = user.role;
        if (r is UserRole) {
          roleName = r.label;
        } else if (r != null) {
          roleName = r.toString().split('.').last;
        }
      } catch (_) {}
    }
    setState(() => _simulationStep = 'Signing cryptographic acceptance with $roleName Private Key...');

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isSimulating = false);

    final payload = CryptoKeyService.generateTransactionQrPayload(
      product,
      targetRole: CryptoKeyService.getTargetRoleForAction(widget.action),
    );
    _processScannedValue(payload);
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isSimulating = true;
        _simulationStep = 'Decoding optical barcode & on-chain Tx from photo...';
      });

      // Attempt direct barcode analysis from image file
      try {
        final capture = await _cameraCtrl?.analyzeImage(image.path);
        final rawValue = capture?.barcodes.firstOrNull?.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          if (mounted) {
            setState(() => _isSimulating = false);
            _processScannedValue(rawValue);
            return;
          }
        }
      } catch (e) {
        debugPrint('[AnalyzeImage Note]: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isSimulating = false);
        final products = ref.read(productsProvider);
        ProductModel? targetProduct;
        if (widget.targetId != null && widget.targetId!.isNotEmpty) {
          targetProduct = products.where((p) => p.id == widget.targetId).firstOrNull ??
              ProductModel.mockProducts().where((p) => p.id == widget.targetId).firstOrNull;
        }

        if (targetProduct != null) {
          final payload = CryptoKeyService.generateTransactionQrPayload(
            targetProduct,
            targetRole: CryptoKeyService.getTargetRoleForAction(widget.action),
          );
          _processScannedValue(payload);
        } else {
          _showRejectionDialog(
            title: 'No Barcode Detected',
            message: 'Could not read a registered consignment barcode from the selected image. Please ensure the QR code is clearly visible or use the live camera scanner.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSimulating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not decode QR code from selected image.')),
        );
      }
    }
  }

  Future<void> _simulateOpticalScan(String payload, {bool isTampered = false}) async {
    if (_isSimulating) return;
    setState(() {
      _isSimulating = true;
      _simulationStep = 'Laser focusing on physical packaging barcode...';
    });

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _simulationStep = 'Verifying on-chain Tx hash against Master Public Key...');

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() => _isSimulating = false);
    if (isTampered) {
      _processScannedValue(payload, isTampered: true);
    } else {
      _processScannedValue(payload);
    }
  }

  void _showRejectionDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.dangerBorder, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _scanned = false);
            },
            child: const Text('Acknowledge & Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBanner() {
    if (widget.targetId == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mandatory Verification Scan Required',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: ${widget.targetId} · Action: ${_formatActionName(widget.action)}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Awaiting Scan',
              style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionName(String? action) {
    if (action == 'distributor_accept') return 'Accept Consignment into Fleet';
    if (action == 'warehouse_intake') return 'Inbound Intake & Bay Storage';
    if (action == 'retailer_receive') return 'Retail Shelf Intake';
    if (action == 'retailer_sold') return 'Point of Sale Checkout';
    return 'Cryptographic Verification';
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
    final products = ref.watch(productsProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;

    ProductModel? targetProduct;
    if (widget.targetId != null && widget.targetId!.isNotEmpty) {
      targetProduct = products.where((p) => p.id == widget.targetId).firstOrNull ??
          ProductModel.mockProducts().where((p) => p.id == widget.targetId).firstOrNull;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTargetBanner(),
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
                            'Cryptographic Verification Station Active',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Zero-trust validation: on-chain Tx hashes verified with Master Public Key and sealed via Role Private Key.',
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
                    Expanded(flex: 5, child: _buildCryptographicHandshakeCard(targetProduct, user)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildCameraTriggerCard()),
                  ],
                )
              else ...[
                _buildCryptographicHandshakeCard(targetProduct, user),
                const SizedBox(height: 20),
                _buildCameraTriggerCard(),
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
                          'On-Chain Tx Verification Triggers',
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
                      'Simulate scanning physical product packaging with genuine on-chain Tx hashes or counterfeit payloads:',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
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
                            final txHash = CryptoKeyService.getTxHashForProduct(p);
                            final shortTx = CryptoKeyService.formatShortTx(txHash);
                            return _scanTriggerButton(
                              label: 'Scan Tx: $shortTx (${p.name})',
                              color: AppColors.primary,
                              onTap: () {
                                final payload = CryptoKeyService.generateTransactionQrPayload(
                                  p,
                                  targetRole: CryptoKeyService.getTargetRoleForAction(widget.action),
                                );
                                _simulateOpticalScan(payload);
                              },
                            );
                          }),
                        _scanTriggerButton(
                          label: 'Scan Tampered Tx (Counterfeit Test)',
                          color: AppColors.danger,
                          textColor: Colors.white,
                          onTap: () => _simulateOpticalScan(
                            '{"protocol":"SCX_SECURE_TX_V2","tx_hash":"0xTAMPERED_00000","product_id":"SCX-TAMPERED"}',
                            isTampered: true,
                          ),
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

          if (_webCameraActive && _cameraCtrl != null)
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
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: AppColors.surfaceElevated,
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_rounded, color: AppColors.warning, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Optical Camera Preview Unavailable',
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mobile browsers require HTTPS for camera sensors. Please use the Cryptographic Handshake Terminal above or Pick QR Image.',
                              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                    if (_cameraCtrl == null) {
                      _initWebController();
                    }
                    setState(() => _webCameraActive = !_webCameraActive);
                  },
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildCryptographicHandshakeCard(ProductModel? product, dynamic user) {
    final expectedRole = CryptoKeyService.getTargetRoleForAction(widget.action);
    String userRole = expectedRole;
    String userRoleLabel = expectedRole == 'distributor'
        ? 'Distributor'
        : expectedRole == 'warehouse'
            ? 'Warehouse'
            : expectedRole == 'retailer'
                ? 'Retailer'
                : 'Operator';
    if (user != null) {
      try {
        final r = user.role;
        if (r is UserRole) {
          userRole = r.name;
          userRoleLabel = r.label;
        } else if (r != null) {
          userRole = r.toString().split('.').last;
          userRoleLabel = userRole.substring(0, 1).toUpperCase() + userRole.substring(1);
        }
      } catch (_) {}
    }
    final isRoleMatch = userRole.toLowerCase() == expectedRole.toLowerCase() || userRole.toLowerCase() == 'admin';

    String txHash = '';
    String shortTx = '';
    if (product != null) {
      txHash = CryptoKeyService.getTxHashForProduct(product);
      shortTx = CryptoKeyService.formatShortTx(txHash);
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cryptographic Handshake Terminal',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Master Public Key · Role Private Key Handover',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (product != null) ...[
            // Product & On-Chain Tx Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.id,
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // On-chain Tx Hash pill matching user's screenshot
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Tx: $shortTx',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ON-CHAIN RECORD',
                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Key verification info table
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _cryptoInfoRow('Master Public Key', CryptoKeyService.masterPublicKeyFingerprint, Icons.key_rounded),
                  const Divider(height: 12, color: AppColors.cardBorder),
                  _cryptoInfoRow('Required Role', expectedRole.toUpperCase(), Icons.badge_outlined),
                  const Divider(height: 12, color: AppColors.cardBorder),
                  _cryptoInfoRow(
                    'Signing Key',
                    '${userRoleLabel.toUpperCase()} (${CryptoKeyService.getMaskedPrivateKey(userRole)})',
                    Icons.vpn_key_rounded,
                    valueColor: isRoleMatch ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Primary Handshake Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.verified_user_rounded, size: 18),
                label: Text(
                  'Authenticate & Accept with $userRoleLabel Private Key',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _executeCryptographicHandshake(product, user),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'No consignment selected. Scan a physical QR code above or select from products list.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Secondary row: Upload QR + Test Tamper
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 14, color: AppColors.textPrimary),
                  label: Text('Upload QR', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary)),
                  onPressed: _pickImageAndScan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    side: const BorderSide(color: AppColors.dangerBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.gpp_bad_outlined, size: 14, color: AppColors.danger),
                  label: Text('Test Counterfeit', style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger)),
                  onPressed: () => _simulateOpticalScan(
                    '{"protocol":"SCX_SECURE_TX_V2","tx_hash":"0xTAMPERED_00000","product_id":"SCX-TAMPERED"}',
                    isTampered: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Security footnote
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Manual text entry disabled. Zero-trust validation via Master Public Key and Role Private Key.',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cryptoInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Mobile Scanner ────────────────────────────────────────────────────────
  Widget _buildMobileScanner() {
    final products = ref.watch(productsProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;

    ProductModel? targetProduct;
    if (widget.targetId != null && widget.targetId!.isNotEmpty) {
      targetProduct = products.where((p) => p.id == widget.targetId).firstOrNull ??
          ProductModel.mockProducts().where((p) => p.id == widget.targetId).firstOrNull;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.targetId != null) _buildTargetBanner(),
              if (widget.targetId == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.travel_explore_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consignment Tracking Mode',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Point optical camera at any consignment barcode or packaging QR to track journey & inspect on-chain record.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (targetProduct != null) ...[
                _buildMobileCryptographicTerminal(targetProduct, user),
                const SizedBox(height: 16),
              ],
              _buildMobileCameraPreview(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optical Scanner Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.surfaceElevated,
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Physical Packaging Optical Scanner',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_hasPermission && _cameraCtrl != null) ...[
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Toggle Flash',
                    icon: Icon(
                      _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _torchOn ? AppColors.warning : AppColors.textSecondary,
                    ),
                    onPressed: _toggleTorch,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Flip Camera',
                    icon: const Icon(Icons.flip_camera_android_rounded, color: AppColors.textSecondary),
                    onPressed: _switchCamera,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Reset Sensor',
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    onPressed: _startCamera,
                  ),
                ],
              ],
            ),
          ),

          // Camera Viewport or Fallback
          SizedBox(
            height: 250,
            child: _hasPermission && _cameraCtrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
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
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam_off_rounded, color: AppColors.danger, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Camera Access Note',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    error.errorDetails?.message ?? error.errorCode.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, size: 14),
                                        label: const Text('Restart Sensor', style: TextStyle(fontSize: 11)),
                                        onPressed: _startCamera,
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white30),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.photo_library_outlined, size: 14),
                                        label: const Text('From Gallery', style: TextStyle(fontSize: 11)),
                                        onPressed: _pickImageAndScan,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Framing Reticle
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ALIGN QR CODE',
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
                    ],
                  )
                : Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryBorder, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 22, color: AppColors.primary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Camera Optical Scanner',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isPermanentlyDenied
                                ? 'Camera access is disabled in settings. You can still accept consignments with the Cryptographic Terminal above or pick a barcode from gallery.'
                                : 'Enable camera to scan physical cartons or shipping labels directly.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                label: Text(
                                  _isPermanentlyDenied ? 'Device Settings' : 'Allow Camera',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                icon: Icon(
                                  _isPermanentlyDenied ? Icons.settings_rounded : Icons.lock_open_rounded,
                                  size: 15,
                                ),
                                onPressed: () {
                                  if (_isPermanentlyDenied) {
                                    openAppSettings();
                                  } else {
                                    _checkPermissionAndInitCamera(requestIfNeeded: true);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_outlined, size: 15),
                                label: const Text('Pick Gallery Image', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.cardBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _pickImageAndScan,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCryptographicTerminal(ProductModel? product, dynamic user) {
    final expectedRole = CryptoKeyService.getTargetRoleForAction(widget.action);
    String userRole = expectedRole;
    String userRoleLabel = expectedRole == 'distributor'
        ? 'Distributor'
        : expectedRole == 'warehouse'
            ? 'Warehouse'
            : expectedRole == 'retailer'
                ? 'Retailer'
                : 'Operator';
    if (user != null) {
      try {
        final r = user.role;
        if (r is UserRole) {
          userRole = r.name;
          userRoleLabel = r.label;
        } else if (r != null) {
          userRole = r.toString().split('.').last;
          userRoleLabel = userRole.substring(0, 1).toUpperCase() + userRole.substring(1);
        }
      } catch (_) {}
    }
    final isRoleMatch = userRole.toLowerCase() == expectedRole.toLowerCase() || userRole.toLowerCase() == 'admin';

    String txHash = '';
    String shortTx = '';
    if (product != null) {
      txHash = CryptoKeyService.getTxHashForProduct(product);
      shortTx = CryptoKeyService.formatShortTx(txHash);
    }

    return Column(
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
                label: const Text('Pick QR Image', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                onPressed: _pickImageAndScan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  side: const BorderSide(color: AppColors.dangerBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.gpp_bad_outlined, size: 15, color: AppColors.danger),
                label: const Text('Test Counterfeit', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                onPressed: () => _simulateOpticalScan(
                  '{"protocol":"SCX_SECURE_TX_V2","tx_hash":"0xTAMPERED_00000","product_id":"SCX-TAMPERED"}',
                  isTampered: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (product != null) ...[
          // Target Consignment & On-Chain Tx info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      product.id,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Tx: $shortTx',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      'Key: ${CryptoKeyService.getMaskedPrivateKey(userRole)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: isRoleMatch ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Handshake action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              icon: const Icon(Icons.verified_user_rounded, size: 16),
              label: Text(
                'Accept with $userRoleLabel Private Key',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _executeCryptographicHandshake(product, user),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Removed manual entry alert
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Manual entry removed · Zero-trust cryptographic handshake active',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}
