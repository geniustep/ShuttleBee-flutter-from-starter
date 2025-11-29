import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';

/// Reusable login form widget
class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController serverUrlController;
  final TextEditingController databaseController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.serverUrlController,
    required this.databaseController,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server URL
          TextFormField(
            controller: widget.serverUrlController,
            decoration: InputDecoration(
              labelText: l10n.serverUrl,
              prefixIcon: const Icon(Icons.dns_outlined),
              hintText: 'https://your-odoo-server.com',
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            validator: Validators.url,
            enabled: !widget.isLoading,
          ),

          const SizedBox(height: AppDimensions.md),

          // Database
          TextFormField(
            controller: widget.databaseController,
            decoration: InputDecoration(
              labelText: l10n.database,
              prefixIcon: const Icon(Icons.storage_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.required(v, fieldName: l10n.database),
            enabled: !widget.isLoading,
          ),

          const SizedBox(height: AppDimensions.md),

          // Username
          TextFormField(
            controller: widget.usernameController,
            decoration: InputDecoration(
              labelText: l10n.username,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.required(v, fieldName: l10n.username),
            enabled: !widget.isLoading,
          ),

          const SizedBox(height: AppDimensions.md),

          // Password
          TextFormField(
            controller: widget.passwordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: widget.isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onSubmit(),
            validator: (v) => Validators.required(v, fieldName: l10n.password),
            enabled: !widget.isLoading,
          ),

          const SizedBox(height: AppDimensions.sm),

          // Remember me
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: widget.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
              ),
              Text(l10n.rememberMe),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // Login button
          ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onSubmit,
            child: widget.isLoading
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
        ],
      ),
    );
  }
}
