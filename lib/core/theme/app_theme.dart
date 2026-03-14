import 'package:flutter/material.dart';

class AppColors {
  static const Color primary    = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color secondary  = Color(0xFF3498DB);
  static const Color danger     = Color(0xFFE74C3C);
  static const Color warning    = Color(0xFFF39C12);
  static const Color purple     = Color(0xFF9B59B6);
  static const Color dark       = Color(0xFF1A1A2E);
  static const Color navy       = Color(0xFF0A1628);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface    = Colors.white;
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
  static const Color border     = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    fontFamily: 'Poppins',
  );
}