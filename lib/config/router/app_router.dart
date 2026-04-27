import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/home_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/not_found_page.dart';
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
      name: Routes.home,
      path: Routes.homePath,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      name: Routes.notFound,
      path: Routes.notFoundPath,
      builder: (context, state) => const NotFoundPage(),
    ),
  ];
}
