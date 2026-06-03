import 'package:flutter/material.dart';

class AppColors {
  // Primary Color - Modern Sky Blue
  static const Color primary = Color(0xFF0EA5E9);
  
  // Primary Dark - Premium Deep Sky Blue
  static const Color primaryDark = Color(0xFF0288D1);
  
  // Light Sky Blue - Ideal for surface highlights and secondary buttons
  static const Color primaryLight = Color(0xFFE0F2FE);
  
  // Clean Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  
  // Borders and Dividers
  static const Color border = Color(0xFFE2E8F0);
  
  // Text & Fonts - Charcoal / Slate Black
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  
  // UI States
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  
  // Elegant Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
