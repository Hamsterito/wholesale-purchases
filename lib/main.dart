import 'package:flutter/material.dart';
import 'login_screen/login.dart';
import 'services/app_settings.dart';
import 'services/auth_storage.dart';
import 'widgets/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.init();
  await AuthStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6288D5);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Marketplace App',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(primaryColor),
          darkTheme: _buildDarkTheme(primaryColor),
          themeMode: themeMode,
          home: AuthStorage.isRemembered
              ? const MainNavigation()
              : const LoginPage(),
        );
      },
    );
  }

  ThemeData _buildLightTheme(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(seedColor: primaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF3F9FF),
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
