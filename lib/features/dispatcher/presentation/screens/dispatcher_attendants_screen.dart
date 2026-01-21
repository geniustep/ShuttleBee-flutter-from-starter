import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/headers/dispatcher_unified_header.dart';
import '../widgets/headers/dispatcher_secondary_header.dart';
import '../widgets/common/dispatcher_footer.dart';
import '../widgets/common/dispatcher_action_fab.dart';

/// Dispatcher Attendants Screen - شاشة إدارة المرافقين للمرسل - ShuttleBee
class DispatcherAttendantsScreen extends ConsumerStatefulWidget {
  const DispatcherAttendantsScreen({super.key});

  @override
  ConsumerState<DispatcherAttendantsScreen> createState() =>
      _DispatcherAttendantsScreenState();
}

class _DispatcherAttendantsScreenState
    extends ConsumerState<DispatcherAttendantsScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attendantsAsync = ref.watch(companionsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.dispatcherHome);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // === Unified Header ===
            _buildHeader(context, l10n, attendantsAsync),

            // === شريط البحث والفلاتر (للموبايل فقط) ===
            _buildMobileSearchSection(context),

            // === Attendants List ===
            Expanded(
              child: attendantsAsync.when(
                data: (attendants) => _buildAttendantsList(attendants),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),

        // === Footer (Tablet/Desktop only) ===
        bottomNavigationBar: _buildFooter(attendantsAsync),

        // === FAB (Mobile only) ===
        floatingActionButton: DispatcherActionFAB(
          actions: [
            DispatcherFabAction(
              icon: Icons.add_rounded,
              label: l10n.addAttendant,
              isPrimary: true,
              onPressed: () {
                context.go('${RoutePaths.dispatcherHome}/attendants/create');
              },
            ),
            if (_hasActiveFilters)
              DispatcherFabAction(
                icon: Icons.clear_all_rounded,
                label: l10n.clearFilters,
                onPressed: () {
                  setState(() {
                    _showActiveOnly = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 HEADER BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<SimpleUser>> attendantsAsync,
  ) {
    return DispatcherUnifiedHeader(
      title: l10n.attendantsManagement,
      subtitle: attendantsAsync.maybeWhen(
        data: (attendants) {
          return '${l10n.total}: ${Formatters.formatSimple(attendants.length)}';
        },
        orElse: () => null,
      ),
      searchHint: l10n.searchAttendant,
      searchValue: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onSearchClear: () => setState(() => _searchQuery = ''),
      showSearch: !context.isMobile,
      onRefresh: () async {
        if (!mounted) return;
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        final container = ref.container;

        if (userId != 0) {
          await cache.delete(
            DispatcherCacheKeys.usersByRole(userId: userId, role: 'companion_only'),
          );
        }

        if (mounted) {
          container.invalidate(companionsProvider);
        }
      },
      isLoading: attendantsAsync.isLoading,
      actions: [
        const RoleSwitcherButton(),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: _hasActiveFilters ? AppColors.warning : Colors.white,
          ),
          onPressed: _openFiltersSheet,
          tooltip: l10n.filter,
        ),
      ],
      primaryActions: [
        DispatcherHeaderAction(
          icon: Icons.add_rounded,
          label: l10n.addAttendant,
          isPrimary: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/attendants/create');
          },
        ),
        if (_hasActiveFilters)
          DispatcherHeaderAction(
            icon: Icons.clear_all_rounded,
            label: l10n.clearFilters,
            onPressed: () {
              setState(() {
                _showActiveOnly = false;
              });
            },
          ),
      ],
      stats: attendantsAsync.maybeWhen(
        data: (attendants) {
          return [
            DispatcherHeaderStat(
              icon: Icons.person_add_alt_rounded,
              label: l10n.attendants,
              value: Formatters.formatSimple(attendants.length),
            ),
          ];
        },
        orElse: () => [],
      ),
      filters: context.isMobile ? [] : _buildActiveFilterChips(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE SEARCH SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileSearchSection(BuildContext context) {
    if (!context.isMobile) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حقل البحث
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: l10n.searchAttendant,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
            ),
          ),

          // الفلاتر النشطة
          if (_buildActiveFilterChips().isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildActiveFilterChips()
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: f,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (_showActiveOnly) {
      chips.add(
        DispatcherFilterChip(
          label: l10n.activeOnly,
          isSelected: true,
          onTap: () => setState(() => _showActiveOnly = false),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      );
    }

    return chips;
  }

  Widget _buildFooter(AsyncValue<List<SimpleUser>> attendantsAsync) {
    final l10n = AppLocalizations.of(context);
    return attendantsAsync.maybeWhen(
      data: (attendants) {
        final filteredCount = _getFilteredAttendants(attendants).length;
        final totalCount = attendants.length;

        return DispatcherFooter(
          hideOnMobile: true,
          info: filteredCount != totalCount
              ? '${l10n.showingOf} ${Formatters.formatSimple(filteredCount)} ${l10n.ofText} ${Formatters.formatSimple(totalCount)} ${l10n.attendants}'
              : '${l10n.total}: ${Formatters.formatSimple(totalCount)} ${l10n.attendants}',
          stats: [
            DispatcherFooterStat(
              icon: Icons.person_add_alt_rounded,
              label: l10n.attendants,
              value: Formatters.formatSimple(totalCount),
            ),
          ],
          lastUpdated: DateTime.now(),
          syncStatus: DispatcherSyncStatus.synced,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  List<SimpleUser> _getFilteredAttendants(List<SimpleUser> attendants) {
    var filteredAttendants = attendants;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredAttendants = filteredAttendants
          .where(
            (a) =>
                a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (a.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    return filteredAttendants;
  }

  Widget _buildAttendantsList(List<SimpleUser> attendants) {
    final l10n = AppLocalizations.of(context);
    final filteredAttendants = _getFilteredAttendants(attendants);

    if (filteredAttendants.isEmpty) {
      return EmptyState(
        icon: Icons.person_add_alt_rounded,
        title: l10n.noAttendants,
        message: _searchQuery.isNotEmpty
            ? l10n.noAttendantsFound
            : l10n.noAttendantsAdded,
        buttonText: l10n.addAttendant,
        onButtonPressed: () {
          context.go('${RoutePaths.dispatcherHome}/attendants/create');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!mounted) return;
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        final container = ref.container;

        if (userId != 0) {
          await cache.delete(
            DispatcherCacheKeys.usersByRole(userId: userId, role: 'companion_only'),
          );
        }

        if (mounted) {
          container.invalidate(companionsProvider);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          context.isMobile ? 96 : 16,
        ),
        itemCount: filteredAttendants.length,
        itemBuilder: (context, index) {
          final attendant = filteredAttendants[index];
          return _buildAttendantCard(attendant, index);
        },
      ),
    );
  }

  bool get _hasActiveFilters => _showActiveOnly;

  Future<void> _openFiltersSheet() async {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool localActiveOnly = _showActiveOnly;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              margin: const EdgeInsets.only(top: 100),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.dispatcherPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.filter,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                localActiveOnly = false;
                              });
                            },
                            child: Text(
                              l10n.reset,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localActiveOnly,
                        onChanged: (v) => setLocal(() => localActiveOnly = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          l10n.activeOnly,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                l10n.cancel,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dispatcherPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showActiveOnly = localActiveOnly;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                l10n.apply,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendantCard(SimpleUser attendant, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('${RoutePaths.dispatcherHome}/attendants/${attendant.id}');
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showAttendantActions(attendant);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_add_alt_rounded,
                  size: 28,
                  color: AppColors.dispatcherPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attendant.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              attendant.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (attendant.role != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          attendant.role!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dispatcherPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                color: AppColors.textSecondary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('${RoutePaths.dispatcherHome}/attendants/${attendant.id}');
                },
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms, delay: (index * 50).ms);
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            isMobile ? 96 : 16,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const ShimmerCard(height: 100);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (!mounted) return;
              final cache = ref.read(dispatcherCacheDataSourceProvider);
              final userId =
                  ref.read(authStateProvider).asData?.value.user?.id ?? 0;
              final container = ref.container;

              if (userId != 0) {
                await cache.delete(
                  DispatcherCacheKeys.usersByRole(userId: userId, role: 'companion_only'),
                );
              }

              if (mounted) {
                container.invalidate(companionsProvider);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  void _showAttendantActions(SimpleUser attendant) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              attendant.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            if (attendant.email != null)
              Text(
                attendant.email!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.edit_rounded,
              label: l10n.edit,
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/attendants/${attendant.id}/edit',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.info_outline_rounded,
              label: l10n.viewDetails,
              color: AppColors.dispatcherPrimary,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/attendants/${attendant.id}',
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

