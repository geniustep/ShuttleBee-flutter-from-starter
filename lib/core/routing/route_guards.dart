import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'route_paths.dart';

/// Route guard for authentication
class AuthGuard {
  final Ref ref;

  AuthGuard(this.ref);

  /// Check if user is authenticated
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.asData?.value.isAuthenticated ?? false;
    final isLoggingIn = state.matchedLocation == RoutePaths.login;
    final isSplash = state.matchedLocation == RoutePaths.splash;

    // Allow splash screen to handle initialization
    if (isSplash) {
      return null;
    }

    // If not logged in and not on login page, redirect to login
    if (!isLoggedIn && !isLoggingIn) {
      return RoutePaths.login;
    }

    // If logged in and on login page, redirect to home
    if (isLoggedIn && isLoggingIn) {
      return RoutePaths.home;
    }

    return null;
  }
}

/// Route guard for onboarding
class OnboardingGuard {
  final Ref ref;

  OnboardingGuard(this.ref);

  /// Check if onboarding is completed
  String? redirect(BuildContext context, GoRouterState state) {
    return null;
  }
}
