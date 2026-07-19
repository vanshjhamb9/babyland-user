import 'package:flutter/material.dart';

/// Design tokens for the pregnancy / baby dashboard (soft pastel, 8px grid).
abstract final class DashboardTheme {
  static const Color canvas = Color(0xFFFFF5F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D2A32);
  static const Color textSecondary = Color(0xFF6B6570);
  static const Color accentRose = Color(0xFFE08A9B); // Darkened from FFB6C1
  static const Color accentBlush = Color(0xFFF2A3B3); // Darkened from FFD1DC
  static const Color accentLavender = Color(0xFFE8E0F5);
  static const Color accentPeach = Color(0xFFFFE4D6);
  static const Color stroke = Color(0xFFF0E8EE);

  /// Spec: light gradient #FFB6C1 → #FFD1DC
  static const LinearGradient softPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentRose, accentBlush],
  );

  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double sectionGap = 24;
  static const double cardPadding = 18;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF2D0A1F).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: cardShadow,
        border: Border.all(color: stroke.withValues(alpha: 0.85)),
      );
}
