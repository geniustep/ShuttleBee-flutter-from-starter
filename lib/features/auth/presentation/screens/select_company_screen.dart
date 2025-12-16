import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Company selection screen
class SelectCompanyScreen extends ConsumerWidget {
  const SelectCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Demo companies for now
    final companies = [
      {'id': 1, 'name': 'Main Company', 'description': 'Headquarters'},
      {'id': 2, 'name': 'Branch Office', 'description': 'Regional branch'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectCompany),
        automaticallyImplyLeading: false,
        centerTitle: context.isMobile,
      ),
      body: SafeArea(
        child: context.isDesktop
            ? _buildDesktopLayout(context, l10n, companies)
            : _buildMobileLayout(context, l10n, companies),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    List<Map<String, dynamic>> companies,
  ) {
    return Padding(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('select_company'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.lg),
          Expanded(
            child: _buildCompanyList(context, companies),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    List<Map<String, dynamic>> companies,
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
                  Icon(
                    Icons.business,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  Text(
                    l10n.selectCompany,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
                    child: Text(
                      l10n.multiCompany,
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
        // Right side - Company list
        Expanded(
          flex: 1,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.companies,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Expanded(
                      child: _buildCompanyList(context, companies),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyList(
    BuildContext context,
    List<Map<String, dynamic>> companies,
  ) {
    return ListView.separated(
      itemCount: companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) {
        final company = companies[index];
        return Card(
          elevation: context.isMobile ? 1 : 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(context.responsive(
              mobile: AppDimensions.md,
              tablet: AppDimensions.lg,
              desktop: AppDimensions.lg,
            )),
            leading: CircleAvatar(
              radius: context.responsive(
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                company['name'].toString()[0],
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                ),
              ),
            ),
            title: Text(
              company['name'].toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: company['description'] != null
                ? Text(company['description'].toString())
                : null,
            trailing: Icon(
              Icons.chevron_right,
              size: context.responsive(
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
            ),
            onTap: () {
              context.go(RoutePaths.home);
            },
          ),
        );
      },
    );
  }
}
