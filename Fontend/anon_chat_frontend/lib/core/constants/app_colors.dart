import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121C);
  static const Color card = Color(0xFF1A1A2E);
  static const Color errorBackground = Color(0xFF2A1A1A);

  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF3ECFCF);

  // Neutral Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF6666AA);
  static const Color textTertiary = Color(0xFF8888AA);
  static const Color hint = Color(0xFF44445A);

  // Functional Colors
  static const Color error = Color(0xFFFF6B6B);
  static const Color border = Color(0xFF2E2E4E);
  static const Color borderSecondary = Color(0xFF2A2A3E);

  // Gradients
  static const List<Color> primaryGradient = [primary, secondary];

  static const List<Color> secondaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF4B44CC),
  ];
}
