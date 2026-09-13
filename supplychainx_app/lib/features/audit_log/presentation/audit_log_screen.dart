import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/rbac/roles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/audit/audit_event.dart';
import '../../../app.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/audit_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AuditSeverity? _severityFilter;
  String _search = '';
  bool _isSwitchingAccount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user?.role == UserRole.admin) {
        ref.read(auditProvider.notifier).fetchLogs();
      }
    });
  }

  Future<void> _switchToAdminAccount() async {
    setState(() => _isSwitchingAccount = true);
    final ok = await ref.read(authProvider.notifier).login('admin@supply.com', 'demo1234');
    if (!mounted) return;
    setState(() => _isSwitchingAccount = false);
    if (ok) {
      ref.read(auditProvider.notifier).fetchLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switched to Enterprise Security Auditor (admin@supply.com)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isAdmin = user?.role == UserRole.admin;

    if (!isAdmin) {
      return _buildAccessDeniedView(context, user);
    }

    final auditState = ref.watch(auditProvider);
    final events = auditState.events;

    final filtered = events.where((e) {
      if (_severityFilter != null && e.severity != _severityFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final inDesc = e.description.toLowerCase().contains(q);
        final inUser = e.userEmail.toLowerCase().contains(q);
        final inType = e.type.label.toLowerCase().contains(q);
        final inMeta = e.metadata.values.any((v) => v.toString().toLowerCase().contains(q));
        if (!inDesc && !inUser && !inType && !inMeta) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            Text(
              'Security Telemetry & Audit Stream',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ADMIN STREAM',
                    style: GoogleFonts.inter(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Audit Logs',
            icon: auditState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.read(auditProvider.notifier).fetchLogs(),
          ),
          IconButton(
            tooltip: 'Home Portal',
            icon: const Icon(Icons.home_outlined, size: 20),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Ribbon
          _buildKpiRibbon(auditState, events),

          // Search & Filter Toolbar
          _buildFilterToolbar(),

          // Events Feed
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      return _buildEventCard(e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Access Denied View ───────────────────────────────────────────────────
  Widget _buildAccessDeniedView(BuildContext context, user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Security Telemetry & Audit Stream',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.shield_outlined, size: 32, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Access Restricted: Administrator Clearance Required',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Security audit streams, physical QR scan telemetry, and cryptographic ledger verification records are strictly governed and reserved exclusively for authorized Enterprise Security Auditors.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Session Identity Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _sessionRow('Current Account', user?.email ?? 'Unauthenticated'),
                        const SizedBox(height: 6),
                        _sessionRow('Current Role', (user?.role.label ?? 'Guest').toUpperCase()),
                        const SizedBox(height: 6),
                        _sessionRow('Required Role', 'ENTERPRISE AUDITOR (ADMIN)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1-Tap Switch to Auditor
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: _isSwitchingAccount ? 'Authorizing Auditor...' : 'Switch to Auditor Demo Account',
                      icon: Icons.admin_panel_settings_rounded,
                      isLoading: _isSwitchingAccount,
                      onPressed: _switchToAdminAccount,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.dashboard_outlined, size: 16),
                      label: const Text('Return to Workspace Dashboard'),
                      onPressed: () => context.go(dashboardRoute(user?.role ?? UserRole.customer)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
        Text(val, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── KPI Ribbon ───────────────────────────────────────────────────────────
  Widget _buildKpiRibbon(AuditState state, List<AuditEvent> events) {
    final total = events.length;
    final scans = events.where((e) => e.type == AuditEventType.qrScanned || e.type == AuditEventType.qrVerified || e.type == AuditEventType.qrTampered).length;
    final verified = events.where((e) => e.type == AuditEventType.qrVerified).length;
    final tampers = events.where((e) => e.type == AuditEventType.qrTampered || e.severity == AuditSeverity.critical).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _kpiChip('TOTAL LOGS', '$total', AppColors.textPrimary, Icons.analytics_outlined),
            const SizedBox(width: 8),
            _kpiChip('PHYSICAL SCANS', '$scans', AppColors.primary, Icons.qr_code_scanner_rounded),
            const SizedBox(width: 8),
            _kpiChip('VERIFIED VERDICTS', '$verified', AppColors.success, Icons.verified_rounded),
            const SizedBox(width: 8),
            _kpiChip('TAMPER ALERTS', '$tampers', tampers > 0 ? AppColors.danger : AppColors.textMuted, Icons.warning_amber_rounded),
            const SizedBox(width: 8),
            _kpiChip('RBAC ACCESS', 'ADMIN', const Color(0xFF10B981), Icons.lock_open_rounded),
          ],
        ),
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── Filter Toolbar ───────────────────────────────────────────────────────
  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search product serials, actors, telemetry...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButton<AuditSeverity?>(
              value: _severityFilter,
              underline: const SizedBox(),
              hint: Text('All Severities', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
              items: [
                DropdownMenuItem(value: null, child: Text('All Severities', style: GoogleFonts.inter(fontSize: 12))),
                ...AuditSeverity.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: GoogleFonts.inter(fontSize: 12)))),
              ],
              onChanged: (v) => setState(() => _severityFilter = v),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Event Card ───────────────────────────────────────────────────────────
  Widget _buildEventCard(AuditEvent e) {
    final hasMeta = e.metadata.isNotEmpty;
    final productId = e.metadata['product_id'] ?? '';
    final txHash = e.metadata['blockchain_hash'] ?? '';
    final location = e.metadata['location'] ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeverityBadge(severity: e.severity.name, small: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.type.label,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm:ss · dd MMM').format(e.timestamp),
                          style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.description,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Metadata Tag Strip
          if (hasMeta || productId.isNotEmpty || txHash.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (productId.isNotEmpty)
                  _metaBadge(Icons.tag_rounded, 'Product: $productId', AppColors.primary),
                if (e.userEmail.isNotEmpty)
                  _metaBadge(Icons.person_outline_rounded, '${e.userRole.label}: ${e.userEmail}', AppColors.textSecondary),
                if (location.isNotEmpty)
                  _metaBadge(Icons.location_on_outlined, location, AppColors.textMuted),
                if (txHash.isNotEmpty)
                  _metaBadge(Icons.link_rounded, 'Tx: ${txHash.length > 16 ? "${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 6)}" : txHash}', const Color(0xFF10B981)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyStateView(
          title: 'No Matching Audit Telemetry',
          message: _search.isNotEmpty
              ? 'No audit events or physical scan logs match "$_search". Try adjusting your search query or severity filter.'
              : 'Audit stream is clean. Live scan telemetry will appear here as physical consignments are scanned across the network.',
          icon: Icons.shield_outlined,
        ),
      ),
    );
  }
}
