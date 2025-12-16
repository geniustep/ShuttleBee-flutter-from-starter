import 'package:bridgecore_flutter_starter/core/config/env_config.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/role_routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController =
      TextEditingController(text: "youssef@done.bridgecore.internal");
  // TextEditingController(text: "admin@done.bridgecore.internal");
  final _passwordController = TextEditingController(text: ",,07Genius");

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
      serverUrl: EnvConfig.odooUrl,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
      modelName: "res.users",
      listFields: ["shuttle_role"],
    );

    if (!mounted) return;

    if (success) {
      // Get user role and navigate to appropriate home
      final user = ref.read(authStateProvider).asData?.value.user;
      final homeRoute = getHomeRouteForRole(user?.role);
      context.go(homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    // Listen for auth errors and show snackbar
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    // Responsive form max width
    final formMaxWidth = context.responsive(
      mobile: double.infinity,
      tablet: 450.0,
      desktop: 500.0,
    );

    // Responsive padding
    final horizontalPadding = context.responsive(
      mobile: AppDimensions.md,
      tablet: AppDimensions.xl,
      desktop: AppDimensions.xxl,
    );

    return Scaffold(
      body: SafeArea(
        child: context.isDesktop
            ? _buildDesktopLayout(context, l10n, isLoading, formMaxWidth)
            : _buildMobileLayout(context, l10n, isLoading, formMaxWidth, horizontalPadding),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isLoading,
    double formMaxWidth,
    double horizontalPadding,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppDimensions.md,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: formMaxWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(),
              const SizedBox(height: AppDimensions.xxl),
              _buildLoginForm(context, l10n, isLoading),
              const SizedBox(height: AppDimensions.lg),
              _buildLanguageSelector(context),
              const SizedBox(height: AppDimensions.md),
              _buildVersionInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isLoading,
    double formMaxWidth,
  ) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthHeader(),
                  const SizedBox(height: AppDimensions.xl),
                  Text(
                    l10n.welcomeToApp,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
                    child: Text(
                      l10n.onboardingDesc1,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Login form
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.xxl),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formMaxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLoginForm(context, l10n, isLoading),
                    const SizedBox(height: AppDimensions.lg),
                    _buildLanguageSelector(context),
                    const SizedBox(height: AppDimensions.md),
                    _buildVersionInfo(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AppLocalizations l10n, bool isLoading) {
    return Card(
      elevation: context.isMobile ? 1 : 4,
      child: Padding(
        padding: EdgeInsets.all(context.responsive(
          mobile: AppDimensions.lg,
          tablet: AppDimensions.xl,
          desktop: AppDimensions.xxl,
        )),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.login,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xl),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, fieldName: l10n.username),
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                validator: (v) => Validators.required(v, fieldName: l10n.password),
              ),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  Text(l10n.rememberMe),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              SizedBox(
                height: context.responsive(
                  mobile: 48.0,
                  tablet: 52.0,
                  desktop: 56.0,
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.login),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final localeNotifier = ref.read(localeProvider.notifier);
    final currentLocale = ref.watch(localeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.language,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppDimensions.xs),
        DropdownButton<String>(
          value: currentLocale.languageCode,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
            DropdownMenuItem(value: 'fr', child: Text('Français')),
          ],
          onChanged: (value) {
            if (value != null) {
              localeNotifier.setLocale(Locale(value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Text(
      'v1.0.0',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}
