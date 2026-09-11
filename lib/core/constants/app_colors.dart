/// Application-wide color constants for WavesLive
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Ocean Palette
  static const Color primaryDeep = Color(0xFF0A2E4A);
  static const Color primaryMid = Color(0xFF0D4470);
  static const Color primaryLight = Color(0xFF1A6B9E);
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentLight = Color(0xFF4DDFC7);

  // Background & Surface
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8EEF5);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF0A1929);
  static const Color textSecondary = Color(0xFF4A6580);
  static const Color textHint = Color(0xFF8EA5BB);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Severity Colors
  static const Color severityLow = Color(0xFF4CAF50);
  static const Color severityMedium = Color(0xFFFF9800);
  static const Color severityHigh = Color(0xFFF44336);
  static const Color severityCritical = Color(0xFF9C27B0);

  // Status Colors
  static const Color statusPending = Color(0xFF607D8B);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusMitigated = Color(0xFFFF9800);
  static const Color statusResolved = Color(0xFF4CAF50);

  // Verification Colors
  static const Color genuine = Color(0xFF4CAF50);
  static const Color suspicious = Color(0xFFFF9800);
  static const Color falsified = Color(0xFFF44336);

  // Alert
  static const Color alertBackground = Color(0xFFFFF3E0);
  static const Color alertBorder = Color(0xFFFF8C00);

  // Divider & Border
  static const Color divider = Color(0xFFE0E8F0);
  static const Color border = Color(0xFFCDD9E5);

  // Role-specific Colors
  static const Color officerColor = Color(0xFF0A2E4A);
  static const Color agentColor = Color(0xFF00796B);
  static const Color volunteerColor = Color(0xFF5C6BC0);
  static const Color ngoColor = Color(0xFF8D6E63);

  // Gradient
  static const List<Color> oceanGradient = [
    Color(0xFF0A2E4A),
    Color(0xFF0D6B8E),
    Color(0xFF00C9A7),
  ];

  static const List<Color> splashGradient = [
    Color(0xFF051929),
    Color(0xFF0A2E4A),
    Color(0xFF0D4470),
  ];
}
