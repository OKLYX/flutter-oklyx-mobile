import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/config/router/app_router.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
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
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Oklyn Mobile',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Kept on light until hardcoded Colors.white/black usages are themed.
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    ),
  );
}
