import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// A builder widget that provides different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile layout (required)
  final Widget Function(BuildContext context, BoxConstraints constraints) mobile;

  /// Builder for tablet layout (optional, falls back to mobile)
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;

  /// Builder for desktop layout (optional, falls back to tablet or mobile)
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);

        switch (deviceType) {
          case DeviceType.desktop:
            return desktop?.call(context, constraints) ??
                tablet?.call(context, constraints) ??
                mobile(context, constraints);
          case DeviceType.tablet:
            return tablet?.call(context, constraints) ??
                mobile(context, constraints);
          case DeviceType.mobile:
            return mobile(context, constraints);
        }
      },
    );
  }
}

/// A simpler responsive widget that just switches between widgets
class ResponsiveWidget extends StatelessWidget {
  /// Widget for mobile
  final Widget mobile;

  /// Widget for tablet (optional)
  final Widget? tablet;

  /// Widget for desktop (optional)
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// A visibility widget based on device type
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    bool isVisible;

    switch (deviceType) {
      case DeviceType.mobile:
        isVisible = visibleOnMobile;
        break;
      case DeviceType.tablet:
        isVisible = visibleOnTablet;
        break;
      case DeviceType.desktop:
        isVisible = visibleOnDesktop;
        break;
    }

    if (isVisible) {
      return child;
    }
    return replacement ?? const SizedBox.shrink();
  }
}

/// Hide widget on mobile only
class HideOnMobile extends StatelessWidget {
  final Widget child;
  final Widget? replacement;

  const HideOnMobile({
    super.key,
    required this.child,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveVisibility(
      visibleOnMobile: false,
      replacement: replacement,
      child: child,
    );
  }
}

/// Hide widget on desktop only
class HideOnDesktop extends StatelessWidget {
  final Widget child;
  final Widget? replacement;

  const HideOnDesktop({
    super.key,
    required this.child,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveVisibility(
      visibleOnDesktop: false,
      replacement: replacement,
      child: child,
    );
  }
}

/// Show widget only on mobile
class MobileOnly extends StatelessWidget {
  final Widget child;

  const MobileOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveVisibility(
      visibleOnMobile: true,
      visibleOnTablet: false,
      visibleOnDesktop: false,
      child: child,
    );
  }
}

/// Show widget only on tablet
class TabletOnly extends StatelessWidget {
  final Widget child;

  const TabletOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveVisibility(
      visibleOnMobile: false,
      visibleOnTablet: true,
      visibleOnDesktop: false,
      child: child,
    );
  }
}

/// Show widget only on desktop
class DesktopOnly extends StatelessWidget {
  final Widget child;

  const DesktopOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveVisibility(
      visibleOnMobile: false,
      visibleOnTablet: false,
      visibleOnDesktop: true,
      child: child,
    );
  }
}
