import 'package:flutter/material.dart';

/// Application color palette - ShuttleBee Theme
class AppColors {
  AppColors._();

  // === Primary Colors (ShuttleBee Blue) ===
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryContainer = Color(0xFFBBDEFB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0D47A1);

  // === Secondary Colors (ShuttleBee Orange) ===
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFFE65100);

  // === Neutral Colors ===
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceDim = Color(0xFFE5E7EB);
  static const Color onBackground = Color(0xFF111827);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFFD1D5DB);

  // === Status Colors (ShuttleBee) ===
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF9C4);
  static const Color onWarning = Color(0xFF000000);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color onInfo = Color(0xFFFFFFFF);

  // === Trip State Colors (ShuttleBee) ===
  static const Color stateDraft = Color(0xFF9E9E9E);
  static const Color statePlanned = Color(0xFF2196F3);
  static const Color stateOngoing = Color(0xFFFF9800);
  static const Color stateDone = Color(0xFF4CAF50);
  static const Color stateCancelled = Color(0xFFF44336);

  // === Trip Line Status Colors ===
  static const Color statusNotStarted = Color(0xFF9E9E9E);
  static const Color statusAbsent = Color(0xFFF44336);
  static const Color statusBoarded = Color(0xFF2196F3);
  static const Color statusDropped = Color(0xFF4CAF50);

  // === Map Colors ===
  static const Color mapMarkerPickup = Color(0xFF2196F3);
  static const Color mapMarkerDropoff = Color(0xFF4CAF50);
  static const Color mapMarkerCurrent = Color(0xFFFF9800);
  static const Color mapRoute = Color(0xFF2196F3);

  // === Chart Colors ===
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];

  // === Sync Status Colors ===
  static const Color offline = Color(0xFFEF4444);
  static const Color syncing = Color(0xFFF59E0B);
  static const Color synced = Color(0xFF10B981);

  // === Border Colors ===
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  // === Divider Colors ===
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // === Shadow Color ===
  static const Color shadow = Color(0x14000000);

  // === Overlay Colors ===
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // === Dark Theme Colors ===
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF374151);
  static const Color darkOnBackground = Color(0xFFF9FAFB);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkDivider = Color(0xFF374151);

  // === Shimmer Colors ===
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);
  static const Color darkShimmerBase = Color(0xFF374151);
  static const Color darkShimmerHighlight = Color(0xFF4B5563);

  // === Gradient Colors ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
