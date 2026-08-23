class ApiEndpoints {
  ApiEndpoints._();

  // Base URL pointing to the FastAPI backend
  static const String baseUrl = "http://127.0.0.1:8000/api/v1";

  // Auth
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String me = "$baseUrl/auth/me";
  static const String toggle2fa = "$baseUrl/auth/toggle-2fa";

  // Products
  static const String products = "$baseUrl/products";
  static const String registerProduct = "$baseUrl/products/register";
  static String productById(String id) => "$baseUrl/products/$id";
  static String productQr(String id) => "$baseUrl/products/$id/qr";

  // Custody & Provenance
  static const String custodyTransfer = "$baseUrl/custody/transfer";
  static String verifyProvenance(String productId) => "$baseUrl/custody/verify/$productId";
  static String custodyChain(String productId) => "$baseUrl/custody/chain/$productId";

  // Security Audit
  static const String auditLogs = "$baseUrl/audit/logs";
  static const String auditStats = "$baseUrl/audit/stats";

  // Plug-ins for other teams
  static const String predictDelay = "$baseUrl/ml/predict-delay";
  static const String aiChat = "$baseUrl/ai/chat";
  static const String blockchainStatus = "$baseUrl/blockchain/status";
  static const String analyticsKpis = "$baseUrl/analytics/kpis";
  static const String analyticsSuppliers = "$baseUrl/analytics/suppliers";
}
