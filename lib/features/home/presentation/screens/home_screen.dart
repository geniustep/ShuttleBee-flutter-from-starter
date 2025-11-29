import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activities_list.dart';
import '../widgets/stats_summary_card.dart';

/// Home screen with drawer navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? true;

    final userName = authState.asData?.value.user?.name ?? 'User';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(l10n.home),
        actions: [
          // Online/Offline indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.successLight : AppColors.errorLight,
              borderRadius: AppDimensions.borderRadiusCircle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: isOnline ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? l10n.online : l10n.offline,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RoutePaths.search),
          ),

          // Notifications
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(RoutePaths.notifications),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                '${l10n.translate('welcome')}, $userName!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.xxs),
              Text(
                'Here\'s what\'s happening today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: AppDimensions.lg),

              // Stats cards
              const StatsSummaryCard(),

              const SizedBox(height: AppDimensions.lg),

              // Quick actions
              Text(
                l10n.translate('quick_actions'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.sm),
              const QuickActionsGrid(),

              const SizedBox(height: AppDimensions.lg),

              // Recent activities
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('recent_activities'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              const RecentActivitiesList(),
            ],
          ),
        ),
      ),
    );
  }
}
