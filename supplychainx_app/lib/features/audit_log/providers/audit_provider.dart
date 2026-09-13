import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/audit/audit_event.dart';
import '../../../core/rbac/roles.dart';
import '../../auth/providers/auth_provider.dart';

class AuditState {
  final List<AuditEvent> events;
  final bool isLoading;
  final String? error;
  final int totalScans;
  final int verifiedCount;
  final int tamperCount;

  const AuditState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.totalScans = 0,
    this.verifiedCount = 0,
    this.tamperCount = 0,
  });

  AuditState copyWith({
    List<AuditEvent>? events,
    bool? isLoading,
    String? error,
    int? totalScans,
    int? verifiedCount,
    int? tamperCount,
  }) {
    return AuditState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalScans: totalScans ?? this.totalScans,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      tamperCount: tamperCount ?? this.tamperCount,
    );
  }
}

class AuditNotifier extends StateNotifier<AuditState> {
  final ApiClient _apiClient;
  final Ref _ref;

  AuditNotifier(this._apiClient, this._ref) : super(AuditState(events: AuditEvent.mockEvents())) {
    fetchLogs();
  }

  Future<void> fetchLogs({String? severity}) async {
    final auth = _ref.read(authProvider);
    if (auth.user?.role != UserRole.admin) {
      state = state.copyWith(
        error: 'Access Denied: Security audit stream requires Administrator authorization.',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _apiClient.get(
        '${ApiEndpoints.baseUrl}/audit/logs',
        queryParameters: severity != null ? {'severity': severity} : null,
      );

      if (res != null && res.statusCode == 200 && res.data is List) {
        final List list = res.data;
        final fetched = list.map((item) {
          final m = item as Map<String, dynamic>;
          final eventTypeStr = (m['event_type'] as String? ?? '').toLowerCase();
          AuditEventType type = AuditEventType.qrVerified;
          if (eventTypeStr.contains('tamper')) {
            type = AuditEventType.qrTampered;
          } else if (eventTypeStr.contains('scan')) {
            type = AuditEventType.qrScanned;
          } else if (eventTypeStr.contains('register')) {
            type = AuditEventType.productRegistered;
          } else if (eventTypeStr.contains('transfer')) {
            type = AuditEventType.productTransferred;
          } else if (eventTypeStr.contains('login')) {
            type = AuditEventType.loginSuccess;
          }

          final sStr = (m['severity'] as String? ?? '').toLowerCase();
          final sev = switch (sStr) {
            'critical' => AuditSeverity.critical,
            'high' => AuditSeverity.high,
            'medium' => AuditSeverity.medium,
            'low' => AuditSeverity.low,
            _ => AuditSeverity.info,
          };

          return AuditEvent(
            id: m['id'] as String? ?? 'aud-${DateTime.now().millisecondsSinceEpoch}',
            type: type,
            severity: sev,
            userId: m['actor_id'] as String? ?? 'unknown',
            userEmail: m['actor_email'] as String? ?? (m['actor_role'] ?? 'system'),
            userRole: UserRole.fromString(m['actor_role'] as String? ?? 'admin'),
            description: m['description'] as String? ?? 'Audit Event',
            timestamp: m['timestamp'] != null
                ? DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();

        final scans = fetched.where((e) => e.type == AuditEventType.qrScanned || e.type == AuditEventType.qrVerified || e.type == AuditEventType.qrTampered).length;
        final verified = fetched.where((e) => e.type == AuditEventType.qrVerified).length;
        final tampers = fetched.where((e) => e.type == AuditEventType.qrTampered).length;

        state = state.copyWith(
          events: fetched,
          isLoading: false,
          totalScans: scans,
          verifiedCount: verified,
          tamperCount: tampers,
        );
        return;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false);
  }

  Future<String> logScan({
    required String productId,
    required String actorRole,
    required String actorName,
    required String actorEmail,
    required String verificationStatus,
    String? action,
    String? location,
    String? blockchainHash,
  }) async {
    final now = DateTime.now();
    final logId = 'SCAN-${now.millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    final isTamper = verificationStatus.toUpperCase().contains('TAMPER') || verificationStatus.toUpperCase().contains('FAIL');
    final isUnregistered = verificationStatus.toUpperCase().contains('NOT_FOUND') || verificationStatus.toUpperCase().contains('UNREGISTERED');

    final localEvent = AuditEvent(
      id: logId,
      type: isTamper ? AuditEventType.qrTampered : (isUnregistered ? AuditEventType.unauthorized : AuditEventType.qrVerified),
      severity: isTamper ? AuditSeverity.critical : (isUnregistered ? AuditSeverity.high : AuditSeverity.info),
      userId: actorName,
      userEmail: actorEmail,
      userRole: UserRole.fromString(actorRole),
      description: 'Physical QR Verification Scan for $productId by $actorName ($actorRole) — Status: $verificationStatus',
      metadata: {
        'product_id': productId,
        'action': action ?? 'Scan',
        'location': location ?? 'Terminal',
        'blockchain_hash': blockchainHash ?? '0xPending',
      },
      timestamp: now,
    );

    state = state.copyWith(
      events: [localEvent, ...state.events],
      totalScans: state.totalScans + 1,
      verifiedCount: state.verifiedCount + (isTamper || isUnregistered ? 0 : 1),
      tamperCount: state.tamperCount + (isTamper ? 1 : 0),
    );

    try {
      await _apiClient.post(
        '${ApiEndpoints.baseUrl}/audit/scan-log',
        data: {
          'product_id': productId,
          'actor_id': actorName,
          'actor_email': actorEmail,
          'actor_role': actorRole,
          'verification_status': verificationStatus,
          'action': action,
          'location': location,
          'blockchain_hash': blockchainHash,
        },
      );
    } catch (_) {}

    return logId;
  }
}

final auditProvider = StateNotifierProvider<AuditNotifier, AuditState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuditNotifier(apiClient, ref);
});
