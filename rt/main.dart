import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';
import 'features/app_shell.dart';
import 'features/settings/application/app_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('app');
  await NotificationService.instance.initialize();
  await NotificationService.instance.syncForAllTrackers(Hive.box('app'));
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B894),
      brightness: Brightness.dark,
    );
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B894),
      brightness: Brightness.light,
    );

    final darkBase = ThemeData(
      useMaterial3: true,
      fontFamily: 'Avenir',
      colorScheme: darkScheme,
    );

    final lightBase = ThemeData(
      useMaterial3: true,
      fontFamily: 'Avenir',
      colorScheme: lightScheme,
    );
    const pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );

    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: settings.materialThemeMode,
      themeAnimationCurve: Curves.easeOutCubic,
      themeAnimationDuration: const Duration(milliseconds: 220),
      theme: lightBase.copyWith(
        pageTransitionsTheme: pageTransitionsTheme,
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface.withValues(alpha: 0.88),
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: lightScheme.onSurface,
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFD8E1EA),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: lightScheme.surface.withValues(alpha: 0.96),
          selectedItemColor: lightScheme.primary,
          unselectedItemColor: lightScheme.onSurface.withValues(alpha: 0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00A885), width: 1.2),
          ),
        ),
      ),
      darkTheme: darkBase.copyWith(
        pageTransitionsTheme: pageTransitionsTheme,
        scaffoldBackgroundColor: const Color(0xFF090F1B),
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface.withValues(alpha: 0.72),
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: darkScheme.onSurface,
        ),
        cardColor: const Color(0xFF111A2B),
        dividerColor: Colors.white.withValues(alpha: 0.08),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkScheme.surface.withValues(alpha: 0.92),
          selectedItemColor: const Color(0xFF77FFD8),
          unselectedItemColor: darkScheme.onSurface.withValues(alpha: 0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00E0B2), width: 1.2),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
