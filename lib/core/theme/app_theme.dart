import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient & Brand
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFFEC4899); // Pink
  static const Color accent = Color(0xFF8B5CF6); // Purple
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose
  static const Color info = Color(0xFF0EA5E9); // Sky
  
  // Backgrounds & Surfaces (Modern clean dark & light)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusReserved = Color(0xFFF59E0B);
  static const Color statusSold = Color(0xFF64748B);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
