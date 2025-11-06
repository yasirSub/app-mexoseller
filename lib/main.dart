// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'pages/home_page.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Mexo Seller',
          // Light theme (kept for completeness) and a dark theme which will be used
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            // Ensure text is black on light theme so it's visible on light backgrounds
            textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
            useMaterial3: false,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1B2E),
              foregroundColor: Colors.white,
              elevation: 1,
            ),
            // text colors
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            useMaterial3: false,
          ),
          themeMode: themeMode,
          initialRoute: AppRoutes.login,
          onGenerateRoute: RouteGenerator.generate,
        );
      },
    );
  }
}
