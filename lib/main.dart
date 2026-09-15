import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/config/router/app_router.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_bloc.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_theme.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
      // Drawer 는 어느 화면에서 열려도 같은 배지 숫자를 봐야 한다 → 앱 최상단 1개(싱글턴).
      BlocProvider<AlertSummaryBloc>(create: (_) => getIt<AlertSummaryBloc>()),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Oklyn Mobile',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Pages now read their colors from the theme; the flip to
      // ThemeMode.system ships separately after a dark-mode review pass.
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    ),
  );
}
