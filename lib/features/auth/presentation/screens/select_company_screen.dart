import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

/// Company selection screen
class SelectCompanyScreen extends ConsumerWidget {
  const SelectCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Demo companies for now
    final companies = [
      {'id': 1, 'name': 'Main Company'},
      {'id': 2, 'name': 'Branch Office'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('select_company')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select the company you want to work with',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppDimensions.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: companies.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.sm),
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            company['name'].toString()[0],
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(company['name'].toString()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Select company and go to home
                          context.go(RoutePaths.home);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
