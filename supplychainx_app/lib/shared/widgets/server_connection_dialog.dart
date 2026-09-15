import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../features/product/providers/products_provider.dart';
import '../../features/audit_log/providers/audit_provider.dart';

/// Interactive dialog to inspect, test, auto-discover, and change the server host IP
class ServerConnectionDialog extends ConsumerStatefulWidget {
  const ServerConnectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ServerConnectionDialog(),
    );
  }

  @override
  ConsumerState<ServerConnectionDialog> createState() => _ServerConnectionDialogState();
}

class _ServerConnectionDialogState extends ConsumerState<ServerConnectionDialog> {
  late final TextEditingController _hostCtrl;
  bool _isTesting = false;
  bool? _isConnected;
  String? _statusMessage;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: ApiEndpoints.activeHost);
    _testConnection(_hostCtrl.text.trim());
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String host) async {
    if (!mounted) return;
    setState(() {
      _isTesting = true;
      _statusMessage = 'Pinging http://' + host + ':8000/api/v1/products...';
    });

    final stopwatch = Stopwatch()..start();
    final ok = await ApiEndpoints.testHostConnection(host);
    stopwatch.stop();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isConnected = ok;
      if (ok) {
        _statusMessage = 'Connected (' + stopwatch.elapsedMilliseconds.toString() + 'ms) · Node Online';
      } else {
        _statusMessage = 'Unreachable · Check if PC and phone share same Wi-Fi / IP';
      }
    });
  }

  Future<void> _autoScanLan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning local subnet (192.168.1.x) for active backend...';
    });

    final found = await ApiEndpoints.autoDiscoverLanServer();

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (found != null) {
      _hostCtrl.text = found;
      _testConnection(found);
      ref.read(productsProvider.notifier).refresh();
      ref.read(auditProvider.notifier).fetchLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-detected active PAN Node at $found!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _statusMessage = 'Subnet scan complete. No active node found automatically.';
      });
    }
  }

  Future<void> _saveAndApply() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;

    await ApiEndpoints.setAndPersistCustomHost(host);
    if (!mounted) return;

    ref.read(productsProvider.notifier).refresh();
    ref.read(auditProvider.notifier).fetchLogs();

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PAN Node updated to $host · Reconnecting...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Icon(Icons.router_rounded, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAN Node Network Config',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Connect mobile APK & web to backend server',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    if (_isTesting || _isScanning)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected == true ? AppColors.success : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage ?? 'Checking connection...',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: _isConnected == true ? AppColors.success : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _isTesting ? null : () => _testConnection(_hostCtrl.text.trim()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Ping',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Host Input Field
              Text(
                'SERVER HOST / IP ADDRESS',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hostCtrl,
                style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.9',
                  hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  prefixIcon: const Icon(Icons.dns_outlined, size: 18, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                    onPressed: () => _hostCtrl.clear(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (v) => _testConnection(v.trim()),
              ),
              const SizedBox(height: 12),

              // Quick Preset Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _presetChip('192.168.1.9', 'Current LAN'),
                  _presetChip('192.168.1.10', 'Old LAN'),
                  _presetChip('10.0.2.2', 'Emulator'),
                  _presetChip('127.0.0.1', 'Localhost'),
                ],
              ),
              const SizedBox(height: 16),

              // Auto-Scan Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primaryBorder),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(
                  _isScanning ? 'Scanning Subnet...' : 'Auto-Detect LAN Server (Port 8000)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: _isScanning ? null : _autoScanLan,
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(
                        'Save & Connect',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _saveAndApply,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String ip, String label) {
    final isSelected = _hostCtrl.text.trim() == ip;
    return InkWell(
      onTap: () {
        _hostCtrl.text = ip;
        _testConnection(ip);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          label + ': ' + ip,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
