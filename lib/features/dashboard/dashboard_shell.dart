import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/rbac/roles.dart';

/// Clean Industrial Control Room Dashboard Shell
class DashboardShell extends ConsumerStatefulWidget {
  final String title;
  final List<DashboardTab> tabs;
  final List<Widget> pages;
  final List<Widget>? actions;

  const DashboardShell({
    super.key,
    required this.title,
    required this.tabs,
    required this.pages,
    this.actions,
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class DashboardTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const DashboardTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _currentIndex = 0;

  void _logout() {
    ref.read(authProvider.notifier).logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final isWide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWide(user) : _buildMobile(user),
    );
  }

  // ─── Desktop / Web Layout with Compact Dark Sidebar ────────────────────────
  Widget _buildWide(UserModel user) {
    final todayStr = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());

    return Row(
      children: [
        // Compact Sidebar
        Container(
          width: 220,
          color: AppColors.sidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.hub_outlined, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SupplyX',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.name.toUpperCase().substring(0, 3),
                        style: GoogleFonts.inter(
                          color: AppColors.primaryBorder,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // User Info
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBorder,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.role.label,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'OPERATIONS',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: widget.tabs.length,
                  itemBuilder: (_, i) {
                    final tab = widget.tabs[i];
                    final selected = _currentIndex == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = i),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.sidebarActive : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected ? tab.activeIcon : tab.icon,
                                color: selected ? AppColors.primaryBorder : const Color(0xFF94A3B8),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                tab.label,
                                style: GoogleFonts.inter(
                                  color: selected ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Color(0xFF1E293B), height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'SYSTEM & TOOLS',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Auxiliary Tools
              _sidebarLink(Icons.shield_outlined, 'Security Settings', () => context.push('/security')),
              _sidebarLink(Icons.bar_chart_outlined, 'Analytics', () => context.push('/analytics')),
              _sidebarLink(Icons.smart_toy_outlined, 'AI Assistant', () => context.push('/assistant')),
              if (user.role == UserRole.manufacturer)
                _sidebarLink(Icons.security_outlined, 'Audit Logs', () => context.push('/audit')),

              const Divider(color: Color(0xFF1E293B), height: 1),
              _sidebarLink(Icons.logout_rounded, 'Sign Out', _logout, isDanger: true),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Main Control Area
        Expanded(
          child: Column(
            children: [
              // Operations Top Bar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    // Breadcrumbs
                    Text(
                      'SupplyX / ${user.role.label}',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const Text(' / ', style: TextStyle(color: AppColors.cardBorderStrong)),
                    Text(
                      widget.tabs[_currentIndex].label,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('LIVE SYSTEM', style: GoogleFonts.inter(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date & Actions
                    Text(
                      todayStr,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    if (widget.actions != null) ...widget.actions!,
                    IconButton(
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: AppColors.textSecondary),
                      onPressed: () => context.go('/'),
                      tooltip: 'Public Portal',
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(child: widget.pages[_currentIndex]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarLink(IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isDanger ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile Bottom Navigation ──────────────────────────────────────────────
  Widget _buildMobile(UserModel user) {
    return Column(
      children: [
        // Compact App Bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 12,
            bottom: 8,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.hub_outlined, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'SupplyX',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              RoleBadge(role: user.role.label, small: true),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
                onPressed: _logout,
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: widget.pages[_currentIndex]),
        // Compact Bottom Nav
        NavigationBar(
          height: 56,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: widget.tabs
              .map((tab) => NavigationDestination(
                    icon: Icon(tab.icon, size: 20),
                    selectedIcon: Icon(tab.activeIcon, size: 20, color: AppColors.primary),
                    label: tab.label,
                  ))
              .toList(),
        ),
      ],
    );
  }
}
