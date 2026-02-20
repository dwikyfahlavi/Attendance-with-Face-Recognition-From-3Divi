import 'package:flutter/material.dart';

/// Centralized color palette for the attendance app
class AppColors {
  // Primary colors - Warm clay gradient
  static const Color primaryPurple = Color(0xFFC46C3B);
  static const Color primaryPurpleDark = Color(0xFF9C4E26);
  static const Color primaryPurpleLight = Color(0xFFD68A60);

  // Secondary colors - Sage green
  static const Color secondaryCyan = Color(0xFF2F6F5B);
  static const Color secondaryCyanDark = Color(0xFF235A49);

  // Background colors
  static const Color backgroundLight = Color(0xFFF7F2EC);
  static const Color backgroundWhite = Color(0xFFFFFDF9);
  static const Color backgroundGrey = Color(0xFFF1E8DF);

  // Text colors
  static const Color textPrimary = Color(0xFF2A241F);
  static const Color textSecondary = Color(0xFF6B5F54);
  static const Color textHint = Color(0xFF9B8D80);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF2F855A);
  static const Color successLight = Color(0xFFDDF3E5);
  static const Color error = Color(0xFFB42318);
  static const Color errorLight = Color(0xFFFDE3D7);
  static const Color warning = Color(0xFFB54708);
  static const Color warningLight = Color(0xFFFFE7C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFE0ECFF);

  // Attendance specific colors
  static const Color present = Color(0xFF10B981);
  static const Color absent = Color(0xFFEF4444);
  static const Color late = Color(0xFFF59E0B);

  // Aliases for convenience
  static const Color secondary = secondaryCyan;
  static const Color successGreen = present;
  static const Color errorRed = error;
  static const Color warningOrange = warning;

  // Borders and dividers
  static const Color borderLight = Color(0xFFE6D9CC);
  static const Color dividerColor = Color(0xFFE6D9CC);

  // Disabled state
  static const Color disabled = Color(0xFFBFB3A8);
  static const Color disabledBackground = Color(0xFFF3ECE5);

  // Glassmorphism
  static const Color glassLight = Color(0xFFFFF7EE);

  // Create gradient from primary purple to secondary cyan
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPurpleLight, Color(0xFFE8BFA4)],
  );

  // Purple gradient for cards
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPurpleLight],
  );

  // Success gradient for positive actions
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F855A), Color(0xFF276749)],
  );

  // Error gradient for negative actions
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB42318), Color(0xFF7A1A12)],
  );
}
