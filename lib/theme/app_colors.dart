import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color scaffoldBackground = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF232340);
  static const Color surfaceLight = Color(0xFF2A2A45);

  // Primary accent
  static const Color primary = Color(0xFF7B2FFF);
  static const Color primaryDark = Color(0xFF5B1FCC);
  static const Color primaryLight = Color(0xFF9D5FFF);
  static const Color primarySurface = Color(0xFF1E1040);

  // Secondary accent
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryDark = Color(0xFF00A888);

  // Semantic
  static const Color error = Color(0xFFFF4C6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color success = Color(0xFF4ADE80);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color textTertiary = Color(0xFF6B6B80);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & dividers
  static const Color border = Color(0xFF2A2A40);
  static const Color divider = Color(0xFF1F1F35);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF4A1FB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient headingGradient = LinearGradient(
    colors: [Color(0xFFB388FF), primary, secondary],
  );
}
