import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String? _customHost;

  /// Set a dynamic server host IP at runtime (e.g. from server settings dialog)
  static set customHost(String? host) {
    if (host != null && host.trim().isNotEmpty) {
      _customHost = host.trim().replaceAll('http://', '').replaceAll('https://', '').split(':').first;
    } else {
      _customHost = null;
    }
  }

  static String? get customHost => _customHost;

  /// Returns the currently active host IP or hostname
  static String get activeHost {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    if (kIsWeb) {
      return Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return '127.0.0.1';
    }
    // Default fallback for native Android/iOS on local network
    return '192.168.1.10';
  }

  // Base URL pointing to the FastAPI backend
  // Automatically detects host IP on Flutter Web (LAN / PAN / Wi-Fi / Hotspot)
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return "http://$host:8000/api/v1";
    }
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return "http://$activeHost:8000/api/v1";
  }

  // Root Host for Section 15 Direct API
  static String get hostRoot {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return "http://$host:8000";
    }
    return "http://$activeHost:8000";
  }

  // Auth
  static String get login => "$baseUrl/auth/login";
  static String get register => "$baseUrl/auth/register";
  static String get me => "$baseUrl/auth/me";
  static String get toggle2fa => "$baseUrl/auth/toggle-2fa";

  // Products
  static String get products => "$baseUrl/products";
  static String get registerProduct => "$baseUrl/products/register";
  static String productById(String id) => "$baseUrl/products/$id";
  static String productQr(String id) => "$baseUrl/products/$id/qr";

  // Custody & Provenance
  static String get custodyTransfer => "$baseUrl/custody/transfer";
  static String verifyProvenance(String productId) => "$baseUrl/custody/verify/$productId";
  static String custodyChain(String productId) => "$baseUrl/custody/chain/$productId";

  // Security Audit
  static String get auditLogs => "$baseUrl/audit/logs";
  static String get auditStats => "$baseUrl/audit/stats";

  // Plug-ins for other teams
  static String get predictDelay => "$baseUrl/ml/predict-delay";
  static String get mlPredictOrder => "$baseUrl/ml/predict";
  static String get aiChat => "$baseUrl/ai/chat";
  static String get blockchainStatus => "$baseUrl/blockchain/status";
  static String get analyticsKpis => "$baseUrl/analytics/kpis";
  static String get analyticsSuppliers => "$baseUrl/analytics/suppliers";
}
