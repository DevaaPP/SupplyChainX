import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── SupplyX Industrial-Tech Enterprise Palette (#EDDB43 Theme) ─────────

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);       // Off-white main background
  static const Color surface = Color(0xFFFFFFFF);          // Card / Container pure white
  static const Color surfaceElevated = Color(0xFFF1F5F9);  // Subtle tint / input background
  static const Color sidebar = Color(0xFF0F172A);          // Deep navy sidebar
  static const Color sidebarActive = Color(0xFF1E293B);    // Active item in sidebar
  static const Color card = Color(0xFFFFFFFF);             // Clean white card
  static const Color cardBorder = Color(0xFFE2E8F0);       // Subtle 1px border
  static const Color cardBorderStrong = Color(0xFFCBD5E1); // Slightly darker border

  // Typography
  static const Color textPrimary = Color(0xFF111827);      // Ink — primary text
  static const Color textSecondary = Color(0xFF475569);    // Slate — secondary text
  static const Color textMuted = Color(0xFF94A3B8);        // Muted labels & timestamps
  static const Color textOnNavy = Color(0xFFF8FAFC);       // Light text on dark navy
  static const Color textOnPrimary = Color(0xFF111827);    // Dark text on industrial yellow

  // Brand & Action
  static const Color navy = Color(0xFF0F2942);             // Brand navy
  static const Color primary = Color(0xFFEDDB43);          // Industrial Yellow (#EDDB43)
  static const Color primaryHover = Color(0xFFDCC828);     // Slightly darker gold-yellow on hover
  static const Color primaryLight = Color(0xFFFEFCE8);     // Light yellow tint for active chips
  static const Color primaryBorder = Color(0xFFFACC15);    // Yellow border

  // Status & Operational Indicators
  static const Color success = Color(0xFF16A34A);          // Signal Green — healthy / on-track
  static const Color successLight = Color(0xFFF0FDF4);     // Green tint
  static const Color successBorder = Color(0xFFBBF7D0);    // Green border

  static const Color warning = Color(0xFFD97706);          // Amber — warnings / at risk
  static const Color warningLight = Color(0xFFFFFBEB);     // Amber tint
  static const Color warningBorder = Color(0xFFFDE68A);    // Amber border

  static const Color danger = Color(0xFFDC2626);           // Red — exceptions / delayed / critical
  static const Color dangerLight = Color(0xFFFEF2F2);      // Red tint
  static const Color dangerBorder = Color(0xFFFECACA);     // Red border

  static const Color neutral = Color(0xFF64748B);          // Slate neutral
  static const Color neutralLight = Color(0xFFF8FAFC);     // Neutral tint
  static const Color neutralBorder = Color(0xFFE2E8F0);    // Neutral border

  // Severity aliases
  static const Color critical = danger;
  static const Color criticalDim = dangerLight;
  static const Color high = warning;
  static const Color highDim = warningLight;
  static const Color medium = Color(0xFFEAB308);
  static const Color mediumDim = Color(0xFFFEFCE8);
  static const Color low = success;
  static const Color lowDim = successLight;
  static const Color info = Color(0xFFB45309);
  static const Color infoDim = Color(0xFFFEFCE8);

  // Role Badges
  static const Color manufacturer = Color(0xFF475569);
  static const Color distributor = Color(0xFF0F2942);
  static const Color warehouse = Color(0xFFD97706);
  static const Color retailer = Color(0xFF16A34A);
  static const Color customer = Color(0xFF854D0E);
}
