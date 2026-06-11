import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/hisaab_typography.dart';
import '../features/ledger/presentation/pages/friend_list_page.dart';
import '../features/settings/data/app_preferences_repository.dart';

class HisaabApp extends ConsumerWidget {
  const HisaabApp({super.key});

  TextTheme _readableTextTheme({
    required Color primaryText,
    required Color secondaryText,
    String? fontFamily,
  }) {
    return TextTheme(
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.35,
        color: primaryText,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.35,
        color: primaryText,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.3,
        color: secondaryText,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
    );
  }

  ThemeData _terminalTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Moldern',
      scaffoldBackgroundColor: Color(0xFF0D1117),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF00D084),
        onPrimary: Color(0xFF0D1117),
        secondary: Color(0xFF58A6FF),
        tertiary: Color(0xFF3FB950),
        onTertiary: Color(0xFF0D1117),
        error: Color(0xFFF85149),
        onError: Color(0xFF0D1117),
        errorContainer: Color(0xFF3D4C3A),
        onErrorContainer: Colors.white,
        surface: Color(0xFF161B22),
        onSurface: Color(0xFFE6EDF3),
        onSurfaceVariant: Color(0xFF8B949E),
        outline: Color(0xFF30363D),
        outlineVariant: Color(0xFF8E2A2A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFF00D084),
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00D084),
        foregroundColor: Color(0xFF0D1117),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF00D084), width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFF8B949E)),
        hintStyle: TextStyle(color: Color(0xFF6E7681)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF00D084),
          foregroundColor: Color(0xFF0D1117),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color(0xFF58A6FF)),
      ),
      textTheme: _readableTextTheme(
        primaryText: const Color(0xFFE6EDF3),
        secondaryText: const Color(0xFF8B949E),
        fontFamily: 'Moldern',
      ),
      extensions: const [HisaabTypography(contentFontFamily: 'Courier New')],
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Merriweather',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB94B4B),
        onPrimary: Color(0xFFFFF7F7),
        primaryContainer: Color(0xFF743232),
        onPrimaryContainer: Color(0xFFFFDADA),
        secondary: Color(0xFFE7A0A0),
        onSecondary: Color(0xFF442020),
        secondaryContainer: Color(0xFF633838),
        onSecondaryContainer: Color(0xFFFFDADA),
        tertiary: Color(0xFF80C995),
        onTertiary: Color(0xFF17341F),
        surface: Color(0xFF453B3B),
        onSurface: Color(0xFFFFF5F5),
        onSurfaceVariant: Color(0xFFD8C2C2),
        outline: Color(0xFF806D6D),
        error: Color(0xFFFF7777),
        onError: Color(0xFF3D1010),
        errorContainer: Color(0xFF653B3B),
        onErrorContainer: Color(0xFFFFE7E7),
        outlineVariant: Color(0xFFA64A4A),
      ),
      scaffoldBackgroundColor: const Color(0xFF342E2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF453B3B),
        foregroundColor: Color(0xFFFFF5F5),
        elevation: 0,
      ),
      cardColor: const Color(0xFF453B3B),
      dividerColor: const Color(0xFF806D6D),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF4E4242),
        hintStyle: const TextStyle(color: Color(0xFFBCA7A7)),
        labelStyle: const TextStyle(color: Color(0xFFE8D4D4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF806D6D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF806D6D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB94B4B), width: 2),
        ),
      ),
      textTheme: _readableTextTheme(
        primaryText: const Color(0xFFFFF5F5),
        secondaryText: const Color(0xFFD8C2C2),
        fontFamily: 'Merriweather',
      ),
      extensions: const [HisaabTypography(contentFontFamily: 'Merriweather')],
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Merriweather',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFB94B4B),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFFB7B7),
        onPrimaryContainer: Color(0xFF5C1E1E),
        secondary: Color(0xFF7E3434),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFFFCACA),
        onSecondaryContainer: Color(0xFF4D1919),
        tertiary: Color(0xFF327A48),
        onTertiary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFB0B0),
        onSurface: Color(0xFF3F2020),
        onSurfaceVariant: Color(0xFF704545),
        outline: Color(0xFFC85F5F),
        error: Color(0xFF9F2525),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFA2A2),
        onErrorContainer: Color(0xFF5A1717),
        outlineVariant: Color(0xFFA94040),
      ),
      scaffoldBackgroundColor: const Color(0xFFFF8282),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFB0B0),
        foregroundColor: Color(0xFF3F2020),
        elevation: 0,
      ),
      cardColor: const Color(0xFFFFB0B0),
      dividerColor: const Color(0xFFC85F5F),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFC2C2),
        hintStyle: const TextStyle(color: Color(0xFF875656)),
        labelStyle: const TextStyle(color: Color(0xFF663434)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC85F5F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC85F5F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB94B4B), width: 2),
        ),
      ),
      textTheme: _readableTextTheme(
        primaryText: const Color(0xFF3F2020),
        secondaryText: const Color(0xFF704545),
        fontFamily: 'Merriweather',
      ),
      extensions: const [HisaabTypography(contentFontFamily: 'Merriweather')],
    );
  }

  ThemeData _themeFromKey(String? key) {
    switch (key) {
      case 'dark':
        return _darkTheme();
      case 'light':
        return _lightTheme();
      default:
        return _terminalTheme();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref
        .watch(themeKeyProvider)
        .when(
          data: (value) => value,
          error: (_, __) => 'terminal',
          loading: () => 'terminal',
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hisaab',
      theme: _themeFromKey(themeKey),
      home: const FriendListPage(),
    );
  }
}
