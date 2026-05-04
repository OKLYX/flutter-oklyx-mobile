import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/dashboard_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/list_to_shop_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/not_found_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/notification_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/splash_page.dart';

import 'routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _goRouter;

  static final GoRouter _goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splashPath,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: _routes,
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  static String? _handleRedirect(context, state) =>
      null; // TODO: Phase 5 - Add authentication check

  static final List<RouteBase> _routes = [
    GoRoute(
      name: Routes.splash,
      path: Routes.splashPath,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      name: Routes.login,
      path: Routes.loginPath,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      name: Routes.dashboard,
      path: Routes.dashboardPath,
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      name: Routes.listToShop,
      path: Routes.listToShopPath,
      builder: (context, state) => const ListToShopPage(),
    ),
    GoRoute(
      name: Routes.notification,
      path: Routes.notificationPath,
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      name: Routes.notFound,
      path: Routes.notFoundPath,
      builder: (context, state) => const NotFoundPage(),
    ),
  ];
}
