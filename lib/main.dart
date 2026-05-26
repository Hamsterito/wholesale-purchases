import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_project/login_screen/login.dart';
import 'package:flutter_project/services/app_logger.dart';
import 'package:flutter_project/services/store/app_settings.dart';
import 'package:flutter_project/services/storage/auth_storage.dart';
import 'package:flutter_project/services/store/favorites_store.dart';
import 'package:flutter_project/services/notification_service.dart';
import 'package:flutter_project/services/storage/shared_prefs_provider.dart';
import 'package:flutter_project/services/store/templates_store.dart';
import 'package:flutter_project/widgets/navigation/main_navigation.dart';
import 'package:flutter_project/widgets/messages/top_message.dart';
import 'package:flutter_project/theme/app_color_palette.dart';

// Главная функция приложения Flutter
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

        // Прогреваем SharedPreferences до первой записи/чтения, чтобы
        // дальнейшая инициализация (AppSettings, AuthStorage и т.д.) шла
        // через общий кэш без повторного канала к платформе.
        await SharedPrefsProvider.warmup();
        AppLogger.info('SharedPrefsProvider warmed up', scope: 'startup');

        // Откладываем первый кадр, пока не прогреются шрифты - иначе на web
        // CanvasKit рисует запасным шрифтом и иконки/кнопки получают неверные
        // метрики, которые остаются до hot restart
        WidgetsBinding.instance.deferFirstFrame();
        await _warmupFonts();
        WidgetsBinding.instance.allowFirstFrame();

        // Первая волна инициализации идёт параллельно: dotenv не зависит
        // от Prefs вовсе, AppSettings/AuthStorage/FavoritesStore читают Prefs
        // независимо друг от друга. Каждая safeXxx ловит свои ошибки внутри,
        // чтобы Future.wait не падал на первой неудаче.
        await Future.wait([
          _safeDotenvLoad(),
          _safeAppSettingsInit(),
          _safeAuthStorageInit(),
          _safeFavoritesLoad(),
        ]);

        // Вторая волна последовательная: TemplatesStore и NotificationService
        // читают userId из готового AuthStorage.
        await TemplatesStore.instance.loadForCurrentUser();
        AppLogger.info('Templates loaded for current user', scope: 'startup');

        // Инициализируем сервис уведомлений - ошибка не должна блокировать запуск
        try {
          await NotificationService().initialize();
          AppLogger.info('NotificationService initialized', scope: 'startup');
        } catch (e, st) {
          // Логируем, но не прерываем запуск: значки просто покажут 0
          AppLogger.error(
            'NotificationService initialization failed, badges will show 0',
            scope: 'startup',
            error: e,
            stackTrace: st,
          );
        }

        //Запуск приложения после полной инициализации
        runApp(const MyApp());
      } catch (error, stackTrace) {
        AppLogger.error(
          'Application initialization failed',
          scope: 'startup',
          error: error,
          stackTrace: stackTrace,
        );
        // В случае критической ошибки запускаем приложение с fallback экраном
        runApp(const _ErrorApp());
      }
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled zone error',
        scope: 'startup',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

/// Безопасная загрузка .env: ошибка не валит остальные шаги первой волны.
Future<void> _safeDotenvLoad() async {
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('Environment variables loaded', scope: 'startup');
  } catch (e) {
    AppLogger.warning(
      'Failed to load .env file, using defaults',
      scope: 'startup',
    );
  }
}

/// Безопасная инициализация AppSettings - ошибка не валит остальные шаги.
Future<void> _safeAppSettingsInit() async {
  try {
    await AppSettings.init();
    AppLogger.info('Application settings initialized', scope: 'startup');
  } catch (e, st) {
    AppLogger.error(
      'AppSettings initialization failed',
      scope: 'startup',
      error: e,
      stackTrace: st,
    );
  }
}

/// Безопасная инициализация AuthStorage - ошибка не валит остальные шаги.
Future<void> _safeAuthStorageInit() async {
  try {
    await AuthStorage.init();
    AppLogger.info(
      'Auth storage initialized: remembered=${AuthStorage.isRemembered}, userId=${AuthStorage.userId}',
      scope: 'startup',
    );
  } catch (e, st) {
    AppLogger.error(
      'AuthStorage initialization failed',
      scope: 'startup',
      error: e,
      stackTrace: st,
    );
  }
}

/// Безопасная загрузка избранного - ошибка не валит остальные шаги.
Future<void> _safeFavoritesLoad() async {
  try {
    await FavoritesStore.instance.loadFromStorage();
    AppLogger.info('Favorites loaded from storage', scope: 'startup');
  } catch (e, st) {
    AppLogger.error(
      'Favorites loading failed',
      scope: 'startup',
      error: e,
      stackTrace: st,
    );
  }
}

/// Прогрев шрифтов: регистрируем их в FontEngine до первого кадра.
/// Без этого на web первый кадр уезжает раньше, чем подъедут .otf/.ttf,
/// и layout кнопок/иконок остаётся неверным до hot restart.
Future<void> _warmupFonts() async {
  Future<void> safeLoad(FontLoader loader) async {
    try {
      await loader.load();
    } catch (e, st) {
      // Сбой одного шрифта не должен ронять запуск
      AppLogger.error(
        'Font warmup failed',
        scope: 'startup',
        error: e,
        stackTrace: st,
      );
    }
  }

  final roboto = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Italic.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-MediumItalic.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf'));

  // MaterialIcons включается флагом uses-material-design: true и
  // лежит в FontEngine под именем "MaterialIcons". Asset Flutter SDK
  // публикует по этому пути.
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));

  await Future.wait([safeLoad(roboto), safeLoad(materialIcons)]);
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Ошибка запуска приложения',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    return AuthStorage.isRemembered
        ? const MainNavigation()
        : const LoginPage();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Кэшируем темы - они не зависят от themeMode и не должны пересоздаваться
  static const Color _primaryColor = Color(0xFF6288D5);
  late final ThemeData _lightTheme = _buildLightTheme(_primaryColor);
  late final ThemeData _darkTheme = _buildDarkTheme(_primaryColor);

  // Слушает корневой Navigator и закрывает активный top-message баннер
  // при смене маршрута, чтобы баннер не "переезжал" на новый экран.
  final TopMessageNavigatorObserver _topMessageObserver =
      TopMessageNavigatorObserver();

  @override
  void initState() {
    super.initState();
    // Подписываемся на изменения темы; setState обновляет только themeMode
    AppSettings.themeMode.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppSettings.themeMode.removeListener(_onThemeChanged);
    // NotificationService - singleton, живёт всё время приложения.
    // Его dispose() здесь не вызываем: при hot reload это бы привело к
    // обращению к освобождённым ValueNotifier-ам после восстановления MyApp.
    super.dispose();
  }

  void _onThemeChanged() {
    // Минимальный rebuild: только параметр themeMode у MaterialApp меняется
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: AppSettings.themeMode.value,
      navigatorObservers: [_topMessageObserver],
      home: const _AppHome(),
      // Корневой Overlay поверх Navigator - top-message баннеры монтируются
      // сюда и поэтому не уезжают вместе со сменой страницы.
      builder: (context, child) {
        return Overlay(
          key: rootMessageOverlayKey,
          initialEntries: [
            OverlayEntry(builder: (_) => child ?? const SizedBox.shrink()),
          ],
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
      scaffoldBackgroundColor: AppColorPalette.light.bgTop,
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
        backgroundColor: AppColorPalette.light.card,
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
      scaffoldBackgroundColor: AppColorPalette.dark.bgTop,
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
        backgroundColor: AppColorPalette.dark.bgTop,
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
