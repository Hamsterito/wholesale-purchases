import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login_screen/login.dart';
import 'services/app_logger.dart';
import 'services/app_settings.dart';
import 'services/auth_storage.dart';
import 'widgets/main_navigation.dart';

// Главная функция приложения Flutter
// Важно: WidgetsFlutterBinding.ensureInitialized() ДО любых async операций
Future<void> main() async {
  // Инициализация Flutter bindings ДО любых async операций
  // Это предотвращает ошибки с Binding/debugCheckZone
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка обработки ошибок
  FlutterError.onError = (details) {
    AppLogger.error(
      'Unhandled Flutter framework error',
      scope: 'startup',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Unhandled platform error',
      scope: 'startup',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  // Инициализация приложения с обработкой ошибок
  try {
    AppLogger.info('Application initialization started', scope: 'startup');

    // Все async операции ДО runApp - это критично для предотвращения ошибок зоны
    await AppSettings.init();
    AppLogger.info('Application settings initialized', scope: 'startup');

    await AuthStorage.init();
    AppLogger.info(
      'Auth storage initialized: remembered=${AuthStorage.isRemembered}, userId=${AuthStorage.userId}',
      scope: 'startup',
    );

    // Запуск приложения в защищенной зоне после полной инициализации
    runZonedGuarded(
      () => runApp(const MyApp()),
      (error, stackTrace) {
        AppLogger.error(
          'Unhandled zone error',
          scope: 'startup',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Application initialization failed',
      scope: 'startup',
      error: error,
      stackTrace: stackTrace,
    );
    // В случае критической ошибки запускаем приложение с fallback экраном
    runZonedGuarded(
      () => runApp(const _ErrorApp()),
      (error, stackTrace) {
        AppLogger.error(
          'Fallback app error',
          scope: 'startup',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}

/// Fallback приложение в случае критической ошибки инициализации
class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ошибка запуска',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ошибка запуска приложения',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Попробуйте перезапустить приложение',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          title: 'Оптовые закупки',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ru'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('en'), Locale('kk')],
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
    ).copyWith(primary: primaryColor, onPrimary: Colors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFEAF3FF),
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
    ).copyWith(primary: primaryColor, onPrimary: Colors.white);

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
