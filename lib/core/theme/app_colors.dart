import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2236);
  static const Color card = Color(0xFF151E2D);
  static const Color cardBorder = Color(0xFF1E2D42);

  // Primary accent — electric cyan
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDim = Color(0x2600D4FF);
  static const Color primaryGlow = Color(0x5500D4FF);

  // Secondary accent — violet
  static const Color secondary = Color(0xFF7B61FF);
  static const Color secondaryDim = Color(0x267B61FF);

  // Severity colors
  static const Color critical = Color(0xFFFF2D55);
  static const Color criticalDim = Color(0x26FF2D55);
  static const Color high = Color(0xFFFF6B35);
  static const Color highDim = Color(0x26FF6B35);
  static const Color medium = Color(0xFFFFB800);
  static const Color mediumDim = Color(0x26FFB800);
  static const Color low = Color(0xFF00C896);
  static const Color lowDim = Color(0x2600C896);
  static const Color info = Color(0xFF6B7A99);
  static const Color infoDim = Color(0x266B7A99);

  // Role colors
  static const Color manufacturer = Color(0xFF7B61FF);
  static const Color distributor = Color(0xFF00D4FF);
  static const Color warehouse = Color(0xFFFFB800);
  static const Color retailer = Color(0xFF00C896);
  static const Color customer = Color(0xFFFF6B35);

  // Text
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8A9BBF);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textOnPrimary = Color(0xFF0A0E1A);

  // Status
  static const Color online = Color(0xFF00C896);
  static const Color offline = Color(0xFF4A5568);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFFF2D55);
  static const Color success = Color(0xFF00C896);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF00D4FF)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1424), Color(0xFF0A0E1A)],
  );
}
