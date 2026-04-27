import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/config/router/app_router.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Flutter Oklyn Mobile',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    routerConfig: AppRouter.router,
  );
}
