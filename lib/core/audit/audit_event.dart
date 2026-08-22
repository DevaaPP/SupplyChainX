import '../rbac/roles.dart';

// Audit event types
enum AuditEventType {
  loginSuccess,
  loginFailed,
  logout,
  register,
  passwordChange,
  qrGenerated,
  qrScanned,
  qrVerified,
  qrTampered,
  productRegistered,
  productTransferred,
  roleChanged,
  sessionRevoked,
  twoFactorEnabled,
  twoFactorDisabled,
  unauthorized;

  String get label => switch (this) {
        AuditEventType.loginSuccess => 'Login Successful',
        AuditEventType.loginFailed => 'Login Failed',
        AuditEventType.logout => 'Logout',
        AuditEventType.register => 'User Registered',
        AuditEventType.passwordChange => 'Password Changed',
        AuditEventType.qrGenerated => 'QR Generated',
        AuditEventType.qrScanned => 'QR Scanned',
        AuditEventType.qrVerified => 'QR Verified ✓',
        AuditEventType.qrTampered => 'QR Tampered ✗',
        AuditEventType.productRegistered => 'Product Registered',
        AuditEventType.productTransferred => 'Product Transferred',
        AuditEventType.roleChanged => 'Role Changed',
        AuditEventType.sessionRevoked => 'Session Revoked',
        AuditEventType.twoFactorEnabled => '2FA Enabled',
        AuditEventType.twoFactorDisabled => '2FA Disabled',
        AuditEventType.unauthorized => 'Unauthorized Access Attempt',
      };

  AuditSeverity get defaultSeverity => switch (this) {
        AuditEventType.loginFailed => AuditSeverity.high,
        AuditEventType.qrTampered => AuditSeverity.critical,
        AuditEventType.unauthorized => AuditSeverity.critical,
        AuditEventType.roleChanged => AuditSeverity.high,
        AuditEventType.sessionRevoked => AuditSeverity.medium,
        AuditEventType.twoFactorDisabled => AuditSeverity.medium,
        AuditEventType.passwordChange => AuditSeverity.medium,
        AuditEventType.loginSuccess => AuditSeverity.low,
        AuditEventType.logout => AuditSeverity.low,
        _ => AuditSeverity.info,
      };
}

enum AuditSeverity {
  critical,
  high,
  medium,
  low,
  info;

  String get label => name.toUpperCase();
}

class AuditEvent {
  final String id;
  final AuditEventType type;
  final AuditSeverity severity;
  final String userId;
  final String userEmail;
  final UserRole userRole;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
        id: json['id'] as String,
        type: AuditEventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AuditEventType.loginSuccess,
        ),
        severity: AuditSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => AuditSeverity.info,
        ),
        userId: json['user_id'] as String,
        userEmail: json['user_email'] as String,
        userRole: UserRole.fromString(json['user_role'] as String),
        description: json['description'] as String,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  // Mock audit events for demo / UI development
  static List<AuditEvent> mockEvents() => [
        AuditEvent(
          id: '1',
          type: AuditEventType.qrTampered,
          severity: AuditSeverity.critical,
          userId: 'u1',
          userEmail: 'retailer@supply.com',
          userRole: UserRole.retailer,
          description: 'QR code tamper detected for product #PRD-8821',
          metadata: {'product_id': 'PRD-8821', 'signature': 'INVALID'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        AuditEvent(
          id: '2',
          type: AuditEventType.loginFailed,
          severity: AuditSeverity.high,
          userId: 'unknown',
          userEmail: 'hacker@example.com',
          userRole: UserRole.customer,
          description: 'Failed login attempt — 3 tries in 60s',
          metadata: {'ip': '192.168.1.45', 'attempts': 3},
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        AuditEvent(
          id: '3',
          type: AuditEventType.qrVerified,
          severity: AuditSeverity.info,
          userId: 'u5',
          userEmail: 'customer@mail.com',
          userRole: UserRole.customer,
          description: 'QR verified successfully for product #PRD-7743',
          metadata: {'product_id': 'PRD-7743'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        AuditEvent(
          id: '4',
          type: AuditEventType.productRegistered,
          severity: AuditSeverity.info,
          userId: 'u2',
          userEmail: 'mfg@supply.com',
          userRole: UserRole.manufacturer,
          description: 'New product registered: "Organic Rice 5kg" batch B-2024',
          metadata: {'product_id': 'PRD-8822', 'batch': 'B-2024'},
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AuditEvent(
          id: '5',
          type: AuditEventType.twoFactorEnabled,
          severity: AuditSeverity.medium,
          userId: 'u2',
          userEmail: 'mfg@supply.com',
          userRole: UserRole.manufacturer,
          description: 'Two-factor authentication enabled',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AuditEvent(
          id: '6',
          type: AuditEventType.productTransferred,
          severity: AuditSeverity.info,
          userId: 'u3',
          userEmail: 'dist@supply.com',
          userRole: UserRole.distributor,
          description: 'Product #PRD-7100 transferred to Warehouse-4',
          metadata: {'from': 'Distributor Hub-1', 'to': 'Warehouse-4'},
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        AuditEvent(
          id: '7',
          type: AuditEventType.loginSuccess,
          severity: AuditSeverity.low,
          userId: 'u1',
          userEmail: 'admin@supply.com',
          userRole: UserRole.manufacturer,
          description: 'Admin login via biometric',
          metadata: {'method': 'biometric', 'device': 'Pixel 8'},
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];
}
