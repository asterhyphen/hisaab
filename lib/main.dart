import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/friend_list_page.dart';
import 'widget_action_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('friendsBox');
  await Hive.openBox('userMetaBox');
  await Hive.openBox('appMetaBox');
  await WidgetActionBridge.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF4DA3FF),
        secondary: Color(0xFF2DD4BF),
        surface: Color(0xFF1C1C1E),
        onSurface: Color(0xFFF3F4F6),
      ),
      scaffoldBackgroundColor: Color(0xFF121214),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF0A7D51),
        secondary: Color(0xFF1565C0),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF111827),
      ),
      scaffoldBackgroundColor: Color(0xFFF5F7FA),
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
  Widget build(BuildContext context) {
    final appMetaBox = Hive.box('appMetaBox');
    return ValueListenableBuilder(
      valueListenable: appMetaBox.listenable(keys: ['theme']),
      builder: (context, _, __) {
        final themeKey = appMetaBox.get('theme') as String?;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hisaab',
          theme: _themeFromKey(themeKey),
          home: FriendListPage(),
        );
      },
    );
  }
}
