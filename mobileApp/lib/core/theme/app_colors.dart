import 'package:flutter/material.dart';

/// Marsa Brand Colors - Matching Web App Identity
class AppColors {
  // Primary Brand Colors
  static const Color navy = Color(0xFF0A192F);
  static const Color navyLight = Color(0xFF1E3A5F);
  static const Color electric = Color(0xFF3A86FF);
  static const Color electricLight = Color(0xFF60A5FA);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color danger = Color(0xFFDC3545);
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color info = Color(0xFF17A2B8);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkDivider = Color(0xFF374151);

  // Additional Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x80000000);
  static const Color shadow = Color(0x1A000000);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  // Gradient Colors
  static const List<Color> primaryGradient = [navy, navyLight];
  static const List<Color> accentGradient = [electric, electricLight];
  static const List<Color> successGradient = [success, successLight];
  static const List<Color> warningGradient = [warning, warningLight];

  // Status Colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'نشط':
      case 'paid':
      case 'مدفوع':
        return success;
      case 'pending':
      case 'معلق':
      case 'overdue':
      case 'متأخر':
        return warning;
      case 'inactive':
      case 'غير نشط':
      case 'unpaid':
      case 'غير مدفوع':
        return danger;
      default:
        return info;
    }
  }
}
