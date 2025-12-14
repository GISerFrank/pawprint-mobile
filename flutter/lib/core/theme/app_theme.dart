import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 应用颜色定义
class AppColors {
  AppColors._();

  // Primary - Teal/Mint
  static const Color primary50 = Color(0xFFF0FDFA);
  static const Color primary100 = Color(0xFFCCFBF1);
  static const Color primary200 = Color(0xFF99F6E4);
  static const Color primary300 = Color(0xFF5EEAD4);
  static const Color primary400 = Color(0xFF2DD4BF);
  static const Color primary500 = Color(0xFF14B8A6);
  static const Color primary600 = Color(0xFF0D9488);
  static const Color primary700 = Color(0xFF0F766E);
  static const Color primary800 = Color(0xFF115E59);
  static const Color primary900 = Color(0xFF134E4A);

  // Neutral - Stone
  static const Color stone50 = Color(0xFFFAFAF9);
  static const Color stone100 = Color(0xFFF5F5F4);
  static const Color stone200 = Color(0xFFE7E5E4);
  static const Color stone300 = Color(0xFFD6D3D1);
  static const Color stone400 = Color(0xFFA8A29E);
  static const Color stone500 = Color(0xFF78716C);
  static const Color stone600 = Color(0xFF57534E);
  static const Color stone700 = Color(0xFF44403C);
  static const Color stone800 = Color(0xFF292524);
  static const Color stone900 = Color(0xFF1C1917);

  // Accent Colors
  static const Color cream = Color(0xFFFDFBF7);

  static const Color mint100 = Color(0xFFD1FAE5);
  static const Color mint500 = Color(0xFF10B981);
  static const Color mint600 = Color.fromARGB(255, 8, 145, 99);

  static const Color peach50 = Color(0xFFFFF7ED);
  static const Color peach100 = Color(0xFFFFEDD5);
  static const Color peach200 = Color(0xFFFED7AA);
  static const Color peach400 = Color(0xFFFB923C);
  static const Color peach500 = Color(0xFFF97316);
  static const Color peach600 = Color.fromARGB(255, 220, 93, 2);
  static const Color peach800 = Color(0xFF9A3412);

  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky900 = Color(0xFF0C4A6E);

  // Semantic Colors
  static const Color success = mint500;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = peach500;
  static const Color info = sky500;

  // Background
  static const Color background = cream;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = stone50;
}

/// 应用主题
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary500,
        brightness: Brightness.light,
        primary: AppColors.primary500,
        onPrimary: Colors.white,
        secondary: AppColors.mint500,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.stone800,
        error: AppColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // Typography
      textTheme: GoogleFonts.quicksandTextTheme().copyWith(
        displayLarge: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        displaySmall: GoogleFonts.quicksand(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        headlineLarge: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        headlineMedium: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        headlineSmall: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.stone800,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.stone700,
        ),
        titleSmall: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.stone600,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.stone700,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.stone600,
        ),
        bodySmall: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.stone500,
        ),
        labelLarge: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.stone700,
        ),
        labelMedium: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.stone500,
        ),
        labelSmall: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.stone400,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.stone800,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.stone800,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: AppColors.surface,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary600,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.primary200, width: 2),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary600,
          textStyle: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.stone50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.quicksand(
          color: AppColors.stone300,
          fontWeight: FontWeight.w500,
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.stone400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.stone50,
        selectedColor: AppColors.primary500,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.stone100,
        thickness: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.stone800,
        contentTextStyle: GoogleFonts.quicksand(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 间距常量
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 圆角常量
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 9999;
}

/// 阴影常量
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.01),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get float => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 25,
      offset: const Offset(0, 20),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.01),
      blurRadius: 10,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> primary(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}