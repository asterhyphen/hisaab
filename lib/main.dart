import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/friend_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('friendsBox');
  await Hive.openBox('userMetaBox');
  await Hive.openBox('appMetaBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hisaab',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Moldern',
        scaffoldBackgroundColor: Color(0xFF0D1117), // GitHub dark
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00D084), // Terminal green
          secondary: Color(0xFF58A6FF), // Terminal blue
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Color(0xFF58A6FF)),
        ),
      ),
      home: FriendListPage(),
    );
  }
}
