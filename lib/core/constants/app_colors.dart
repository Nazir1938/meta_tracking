import 'package:flutter/material.dart';

class AppColors {
  static const Color green = Color(0xFF2ECC71);
  static const Color greenDark = Color(0xFF27AE60);
  static const Color red = Color(0xFFFF4444);
  static const Color blue = Color(0xFF3498DB);
  static const Color orange = Color(0xFFFF9800);
  static const Color purple = Color(0xFF9B59B6);
  static const Color dark = Color(0xFF1A1A2E);
  static const Color navy = Color(0xFF0A1628);
  static const Color background = Color(0xFFF5F7FA);
  static const Color white = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textGray = Color(0xFF6B7280);

  static Color greenLight = green.withValues(alpha: 0.1);
  static Color redLight = red.withValues(alpha: 0.1);
  static Color blueLight = blue.withValues(alpha: 0.1);
  static Color orangeLight = orange.withValues(alpha: 0.1);
  static Color purpleLight = purple.withValues(alpha: 0.1);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
        ),
      );
}