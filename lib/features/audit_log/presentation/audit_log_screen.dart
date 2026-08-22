import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
        if (_severityFilter != null && e.severity != _severityFilter) return false;
        if (_search.isNotEmpty &&
            !e.description.toLowerCase().contains(_search.toLowerCase()) &&
            !e.userEmail.toLowerCase().contains(_search.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
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
            Text('Security Telemetry & Audit Feed', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(4)),
              child: Text('LIVE STREAM', style: GoogleFonts.inter(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search audit events, users, signatures...',
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<AuditSeverity?>(
                  value: _severityFilter,
                  underline: const SizedBox(),
                  hint: Text('All Severities', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Severities', style: GoogleFonts.inter(fontSize: 12))),
                    ...AuditSeverity.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: GoogleFonts.inter(fontSize: 12)))),
                  ],
                  onChanged: (v) => setState(() => _severityFilter = v),
                ),
              ],
            ),
          ),

          // Events Table / List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final e = _filtered[i];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      SeverityBadge(severity: e.severity.name, small: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.type.label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(e.description, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(e.userEmail, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                          Text(
                            '${DateTime.now().difference(e.timestamp).inMinutes}m ago',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
