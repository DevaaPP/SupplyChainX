import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL pointing to the FastAPI backend
  // Automatically detects host IP on Flutter Web (LAN / PAN / Wi-Fi / Hotspot)
  // Supports compile-time override with: --dart-define=API_BASE_URL=http://<IP>:8000/api/v1
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return "http://$host:8000/api/v1";
    }
    return "http://127.0.0.1:8000/api/v1";
  }

  // Root Host for Section 15 Direct API
  static String get hostRoot {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return "http://$host:8000";
    }
    return "http://127.0.0.1:8000";
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
