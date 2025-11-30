import 'package:bridgecore_flutter_starter/shared/providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'role_routing.dart';
import 'route_paths.dart';

/// Route guard for authentication with offline support
class AuthGuard {
  final Ref ref;

  AuthGuard(this.ref);

  /// Check if user is authenticated or can work offline
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final auth = authState.asData?.value;
    final isOnline = ref.read(isOnlineProvider);
    
    final isLoggedIn = auth?.isAuthenticated ?? false;
    final canWorkOffline = auth?.canWorkOffline ?? false;
    final isLoggingIn = state.matchedLocation == RoutePaths.login;
    final isSplash = state.matchedLocation == RoutePaths.splash;

    // Allow splash screen to handle initialization
    if (isSplash) {
      return null;
    }

    // If not logged in and can't work offline, redirect to login
    if (!isLoggedIn && !canWorkOffline && !isLoggingIn) {
      return RoutePaths.login;
    }

    // If logged in (or can work offline) and on login page, redirect to role-based home
    if ((isLoggedIn || canWorkOffline) && isLoggingIn) {
      final user = auth?.user;
      return getHomeRouteForRole(user?.role);
    }

    // Allow offline access if user has cached data
    if (!isLoggedIn && canWorkOffline && !isOnline) {
      // User is offline but has cached data - allow access
      return null;
    }

    return null;
  }
}

/// Route guard for routes that require online access
class OnlineGuard {
  final Ref ref;

  OnlineGuard(this.ref);

  /// Check if user is online for routes that require network
  String? redirect(BuildContext context, GoRouterState state) {
    final isOnline = ref.read(isOnlineProvider);
    
    if (!isOnline) {
      // Show offline message and redirect to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه الميزة تتطلب اتصال بالإنترنت'),
          backgroundColor: Colors.orange,
        ),
      );
      final authState = ref.read(authStateProvider);
      final user = authState.asData?.value.user;
      return getHomeRouteForRole(user?.role);
    }
    
    return null;
  }
}

/// Route guard for routes that require valid token (not just offline cache)
class ValidTokenGuard {
  final Ref ref;

  ValidTokenGuard(this.ref);

  /// Check if user has valid token (not just offline cache)
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final auth = authState.asData?.value;
    
    if (auth?.tokenState != TokenState.valid) {
      // Token is not valid - need to refresh or login
      if (auth?.needsTokenRefresh ?? false) {
        // Try to refresh in background
        ref.read(authStateProvider.notifier).refreshToken();
      }
      
      // For now, allow access but show warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحديث الجلسة...'),
          duration: Duration(seconds: 2),
        ),
      );
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

/// Combined guard that checks auth and token validity
class SmartAuthGuard {
  final Ref ref;

  SmartAuthGuard(this.ref);

  /// Smart redirect based on auth state, token validity, and network status
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final auth = authState.asData?.value;
    final isOnline = ref.read(isOnlineProvider);
    
    final currentPath = state.matchedLocation;
    
    // Allow splash to handle initialization
    if (currentPath == RoutePaths.splash) {
      return null;
    }

    // No auth data at all
    if (auth == null) {
      return currentPath == RoutePaths.login ? null : RoutePaths.login;
    }

    // Handle based on token state
    switch (auth.tokenState) {
      case TokenState.valid:
        // Fully authenticated - allow access, redirect from login
        if (currentPath == RoutePaths.login) {
          return getHomeRouteForRole(auth.user?.role);
        }
        return null;

      case TokenState.needsRefresh:
        if (isOnline) {
          // Online with expired token - try refresh in background
          ref.read(authStateProvider.notifier).refreshToken();
        }
        // Allow access (offline mode or refresh in progress)
        if (currentPath == RoutePaths.login) {
          return getHomeRouteForRole(auth.user?.role);
        }
        return null;

      case TokenState.expired:
        // Session expired - must login
        if (currentPath != RoutePaths.login) {
          return RoutePaths.login;
        }
        return null;

      case TokenState.none:
        // No tokens
        if (auth.canWorkOffline && !isOnline) {
          // Offline with cached data - allow limited access
          if (currentPath == RoutePaths.login) {
            return getHomeRouteForRole(auth.user?.role);
          }
          return null;
        }
        // No tokens and online (or no cached data) - go to login
        if (currentPath != RoutePaths.login) {
          return RoutePaths.login;
        }
        return null;
    }
  }
}
