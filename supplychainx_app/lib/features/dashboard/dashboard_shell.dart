import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/rbac/roles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';

/// Clean Industrial Control Room Dashboard Shell with Adaptive Layout
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _logout() {
    ref.read(authProvider.notifier).logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final width = MediaQuery.of(context).size.width;

    if (width >= 1024) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildDesktop(user),
      );
    } else if (width >= 640) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildTablet(user),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _buildMobileDrawer(user),
        body: _buildMobile(user),
      );
    }
  }

  // ─── Desktop Layout with Full 220px Dark Sidebar ─────────────────────────────
  Widget _buildDesktop(UserModel user) {
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
              InkWell(
                onTap: () => context.go('/'),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SupplyChainX',
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
              _sidebarLink(Icons.home_outlined, 'Home Portal', () => context.go('/')),
              _sidebarLink(Icons.model_training_rounded, 'ML Delay Predictor', () => context.push('/ml-studio')),
              _sidebarLink(Icons.smart_toy_outlined, 'AI Assistant', () => context.push('/assistant')),
              _sidebarLink(Icons.bar_chart_outlined, 'Analytics', () => context.push('/analytics')),
              _sidebarLink(Icons.shield_outlined, 'Security Settings', () => context.push('/security')),
              _sidebarLink(
                user.role == UserRole.admin ? Icons.security_outlined : Icons.lock_outline_rounded,
                user.role == UserRole.admin ? 'Audit Stream (Live)' : 'Audit Stream [Admin Only]',
                () => context.push('/audit'),
              ),

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
                      'SupplyChainX / ${user.role.label}',
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

  // ─── Tablet Layout with Compact 68px Icon Rail ──────────────────────────────
  Widget _buildTablet(UserModel user) {
    return Row(
      children: [
        // Slim Icon Rail
        Container(
          width: 68,
          color: AppColors.sidebar,
          child: Column(
            children: [
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.go('/'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/logo.png', width: 28, height: 28),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 8),

              // Tab Icons
              Expanded(
                child: ListView.builder(
                  itemCount: widget.tabs.length,
                  itemBuilder: (_, i) {
                    final tab = widget.tabs[i];
                    final selected = _currentIndex == i;
                    return Tooltip(
                      message: tab.label,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.sidebarActive : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            selected ? tab.activeIcon : tab.icon,
                            color: selected ? AppColors.primaryBorder : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _currentIndex = i),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Color(0xFF1E293B), height: 1),
              // Quick tool popups
              PopupMenuButton<String>(
                icon: const Icon(Icons.apps_rounded, color: Color(0xFF94A3B8), size: 20),
                tooltip: 'System Tools',
                color: AppColors.surfaceElevated,
                onSelected: (val) {
                  if (val == 'home') context.go('/');
                  if (val == 'ml') context.push('/ml-studio');
                  if (val == 'ai') context.push('/assistant');
                  if (val == 'analytics') context.push('/analytics');
                  if (val == 'security') context.push('/security');
                  if (val == 'audit') context.push('/audit');
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'home', child: Text('Home Portal', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'ml', child: Text('ML Studio', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'ai', child: Text('AI Assistant', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'analytics', child: Text('Analytics', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'security', child: Text('Security Settings', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'audit', child: Text('Audit Logs', style: TextStyle(fontSize: 13))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                tooltip: 'Sign Out',
                onPressed: _logout,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.tabs[_currentIndex].label,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    RoleBadge(role: user.role.label, small: true),
                    const Spacer(),
                    if (widget.actions != null) ...widget.actions!,
                    IconButton(
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: AppColors.textSecondary),
                      onPressed: () => context.go('/'),
                      tooltip: 'Public Portal',
                    ),
                  ],
                ),
              ),
              Expanded(child: widget.pages[_currentIndex]),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mobile Layout with Top App Bar, System Drawer & Bottom Navigation ──────
  Widget _buildMobile(UserModel user) {
    return Column(
      children: [
        // Compact App Bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            left: 10,
            right: 12,
            bottom: 6,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22, color: AppColors.textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'System Menu',
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SupplyChainX',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(child: RoleBadge(role: user.role.label, small: true)),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: () => context.go('/'),
                tooltip: 'Public Portal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: widget.pages[_currentIndex]),
        // Compact Bottom Navigation
        NavigationBar(
          height: 58,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: widget.tabs
              .map((tab) => NavigationDestination(
                    icon: Icon(tab.icon, size: 20),
                    selectedIcon: Icon(tab.activeIcon, size: 20, color: AppColors.primary),
                    label: _compactTabLabel(tab.label),
                    tooltip: tab.label,
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _compactTabLabel(String fullLabel) {
    final lower = fullLabel.toLowerCase().trim();
    if (lower.contains('batch')) return 'Batches';
    if (lower.contains('register')) return 'Register';
    if (lower.contains('transfer')) return 'Transfer';
    if (lower.contains('audit') || lower.contains('stream') || lower.contains('history')) return 'Audit';
    if (lower.contains('received')) return 'Received';
    if (lower.contains('location')) return 'Location';
    if (lower.contains('incoming')) return 'Incoming';
    if (lower.contains('inventory') || lower.contains('stock')) return 'Stock';
    if (lower.contains('sold') || lower.contains('sell')) return 'Sell';
    if (lower.contains('verify')) return 'Verify';
    if (lower.contains('order')) return 'Orders';
    if (lower.contains('product')) return 'Products';
    return fullLabel.split(' ').first;
  }

  // ─── Mobile Slide-out Operations & System Tools Drawer ───────────────────────
  Widget _buildMobileDrawer(UserModel user) {
    return Drawer(
      backgroundColor: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryBorder,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.label,
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab shortcuts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'WORKFLOW TABS',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ),
            ...widget.tabs.asMap().entries.map((entry) {
              final idx = entry.key;
              final tab = entry.value;
              final selected = _currentIndex == idx;
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = idx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: selected ? AppColors.sidebarActive : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(selected ? tab.activeIcon : tab.icon, color: selected ? AppColors.primaryBorder : const Color(0xFF94A3B8), size: 16),
                      const SizedBox(width: 10),
                      Text(
                        tab.label,
                        style: GoogleFonts.inter(color: selected ? Colors.white : const Color(0xFFCBD5E1), fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'SYSTEM & TOOLS',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ),
            _sidebarLink(Icons.home_outlined, 'Home Portal', () {
              Navigator.pop(context);
              context.go('/');
            }),
            _sidebarLink(Icons.model_training_rounded, 'ML Delay Predictor', () {
              Navigator.pop(context);
              context.push('/ml-studio');
            }),
            _sidebarLink(Icons.smart_toy_outlined, 'AI Assistant', () {
              Navigator.pop(context);
              context.push('/assistant');
            }),
            _sidebarLink(Icons.bar_chart_outlined, 'Analytics', () {
              Navigator.pop(context);
              context.push('/analytics');
            }),
            _sidebarLink(Icons.shield_outlined, 'Security Settings', () {
              Navigator.pop(context);
              context.push('/security');
            }),
            _sidebarLink(
              user.role == UserRole.admin ? Icons.security_outlined : Icons.lock_outline_rounded,
              user.role == UserRole.admin ? 'Audit Stream (Live)' : 'Audit Stream [Admin Only]',
              () {
                Navigator.pop(context);
                context.push('/audit');
              },
            ),

            const Spacer(),
            const Divider(color: Color(0xFF1E293B), height: 1),
            _sidebarLink(Icons.logout_rounded, 'Sign Out', () {
              Navigator.pop(context);
              _logout();
            }, isDanger: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
}
