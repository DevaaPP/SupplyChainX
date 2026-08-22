import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/audit/audit_event.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AuditSeverity? _severityFilter;
  String _search = '';
  List<AuditEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _events = AuditEvent.mockEvents();
  }

  List<AuditEvent> get _filtered => _events.where((e) {
        if (_severityFilter != null && e.severity != _severityFilter) {
          return false;
        }
        if (_search.isNotEmpty &&
            !e.description.toLowerCase().contains(_search.toLowerCase()) &&
            !e.userEmail.toLowerCase().contains(_search.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            const Text('Security Audit Log'),
            const SizedBox(width: 10),
            PulseDot(color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('LIVE',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                setState(() => _events = AuditEvent.mockEvents()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                _statChip('All', _events.length, AppColors.primary),
                const SizedBox(width: 8),
                _statChip(
                    'Critical',
                    _events
                        .where((e) => e.severity == AuditSeverity.critical)
                        .length,
                    AppColors.critical),
                const SizedBox(width: 8),
                _statChip(
                    'High',
                    _events
                        .where((e) => e.severity == AuditSeverity.high)
                        .length,
                    AppColors.high),
                const Spacer(),
                // Export button
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Export', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 1),

          // Search + Filter bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search,
                              color: AppColors.textMuted, size: 18),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) =>
                                setState(() => _search = v),
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText:
                                  'Search events, emails...',
                              hintStyle:
                                  TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Severity filter
                PopupMenuButton<AuditSeverity?>(
                  color: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _severityFilter != null
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _severityFilter?.label ?? 'Filter',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (v) =>
                      setState(() => _severityFilter = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Severities',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ),
                    ...AuditSeverity.values.map((s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              SeverityBadge(severity: s.name, small: true),
                              const SizedBox(width: 8),
                              Text(s.label,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(
                    message: 'No events match your filters',
                    icon: Icons.shield_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _AuditEventTile(event: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) => GestureDetector(
        onTap: () => setState(() => _severityFilter =
            label == 'All'
                ? null
                : AuditSeverity.values
                    .firstWhere((s) => s.label == label.toUpperCase(),
                        orElse: () => AuditSeverity.info)),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$count $label',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _AuditEventTile extends StatelessWidget {
  final AuditEvent event;
  const _AuditEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = switch (event.severity) {
      AuditSeverity.critical => AppColors.critical,
      AuditSeverity.high => AppColors.high,
      AuditSeverity.medium => AppColors.medium,
      AuditSeverity.low => AppColors.low,
      AuditSeverity.info => AppColors.info,
    };

    return GlassCard(
      borderColor: color.withOpacity(0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity indicator
          Container(
            width: 4,
            height: 60,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_eventIcon(event.type), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.type.label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    SeverityBadge(severity: event.severity.name, small: true),
                  ],
                ),
                const SizedBox(height: 3),
                Text(event.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RoleBadge(role: event.userRole.label, small: true),
                    const SizedBox(width: 8),
                    Text(event.userEmail,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    const Spacer(),
                    Text(_fmtTime(event.timestamp),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(AuditEventType type) => switch (type) {
        AuditEventType.loginSuccess => Icons.login_rounded,
        AuditEventType.loginFailed => Icons.no_accounts_rounded,
        AuditEventType.logout => Icons.logout_rounded,
        AuditEventType.qrGenerated => Icons.qr_code_rounded,
        AuditEventType.qrScanned => Icons.qr_code_scanner_rounded,
        AuditEventType.qrVerified => Icons.verified_rounded,
        AuditEventType.qrTampered => Icons.dangerous_rounded,
        AuditEventType.productRegistered => Icons.inventory_2_rounded,
        AuditEventType.productTransferred => Icons.swap_horiz_rounded,
        AuditEventType.unauthorized => Icons.block_rounded,
        AuditEventType.twoFactorEnabled => Icons.security_rounded,
        AuditEventType.twoFactorDisabled => Icons.security_rounded,
        AuditEventType.sessionRevoked => Icons.devices_rounded,
        _ => Icons.shield_rounded,
      };

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
