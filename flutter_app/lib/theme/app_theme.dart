import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern dark + glassmorphism palette.
class AppColors {
  static const Color bg = Color(0xFF07070C);
  static const Color bgSoft = Color(0xFF0E0F1A);
  static const Color surface = Color(0x22FFFFFF); // translucent glass
  static const Color surfaceStroke = Color(0x33FFFFFF);

  static const Color accent = Color(0xFF7C5CFF);   // violet
  static const Color accent2 = Color(0xFF22D3EE);  // cyan
  static const Color accent3 = Color(0xFFFF6EC7);  // pink
  static const Color danger = Color(0xFFFF5C7C);

  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFB4B4C7);

  static const LinearGradient orbGradient = LinearGradient(
    colors: [accent, accent2, accent3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B0714), Color(0xFF07070C), Color(0xFF06121A)],
  );
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.bgSoft,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
