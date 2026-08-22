import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/dashboard/manufacturer_dashboard.dart';
import 'features/dashboard/distributor_dashboard.dart';
import 'features/dashboard/warehouse_dashboard.dart';
import 'features/dashboard/retailer_dashboard.dart';
import 'features/dashboard/customer_dashboard.dart';
import 'features/product/presentation/register_product_screen.dart';
import 'features/qr_security/presentation/qr_scan_screen.dart';
import 'features/qr_security/presentation/qr_verify_result_screen.dart';
import 'features/product/presentation/product_detail_screen.dart';
import 'features/audit_log/presentation/audit_log_screen.dart';
import 'features/security_panel/presentation/security_settings_screen.dart';
import 'features/ai_assistant/presentation/assistant_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'core/rbac/roles.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/' ||
          state.matchedLocation == '/verify' ||
          state.matchedLocation.startsWith('/verify/');

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return _dashboardRoute(authState.user!.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Dashboards by role
      GoRoute(path: '/dashboard/manufacturer', builder: (_, __) => const ManufacturerDashboard()),
      GoRoute(path: '/dashboard/distributor', builder: (_, __) => const DistributorDashboard()),
      GoRoute(path: '/dashboard/warehouse', builder: (_, __) => const WarehouseDashboard()),
      GoRoute(path: '/dashboard/retailer', builder: (_, __) => const RetailerDashboard()),
      GoRoute(path: '/dashboard/customer', builder: (_, __) => const CustomerDashboard()),

      // Product
      GoRoute(path: '/product/register', builder: (_, __) => const RegisterProductScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // QR
      GoRoute(path: '/qr/scan', builder: (_, __) => const QrScanScreen()),
      GoRoute(
        path: '/verify',
        builder: (_, state) {
          final productId = state.uri.queryParameters['id'];
          return QrVerifyResultScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/verify/:id',
        builder: (_, state) => QrVerifyResultScreen(productId: state.pathParameters['id']),
      ),

      // Features
      GoRoute(path: '/audit', builder: (_, __) => const AuditLogScreen()),
      GoRoute(path: '/security', builder: (_, __) => const SecuritySettingsScreen()),
      GoRoute(path: '/assistant', builder: (_, __) => const AssistantScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    ],
  );
});

String _dashboardRoute(UserRole role) => switch (role) {
      UserRole.manufacturer => '/dashboard/manufacturer',
      UserRole.distributor => '/dashboard/distributor',
      UserRole.warehouse => '/dashboard/warehouse',
      UserRole.retailer => '/dashboard/retailer',
      UserRole.customer => '/dashboard/customer',
    };

class SupplyChainXApp extends ConsumerWidget {
  const SupplyChainXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SupplyX',
      theme: AppTheme.enterprise,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
