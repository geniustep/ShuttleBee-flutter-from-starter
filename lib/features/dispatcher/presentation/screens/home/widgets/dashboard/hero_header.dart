import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../shared/widgets/common/hero_header.dart';
import '../../../../../../../shared/providers/global_providers.dart';
import '../../../../../../auth/domain/entities/user.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';
import '../../../../../../chat/presentation/providers/chat_providers.dart';

class DispatcherHeroHeader extends ConsumerWidget {
  final User? user;
  final AsyncValue<TripDashboardStats> statsAsync;
  final AnimationController pulseController;
  final VoidCallback onRefresh;

  const DispatcherHeroHeader({
    super.key,
    required this.user,
    required this.statsAsync,
    required this.pulseController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRefreshing = statsAsync.isLoading;
    final isOnline = ref.watch(isOnlineStateProvider);
    final l10n = AppLocalizations.of(context);

    return HeroHeader(
      title: l10n.welcome,
      userName: user?.name ?? l10n.dispatcher,
      subtitle: _formatDate(context, DateTime.now()),
      gradientColors: HeroGradients.dispatcher,
      showOnlineIndicator: isOnline,
      onlineIndicatorController: pulseController,
      expandedHeight: 180,
      bottomWidget: !isOnline
          ? GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(RoutePaths.offlineStatus);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.disconnected} • ${l10n.viewSyncStatus}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      actions: [
        HeroHeaderAction(
          icon: Icons.refresh_rounded,
          tooltip: l10n.refresh,
          isLoading: isRefreshing,
          onPressed: () {
            HapticFeedback.mediumImpact();
            onRefresh();
          },
        ),
        HeroHeaderAction(
          icon: Icons.settings_rounded,
          tooltip: l10n.settings,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(RoutePaths.settings);
          },
        ),
        HeroHeaderAction(
          icon: Icons.notifications_rounded,
          tooltip: l10n.notifications,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go(RoutePaths.notifications);
          },
        ),
        HeroHeaderAction(
          icon: Icons.chat_bubble_rounded,
          tooltip: 'Messages',
          badge: ref.watch(unreadMessagesCountProvider).maybeWhen(
                data: (count) => count > 0 ? count : null,
                orElse: () => null,
              ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/conversations');
          },
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == yesterday) {
      return l10n.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
