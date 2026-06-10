import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        secondary: Color(0xFF58A6FF),
        surface: Color(0xFF161B22),
        onSurface: Color(0xFFE6EDF3),
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
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Merriweather',
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF8AB4F8),
        secondary: Color(0xFF7EDDD3),
        surface: Color(0xFF1F232B),
        onSurface: Color(0xFFF7FAFF),
        outline: Color(0xFF3D4553),
      ),
      scaffoldBackgroundColor: Color(0xFF151922),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F232B),
        foregroundColor: Color(0xFFF7FAFF),
        elevation: 0,
      ),
      cardColor: const Color(0xFF1F232B),
      dividerColor: const Color(0xFF3D4553),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202735),
        hintStyle: const TextStyle(color: Color(0xFFAAB4C3)),
        labelStyle: const TextStyle(color: Color(0xFFD8E0EC)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3D4553)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3D4553)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF8AB4F8), width: 2),
        ),
      ),
      textTheme: _readableTextTheme(
        primaryText: const Color(0xFFF7FAFF),
        secondaryText: const Color(0xFFB8C3D3),
        fontFamily: 'Merriweather',
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'PlayfairDisplay',
      colorScheme: ColorScheme.light(
        primary: Color(0xFF0C5A44),
        secondary: Color(0xFF0E5FB8),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1B2430),
        outline: Color(0xFFC9D3DF),
      ),
      scaffoldBackgroundColor: Color(0xFFF1F5F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1B2430),
        elevation: 0,
      ),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFD5DDE7),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        labelStyle: const TextStyle(color: Color(0xFF3A4353)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9D3DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9D3DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0E5FB8), width: 2),
        ),
      ),
      textTheme: _readableTextTheme(
        primaryText: const Color(0xFF1B2430),
        secondaryText: const Color(0xFF5E6878),
        fontFamily: 'PlayfairDisplay',
      ),
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
