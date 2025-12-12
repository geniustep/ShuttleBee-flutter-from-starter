import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/role_routing.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/animated_logo.dart';

/// Splash screen with smart auth handling
/// 
/// هذه الشاشة تتعامل بذكاء مع حالات التوكن المختلفة:
/// - authenticated: دخول مباشر للـ Home
/// - needsRefresh: محاولة تجديد التوكن أو الدخول أوفلاين
/// - expired: توجيه لصفحة تسجيل الدخول
/// - none: توجيه لصفحة تسجيل الدخول
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusMessage = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check network status
    final networkInfo = ref.read(networkInfoProvider);
    final isOnline = await networkInfo.isConnected;
    ref.read(isOnlineStateProvider.notifier).state = isOnline;

    // Wait for auth state to be ready
    final authState = ref.read(authStateProvider);
    
    if (authState.isLoading) {
      // Wait a bit more for auth check to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    final currentAuthState = ref.read(authStateProvider);
    final auth = currentAuthState.asData?.value;

    if (auth == null) {
      // Auth state not ready, go to login
      _navigateToLogin();
      return;
    }

    // Handle different auth states
    switch (auth.tokenState) {
      case TokenState.valid:
        // Fully authenticated - go to home
        _updateStatus('مرحباً ${auth.user?.name ?? ""}');
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToHome();
        break;

      case TokenState.needsRefresh:
        if (isOnline) {
          // Online - try to refresh token
          _updateStatus('جاري تحديث الجلسة...');
          final authNotifier = ref.read(authStateProvider.notifier);
          final refreshed = await authNotifier.refreshToken();
          
          if (refreshed) {
            _updateStatus('مرحباً ${auth.user?.name ?? ""}');
            await Future.delayed(const Duration(milliseconds: 300));
            _navigateToHome();
          } else {
            // Refresh failed - go to login
            _updateStatus('انتهت صلاحية الجلسة');
            await Future.delayed(const Duration(milliseconds: 500));
            _navigateToLogin();
          }
        } else {
          // Offline - allow access with cached data
          // هذا مهم لـ ShuttleBee: السائق يمكنه العمل أوفلاين
          _updateStatus('وضع بدون اتصال');
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToHome(offlineMode: true);
        }
        break;

      case TokenState.expired:
        // Session completely expired
        _updateStatus('انتهت صلاحية الجلسة');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToLogin();
        break;

      case TokenState.none:
        // No tokens - check if we have user data for offline
        if (auth.canWorkOffline && !isOnline) {
          _updateStatus('وضع بدون اتصال');
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToHome(offlineMode: true);
        } else {
          _navigateToLogin();
        }
        break;
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToHome({bool offlineMode = false}) {
    if (!mounted) return;
    
    if (offlineMode) {
      // Show offline indicator before navigating
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أنت في وضع بدون اتصال. بعض الميزات قد لا تعمل.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    // Navigate to role-based home screen
    final auth = ref.read(authStateProvider).asData?.value;
    final role = auth?.user?.role;
    final homeRoute = getHomeRouteForRole(role);
    
    print('🚀 [SplashScreen] Navigating to: $homeRoute (role: ${role?.value ?? "null"})');
    context.go(homeRoute);
  }

  void _navigateToLogin() {
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to network changes
    ref.listen<bool>(isOnlineStateProvider, (previous, next) {
      if (previous == false && next == true) {
        // Back online - might want to refresh
        print('🌐 Network restored');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  const AnimatedLogo(),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                    'ShuttleBee',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'خدمة النقل الذكية',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),

                  const SizedBox(height: 48),

                  // Loading indicator
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusMessage,
                      key: ValueKey(_statusMessage),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
