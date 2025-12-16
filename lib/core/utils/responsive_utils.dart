import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Device type enum for responsive design
enum DeviceType { mobile, tablet, desktop }

/// Screen size enum for more granular control
enum ScreenSize { xs, sm, md, lg, xl }

/// Responsive utility class for handling responsive design
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < desktopBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get screen size enum
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 480) return ScreenSize.xs;
    if (width < 600) return ScreenSize.sm;
    if (width < 900) return ScreenSize.md;
    if (width < 1200) return ScreenSize.lg;
    return ScreenSize.xl;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Check if device is mobile or tablet (for combined layouts)
  static bool isMobileOrTablet(BuildContext context) =>
      !isDesktop(context);

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Get responsive value based on device type
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return value(
      context: context,
      mobile: AppDimensions.paddingMd,
      tablet: AppDimensions.paddingLg,
      desktop: AppDimensions.paddingXl,
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return value(
      context: context,
      mobile: AppDimensions.paddingHorizontalMd,
      tablet: AppDimensions.paddingHorizontalLg,
      desktop: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  /// Get responsive content max width
  static double contentMaxWidth(BuildContext context) {
    return value(
      context: context,
      mobile: double.infinity,
      tablet: 720.0,
      desktop: 1200.0,
    );
  }

  /// Get responsive form max width
  static double formMaxWidth(BuildContext context) {
    return value(
      context: context,
      mobile: double.infinity,
      tablet: 500.0,
      desktop: 600.0,
    );
  }

  /// Get responsive grid column count
  static int gridColumnCount(BuildContext context) {
    return value(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive grid column count for cards
  static int cardGridColumnCount(BuildContext context) {
    return value(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Get responsive font scale
  static double fontScale(BuildContext context) {
    return value(
      context: context,
      mobile: 1.0,
      tablet: 1.05,
      desktop: 1.1,
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, {double baseSize = 24}) {
    return value(
      context: context,
      mobile: baseSize,
      tablet: baseSize * 1.1,
      desktop: baseSize * 1.2,
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {double baseSpacing = 16}) {
    return value(
      context: context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.25,
      desktop: baseSpacing * 1.5,
    );
  }

  /// Get navigation type (bottom nav for mobile, side nav for larger screens)
  static bool useBottomNavigation(BuildContext context) => isMobile(context);

  /// Get navigation type (rail for tablet, drawer for desktop)
  static bool useNavigationRail(BuildContext context) => isTablet(context);

  /// Get navigation type (full drawer for desktop)
  static bool useNavigationDrawer(BuildContext context) => isDesktop(context);

  /// Should show side panel (for master-detail layouts)
  static bool showSidePanel(BuildContext context) => !isMobile(context);

  /// Get dialog width
  static double dialogWidth(BuildContext context) {
    return value(
      context: context,
      mobile: screenWidth(context) * 0.9,
      tablet: 500.0,
      desktop: 600.0,
    );
  }

  /// Get modal bottom sheet height
  static double bottomSheetHeight(BuildContext context) {
    return value(
      context: context,
      mobile: screenHeight(context) * 0.9,
      tablet: screenHeight(context) * 0.7,
      desktop: screenHeight(context) * 0.6,
    );
  }

  /// Is landscape mode
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Is portrait mode
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// Get aspect ratio for images/cards
  static double cardAspectRatio(BuildContext context) {
    return value(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.3,
    );
  }
}

/// Extension on BuildContext for easier access
extension ResponsiveExtension on BuildContext {
  /// Get device type
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);

  /// Get screen size
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);

  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Check if mobile or tablet
  bool get isMobileOrTablet => ResponsiveUtils.isMobileOrTablet(this);

  /// Screen width
  double get screenWidth => ResponsiveUtils.screenWidth(this);

  /// Screen height
  double get screenHeight => ResponsiveUtils.screenHeight(this);

  /// Responsive padding
  EdgeInsets get responsivePadding => ResponsiveUtils.responsivePadding(this);

  /// Content max width
  double get contentMaxWidth => ResponsiveUtils.contentMaxWidth(this);

  /// Form max width
  double get formMaxWidth => ResponsiveUtils.formMaxWidth(this);

  /// Grid column count
  int get gridColumnCount => ResponsiveUtils.gridColumnCount(this);

  /// Card grid column count
  int get cardGridColumnCount => ResponsiveUtils.cardGridColumnCount(this);

  /// Is landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Is portrait
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  /// Use bottom navigation
  bool get useBottomNavigation => ResponsiveUtils.useBottomNavigation(this);

  /// Use navigation rail
  bool get useNavigationRail => ResponsiveUtils.useNavigationRail(this);

  /// Use navigation drawer
  bool get useNavigationDrawer => ResponsiveUtils.useNavigationDrawer(this);

  /// Show side panel
  bool get showSidePanel => ResponsiveUtils.showSidePanel(this);

  /// Get responsive value
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      ResponsiveUtils.value(
        context: this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
