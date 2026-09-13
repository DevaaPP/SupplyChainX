// Core RBAC — role definitions shared across Flutter and mapped to backend
enum UserRole {
  manufacturer,
  distributor,
  warehouse,
  retailer,
  customer,
  admin;

  String get label => switch (this) {
        UserRole.manufacturer => 'Manufacturer',
        UserRole.distributor => 'Distributor',
        UserRole.warehouse => 'Warehouse',
        UserRole.retailer => 'Retailer',
        UserRole.customer => 'Customer',
        UserRole.admin => 'Admin (Auditor)',
      };

  String get description => switch (this) {
        UserRole.manufacturer => 'Register products & generate QR codes',
        UserRole.distributor => 'Accept & transfer product ownership',
        UserRole.warehouse => 'Manage inventory & shipments',
        UserRole.retailer => 'Receive & verify goods',
        UserRole.customer => 'Track & verify your purchases',
        UserRole.admin => 'Full system compliance & security audit stream',
      };

  String get icon => switch (this) {
        UserRole.manufacturer => '🏭',
        UserRole.distributor => '🚛',
        UserRole.warehouse => '🏪',
        UserRole.retailer => '🏬',
        UserRole.customer => '👤',
        UserRole.admin => '🛡️',
      };

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }
}

// Permissions matrix
class RbacPermissions {
  static const Map<UserRole, Set<String>> _permissions = {
    UserRole.manufacturer: {
      'register_product',
      'generate_qr',
      'view_all_products',
      'view_journey',
      'transfer_product',
    },
    UserRole.distributor: {
      'view_assigned_products',
      'accept_transfer',
      'transfer_product',
      'view_journey',
      'update_shipment',
    },
    UserRole.warehouse: {
      'view_inventory',
      'update_inventory',
      'view_assigned_products',
      'view_journey',
      'view_ml_predictions',
    },
    UserRole.retailer: {
      'view_incoming_goods',
      'verify_qr',
      'accept_delivery',
      'view_journey',
    },
    UserRole.customer: {
      'scan_qr',
      'view_journey',
      'view_own_orders',
    },
    UserRole.admin: {
      'view_audit_logs',
      'view_security_telemetry',
      'view_all_products',
      'view_journey',
      'manage_ledger_compliance',
      'view_analytics',
    },
  };

  static bool can(UserRole role, String action) {
    return _permissions[role]?.contains(action) ?? false;
  }

  /// Strictly restricted to Admin accounts
  static bool canViewAuditLogs(UserRole role) => role == UserRole.admin;

  static bool canGenerateQr(UserRole role) =>
      role == UserRole.manufacturer;

  static bool canRegisterProduct(UserRole role) =>
      role == UserRole.manufacturer;

  static bool canTransfer(UserRole role) =>
      role == UserRole.manufacturer || role == UserRole.distributor;
}
