import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';

/// Dispatcher Groups Screen - شاشة إدارة المجموعات للمرسل - ShuttleBee
class DispatcherGroupsScreen extends ConsumerStatefulWidget {
  const DispatcherGroupsScreen({super.key});

  @override
  ConsumerState<DispatcherGroupsScreen> createState() =>
      _DispatcherGroupsScreenState();
}

class _DispatcherGroupsScreenState
    extends ConsumerState<DispatcherGroupsScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = true;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة المجموعات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_off_rounded,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
            },
            tooltip: _showActiveOnly ? 'إظهار الكل' : 'النشطة فقط',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allGroupsProvider),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Stats Summary
          groupsAsync.whenData((groups) => _buildStatsSummary(groups)),

          // Groups List
          Expanded(
            child: groupsAsync.when(
              data: (groups) => _buildGroupsList(groups),
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.go('${RoutePaths.dispatcherHome}/groups/create');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('مجموعة جديدة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن مجموعة...',
          hintStyle: const TextStyle(fontFamily: 'Cairo'),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatsSummary(List<PassengerGroup> groups) {
    final activeGroups = groups.where((g) => g.active).length;
    final totalMembers = groups.fold(0, (sum, g) => sum + g.memberCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.groups_rounded,
            label: 'المجموعات',
            value: '$activeGroups',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.people_rounded,
            label: 'إجمالي الركاب',
            value: '$totalMembers',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.event_repeat_rounded,
            label: 'رحلات/أسبوع',
            value: '${activeGroups * 10}',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList(List<PassengerGroup> groups) {
    var filteredGroups = groups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredGroups = filteredGroups
          .where((g) =>
              g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (g.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Apply active filter
    if (_showActiveOnly) {
      filteredGroups = filteredGroups.where((g) => g.active).toList();
    }

    if (filteredGroups.isEmpty) {
      return EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد مجموعات',
        message: _searchQuery.isNotEmpty
            ? 'لم يتم العثور على نتائج للبحث'
            : 'لم يتم إنشاء أي مجموعة بعد',
        buttonText: 'إنشاء مجموعة',
        onButtonPressed: () {
          context.go('${RoutePaths.dispatcherHome}/groups/create');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allGroupsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          final group = filteredGroups[index];
          return _buildGroupCard(group, index);
        },
      ),
    );
  }

  Widget _buildGroupCard(PassengerGroup group, int index) {
    final tripTypeColor = switch (group.tripType) {
      GroupTripType.pickup => AppColors.primary,
      GroupTripType.dropoff => AppColors.success,
      GroupTripType.both => const Color(0xFF7B1FA2),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showGroupActions(group);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tripTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      size: 28,
                      color: tripTypeColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.code != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  group.code!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tripTypeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                group.tripType.arabicLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tripTypeColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount} راكب',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.person_rounded,
                    group.driverName ?? 'بدون سائق',
                    group.hasDriver ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.directions_bus_rounded,
                    group.vehicleName ?? 'بدون مركبة',
                    group.hasVehicle ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.play_circle_rounded),
                    color: AppColors.success,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go(
                          '${RoutePaths.dispatcherHome}/trips/create?groupId=${group.id}');
                    },
                    tooltip: 'توليد رحلة',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (index * 50).ms,
        );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const ShimmerCard(height: 140);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(allGroupsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showGroupActions(PassengerGroup group) {
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
              group.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${group.memberCount} راكب • ${group.tripType.arabicLabel}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.play_circle_rounded,
              label: 'توليد رحلة جديدة',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                context.go(
                    '${RoutePaths.dispatcherHome}/trips/create?groupId=${group.id}');
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.schedule_rounded,
              label: 'إدارة الجداول',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                context.go(
                    '${RoutePaths.dispatcherHome}/groups/${group.id}/schedules');
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.edit_rounded,
              label: 'تعديل المجموعة',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context.go(
                    '${RoutePaths.dispatcherHome}/groups/${group.id}/edit');
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.people_alt_rounded,
              label: 'عرض الركاب',
              color: const Color(0xFF7B1FA2),
              onTap: () {
                Navigator.pop(context);
                context.go(
                    '${RoutePaths.dispatcherHome}/groups/${group.id}/passengers');
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
