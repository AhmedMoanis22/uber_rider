import 'package:flutter/material.dart';

class AppColors {
  // Primary colors for driver app
  static const Color primary = Color(0xFF2D3142);
  static const Color primaryLight = Color(0xFF4F5D75);
  static const Color primaryDark = Color(0xFF1A1E2E);

  // Accent colors
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF90E0EF);
  static const Color accentDark = Color(0xFF0096C7);

  // Semantic colors
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFEF476F);
  static const Color info = Color(0xFF118AB2);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
}
