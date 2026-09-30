import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StyleSnap design system — "Light minimal" (Zara-like editorial).
/// Warm whites, hairline borders, ink-black CTAs, sage accents, generous space.
class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scrim = Color(0x99000000);

  // Ink scale
  static const Color ink = Color(0xFF1B1B1B);
  static const Color inkSoft = Color(0xFF6F6B65);
  static const Color inkFaint = Color(0xFFA9A39A);

  // Brand accents
  static const Color sage = Color(0xFF75846D);
  static const Color sageDeep = Color(0xFF5C6B55);
  static const Color sageSoft = Color(0xFFE9EDE5);
  static const Color beige = Color(0xFFEFEAE2);
  static const Color sand = Color(0xFFE5DFD4);

  // Lines
  static const Color hairline = Color(0xFFE9E4DB);

  // Semantic
  static const Color danger = Color(0xFFB4574A);
  static const Color success = Color(0xFF5E7D5A);
  static const Color gold = Color(0xFFC2A15E);
}

class AppRadii {
  AppRadii._();
  static const double card = 20;
  static const double cardSm = 14;
  static const double button = 30;
  static const double chip = 20;
  static const double sheet = 28;
}

/// Motion tokens — soft, editorial easing.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve emph = Curves.easeInOutCubicEmphasized;
}

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        displaySmall: GoogleFonts.inter(
          fontSize: 34,
          height: 1.15,
          letterSpacing: -1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 26,
          height: 1.2,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 21,
          height: 1.25,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 17,
          height: 1.3,
          letterSpacing: -0.2,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          height: 1.55,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: AppColors.inkSoft,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: AppColors.inkSoft,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.ink,
        ),
        labelMedium: GoogleFonts.inter(
          // uppercase eyebrow labels
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.inkFaint,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: AppColors.inkFaint,
        ),
      );

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.surface,
        secondary: AppColors.sage,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        outlineVariant: AppColors.hairline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.sageSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.hairline,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
