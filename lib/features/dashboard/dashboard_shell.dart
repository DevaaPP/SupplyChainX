import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../core/rbac/roles.dart';

/// Shared dashboard shell used by all 5 role dashboards.
/// Provides: top app bar, side nav (web), bottom nav (mobile), logout.
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

  const DashboardTab({required this.icon, required this.activeIcon, required this.label});
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
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWide(user) : _buildMobile(user),
    );
  }

  // ─── Wide (Web) Layout with side nav ─────────────────────────────────────
  Widget _buildWide(UserModel user) {
    return Row(
      children: [
        // Side nav
        Container(
          width: 220,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SupplyChainX',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),

              // User info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: roleColor(user.role).withOpacity(0.2),
                      child: Text(user.displayName[0], style: TextStyle(color: roleColor(user.role), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text(user.role.label,
                              style: TextStyle(color: roleColor(user.role), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 8),

              // Nav items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: widget.tabs.length,
                  itemBuilder: (_, i) {
                    final tab = widget.tabs[i];
                    final selected = _currentIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryDim : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? tab.activeIcon : tab.icon,
                              color: selected ? AppColors.primary : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tab.label,
                              style: TextStyle(
                                color: selected ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom nav actions
              const Divider(color: AppColors.cardBorder, height: 1),
              _sideNavAction(Icons.shield_outlined, 'Security', () => context.push('/security')),
              _sideNavAction(Icons.bar_chart_rounded, 'Analytics', () => context.push('/analytics')),
              _sideNavAction(Icons.smart_toy_outlined, 'AI Assistant', () => context.push('/assistant')),
              if (user.role == UserRole.manufacturer)
                _sideNavAction(Icons.security_rounded, 'Audit Logs', () => context.push('/audit')),
              _sideNavAction(Icons.logout_rounded, 'Logout', _logout, color: AppColors.critical),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: Column(
            children: [
              // Top bar
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Text(widget.tabs[_currentIndex].label,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (widget.actions != null) ...widget.actions!,
                    const SizedBox(width: 8),
                    // Home link
                    IconButton(
                      icon: const Icon(Icons.home_outlined, color: AppColors.textMuted),
                      onPressed: () => context.go('/'),
                      tooltip: 'Home',
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(child: widget.pages[_currentIndex]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sideNavAction(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color ?? AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ─── Mobile Layout with bottom nav ───────────────────────────────────────
  Widget _buildMobile(UserModel user) {
    return Column(
      children: [
        // App bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 8,
            bottom: 8,
          ),
          color: AppColors.surface,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: roleColor(user.role).withOpacity(0.2),
                child: Text(user.displayName[0],
                    style: TextStyle(color: roleColor(user.role), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(user.role.label, style: TextStyle(color: roleColor(user.role), fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
                onPressed: _logout,
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: widget.pages[_currentIndex]),
        // Bottom nav
        NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: widget.tabs.map((tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              )).toList(),
        ),
      ],
    );
  }
}
