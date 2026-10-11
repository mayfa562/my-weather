import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.violet);
    return ThemeData(
      colorScheme: scheme.copyWith(primary: AppColors.violet, surface: AppColors.violetPale),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.violetPale,
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violetDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -2),
        displayMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.5),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: .72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .68),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      ),
    );
  }
}

class AppColors {
  AppColors._();
  static const Color violet = Color(0xFF7047E8);
  static const Color violetDeep = Color(0xFF4225A8);
  static const Color violetDark = Color(0xFF2D176F);
  static const Color violetPale = Color(0xFFE8E1FF);
  static const Color violetPaleDeep = Color(0xFFC8BDF5);
  static const Color violetSoft = Color(0xFFB9A8F2);
  static const Color gold = Color(0xFFFFD34E);
  static const Color glassTint = Color(0xFFFFFFFF);
  static const Color cardTint = Color(0xFFF7F4FF);
  static const Color textMuted = Color(0xFF756A9C);
}

class AppGradients {
  AppGradients._();
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8147F5), Color(0xFF5B35D5), Color(0xFF3E2A9D)],
  );
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE8FF), Color(0xFFDAD1FF), Color(0xFFBFB3F0)],
  );
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xBFFFFFFF), Color(0x66FFFFFF)],
  );
  static const LinearGradient primaryButton = LinearGradient(
    colors: [Color(0xFF7D43F2), Color(0xFF4D22C5)],
  );
  static const LinearGradient sun = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE08A), AppColors.gold],
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double huge = 36;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double xxxl = 32;
}

class AppOpacity {
  AppOpacity._();
  static const double subtle = .12;
  static const double faint = .2;
  static const double muted = .68;
  static const double strong = .85;
  static const double nearOpaque = .92;
}
