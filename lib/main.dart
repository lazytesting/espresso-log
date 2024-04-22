import 'package:espresso_log/router.dart';
import 'package:espresso_log/scale_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;
void main() {
  getIt.registerSingleton<ScaleService>(ScaleService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 84, 48, 134))),
      routerConfig: AppRouter().router,
    );
  }
}
