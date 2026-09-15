import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _storageKey = 'custom_server_host';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _customHost;

  /// Initialize and load stored host on app startup
  static Future<void> init() async {
    try {
      final savedHost = await _storage.read(key: _storageKey);
      if (savedHost != null && savedHost.trim().isNotEmpty) {
        customHost = savedHost.trim();
      }
    } catch (e) {
      debugPrint('[ApiEndpoints Init Note]: $e');
    }
  }

  /// Set and persist custom host across app restarts
  static Future<void> setAndPersistCustomHost(String? host) async {
    customHost = host;
    try {
      if (host != null && host.trim().isNotEmpty) {
        await _storage.write(key: _storageKey, value: host.trim());
      } else {
        await _storage.delete(key: _storageKey);
      }
    } catch (e) {
      debugPrint('[ApiEndpoints Persist Note]: $e');
    }
  }

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
    // Default fallback for native Android/iOS on local network (matches current network IP)
    return '192.168.1.9';
  }

  /// Quickly tests whether a candidate host has an active SupplyChainX backend
  static Future<bool> testHostConnection(String host, {Duration timeout = const Duration(milliseconds: 1500)}) async {
    try {
      final cleanHost = host.trim().replaceAll('http://', '').replaceAll('https://', '').split(':').first;
      final dio = Dio(BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
      ));
      final res = await dio.get('http://$cleanHost:8000/api/v1/products');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Auto-discovers the active LAN backend node by probing candidate IPs
  static Future<String?> autoDiscoverLanServer() async {
    final candidates = [
      if (_customHost != null) _customHost!,
      '192.168.1.9',
      '192.168.1.10',
      '10.0.2.2',
      '127.0.0.1',
      for (int i = 1; i <= 20; i++) '192.168.1.$i',
    ];

    final tested = <String>{};
    for (final candidate in candidates) {
      if (tested.contains(candidate)) continue;
      tested.add(candidate);
      final isAlive = await testHostConnection(candidate, timeout: const Duration(milliseconds: 700));
      if (isAlive) {
        await setAndPersistCustomHost(candidate);
        return candidate;
      }
    }
    return null;
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
