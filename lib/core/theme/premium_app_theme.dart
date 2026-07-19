import 'package:flutter/material.dart';

/// Centralized design tokens for the premium trackers UI.
/// This file is intentionally kept separate from the legacy `lib/app/theme/*`
/// to avoid unintended visual regressions across the rest of the app.
class AppColorsPremium {
  // Core palette (matches your spec)
  static const Color primary = Color(0xFFFF6F91);
  static const Color secondary = Color(0xFFA084E8);
  static const Color accent = Color(0xFF6EC6FF);
  static const Color background = Color(0xFFFFF9FB);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF757575);

  // Hydration — deeper aqua/cyan (readable white text, matches rose dashboard)
  static const LinearGradient hydrationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7AB8),
      Color(0xFF5CB8E8),
      Color(0xFF8AD4F5),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // Mental — saturated lavender → warm rose
  static const LinearGradient mentalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7E57C2),
      Color(0xFFB085D6),
      Color(0xFFE8799A),
    ],
    stops: [0.0, 0.45, 1.0],
  );
}

class AppTextStylesPremium {
  static const String fontFamily = 'Poppins';

  static TextStyle h1({
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color ?? AppColorsPremium.textPrimary,
      );

  static TextStyle h2({
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorsPremium.textPrimary,
      );

  static TextStyle h3({
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: color ?? AppColorsPremium.textPrimary,
      );

  static TextStyle body({
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColorsPremium.textPrimary,
      );

  static TextStyle caption({
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: color ?? AppColorsPremium.textSecondary,
      );
}

class AppSpacingPremium {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
}

class AppRadiusPremium {
  static const double cards = 24;
  static const double buttons = 16;
}

class AppShadowPremium {
  static BoxShadow softShadow() => const BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4),
      );
}

