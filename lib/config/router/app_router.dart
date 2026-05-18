import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_oklyn_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/pages/package_search_page.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/pages/package_detail_page.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/pages/product_detail_page.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/pages/product_register_page.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/pages/stock_in_out_page.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/pages/stock_search_page.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/pages/user_edit_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/dashboard_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/list_to_shop_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/not_found_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/notification_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/product_search_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/splash_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/user_manage_page.dart';
import 'package:flutter_oklyn_mobile/shared/pages/user_register_page.dart';

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
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashPage(),
      ),
    ),
    GoRoute(
      name: Routes.login,
      path: Routes.loginPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),
    GoRoute(
      name: Routes.dashboard,
      path: Routes.dashboardPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: DashboardPage(),
      ),
    ),
    GoRoute(
      name: Routes.listToShop,
      path: Routes.listToShopPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ListToShopPage(),
      ),
    ),
    GoRoute(
      name: Routes.notification,
      path: Routes.notificationPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: NotificationPage(),
      ),
    ),
    GoRoute(
      name: Routes.productRegister,
      path: Routes.productRegisterPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ProductRegisterPage(),
      ),
    ),
    GoRoute(
      name: Routes.productSearch,
      path: Routes.productSearchPath,
      pageBuilder: (context, state) => NoTransitionPage(
        child: ProductSearchPage(),
      ),
    ),
    GoRoute(
      name: Routes.productDetail,
      path: Routes.productDetailPath,
      pageBuilder: (context, state) {
        final productId = int.parse(state.pathParameters['productId']!);
        return NoTransitionPage(
          child: ProductDetailPage(productId: productId),
        );
      },
    ),
    GoRoute(
      name: Routes.stockInOut,
      path: Routes.stockInOutPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: StockInOutPage(),
      ),
    ),
    GoRoute(
      name: Routes.stockSearch,
      path: Routes.stockSearchPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: StockSearchPage(),
      ),
    ),
    GoRoute(
      name: Routes.userRegister,
      path: Routes.userRegisterPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: UserRegisterPage(),
      ),
    ),
    GoRoute(
      name: Routes.userManage,
      path: Routes.userManagePath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: UserManagePage(),
      ),
    ),
    GoRoute(
      name: Routes.userEdit,
      path: Routes.userEditPath,
      pageBuilder: (context, state) {
        final user = state.extra as User;
        return NoTransitionPage(
          child: UserEditPage(user: user),
        );
      },
    ),
    GoRoute(
      name: Routes.packageSearch,
      path: Routes.packageSearchPath,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BlocProvider<PackageListBloc>(
          create: (context) => GetIt.instance<PackageListBloc>(),
          child: const PackageSearchPage(),
        ),
      ),
    ),
    GoRoute(
      name: Routes.packageDetail,
      path: Routes.packageDetailPath,
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return NoTransitionPage(
          child: BlocProvider<PackageDetailBloc>(
            create: (context) => GetIt.instance<PackageDetailBloc>()..add(LoadPackageDetail(id)),
            child: PackageDetailPage(packageId: id),
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.notFound,
      path: Routes.notFoundPath,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: NotFoundPage(),
      ),
    ),
  ];
}
