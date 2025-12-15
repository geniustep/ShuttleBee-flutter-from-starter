import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/states/empty_state.dart';

/// Search screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final _recentSearches = [
    'Product ABC',
    'Customer John',
    'Order #1234',
    'Invoice #567',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.translate('search_placeholder'),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (value) {
            setState(() => _query = value);
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty ? _buildRecentSearches() : _buildSearchResults(),
    );
  }

  Widget _buildRecentSearches() {
    final l10n = AppLocalizations.of(context);

    if (_recentSearches.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Start searching',
        message: 'Search for products, customers, orders, and more',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('recent_searches'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  color: AppColors.textSecondary,
                ),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _recentSearches.removeAt(index);
                    });
                  },
                ),
                onTap: () {
                  _searchController.text = search;
                  setState(() => _query = search);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context);

    // Demo search results
    final results = [
      const _SearchResult(
        type: 'Product',
        title: 'Product ABC',
        subtitle: 'SKU: PRD-001 • \$99.99',
        icon: Icons.inventory_2,
      ),
      const _SearchResult(
        type: 'Customer',
        title: 'John Doe',
        subtitle: 'john@example.com',
        icon: Icons.person,
      ),
      const _SearchResult(
        type: 'Order',
        title: 'Order #1234',
        subtitle: 'John Doe • \$250.00',
        icon: Icons.shopping_cart,
      ),
    ]
        .where(
          (r) =>
              r.title.toLowerCase().contains(_query.toLowerCase()) ||
              r.subtitle.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.translate('no_results'),
        message: 'Try searching with different keywords',
      );
    }

    return ListView.builder(
      padding: AppDimensions.paddingVerticalSm,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppDimensions.borderRadiusSm,
            ),
            child: Icon(result.icon, color: AppColors.primary),
          ),
          title: Text(result.title),
          subtitle: Text(
            result.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          trailing: Chip(
            label: Text(
              result.type,
              style: const TextStyle(fontSize: 10),
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            // Navigate to result
          },
        );
      },
    );
  }
}

class _SearchResult {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
