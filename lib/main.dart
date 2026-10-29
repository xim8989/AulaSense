import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AulaSenseApp());
}

class AulaSenseApp extends StatelessWidget {
  const AulaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AulaSense',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B2B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9333EA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}