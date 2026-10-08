import 'package:flutter/material.dart';
import 'login_page.dart';

const Color appRed = Color(0xFFDD0004);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessBumble',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Custom red and white theme
        primaryColor: appRed,
        scaffoldBackgroundColor: appRed,
        colorScheme: const ColorScheme.light(
          primary: appRed,
          secondary: appRed,
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: appRed,
          displayColor: appRed,
        ).copyWith(
          bodyMedium: const TextStyle(fontWeight: FontWeight.bold, color: appRed),
          bodyLarge: const TextStyle(fontWeight: FontWeight.bold, color: appRed),
          titleLarge: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appRed,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: appRed,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
