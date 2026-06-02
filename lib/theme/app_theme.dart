import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color canvasColor = Color(0xFF1E1E1E);
  static const Color textColor = Color(0xFFEBEBEB);
  static const Color subtitleColor = Color(0xFFA1A1AA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Pretendard').copyWith(
        displayLarge: TextStyle(fontFamily: 'Pretendard', 
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontFamily: 'Pretendard', 
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyMedium: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: textColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        color: canvasColor,
      ),
    );
  }
}
