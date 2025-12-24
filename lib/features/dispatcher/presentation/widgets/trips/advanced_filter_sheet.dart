import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/enums/trip_line_status.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../trips/presentation/providers/trip_providers.dart';
import '../../models/trip_filter_model.dart';
import '../../providers/trip_filter_provider.dart';

/// نافذة الفلتر المتقدم
class AdvancedFilterSheet extends ConsumerWidget {
  final int tripId;

  const AdvancedFilterSheet({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(tripFilterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, ref, filterState),

            const Divider(height: 1),

            // محتوى الفلاتر
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. فلتر حالة الركاب
                  _buildSectionTitle('حالة الركاب'),
                  _buildPassengerStatusFilter(ref, filterState),

                  const SizedBox(height: 24),

                  // 2. فلتر المواقع
                  _buildSectionTitle('مواقع الصعود'),
                  _buildLocationFilter(ref, filterState),

                  const SizedBox(height: 24),

                  // 3. فلتر معلومات إضافية
                  _buildSectionTitle('معلومات إضافية'),
                  _buildAdditionalInfoFilter(ref, filterState),

                  const SizedBox(height: 24),

                  // 4. ترتيب النتائج
                  _buildSectionTitle('ترتيب حسب'),
                  _buildSortOptions(ref, filterState),
                ],
              ),
            ),

            // أزرار الإجراءات
            _buildActionButtons(context, ref, filterState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    TripFilterState filterState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الفلتر المتقدم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (filterState.activeFiltersCount > 0)
                      Text(
                        '${Formatters.formatSimple(filterState.activeFiltersCount)} فلتر نشط',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. فلتر حالة الركاب
  Widget _buildPassengerStatusFilter(
    WidgetRef ref,
    TripFilterState filterState,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'صعد للباص',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          isSelected:
              filterState.passengerStatuses.contains(TripLineStatus.boarded),
          onTap: () => ref
              .read(tripFilterProvider.notifier)
              .togglePassengerStatus(TripLineStatus.boarded),
        ),
        _buildFilterChip(
          label: 'غائب',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          isSelected:
              filterState.passengerStatuses.contains(TripLineStatus.absent),
          onTap: () => ref
              .read(tripFilterProvider.notifier)
              .togglePassengerStatus(TripLineStatus.absent),
        ),
        _buildFilterChip(
          label: 'تم الإنزال',
          icon: Icons.place_rounded,
          color: AppColors.primary,
          isSelected:
              filterState.passengerStatuses.contains(TripLineStatus.dropped),
          onTap: () => ref
              .read(tripFilterProvider.notifier)
              .togglePassengerStatus(TripLineStatus.dropped),
        ),
        _buildFilterChip(
          label: 'لم يبدأ',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          isSelected:
              filterState.passengerStatuses.contains(TripLineStatus.notStarted),
          onTap: () => ref
              .read(tripFilterProvider.notifier)
              .togglePassengerStatus(TripLineStatus.notStarted),
        ),
      ],
    );
  }

  // 2. فلتر المواقع
  Widget _buildLocationFilter(WidgetRef ref, TripFilterState filterState) {
    final trip = ref.watch(tripDetailProvider(tripId)).value;
    if (trip == null) return const SizedBox();

    // استخراج المواقع الفريدة
    final locations = trip.lines
        .map((line) => line.pickupLocationName)
        .where((name) => name != 'غير محدد')
        .toSet()
        .toList();

    if (locations.isEmpty) {
      return const Text(
        'لا توجد مواقع محددة',
        style: TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locations
          .map(
            (location) => _buildFilterChip(
              label: location,
              icon: Icons.location_on_rounded,
              color: AppColors.dispatcherPrimary,
              isSelected: filterState.selectedLocations.contains(location),
              onTap: () => ref
                  .read(tripFilterProvider.notifier)
                  .toggleLocation(location),
            ),
          )
          .toList(),
    );
  }

  // 3. معلومات إضافية
  Widget _buildAdditionalInfoFilter(
    WidgetRef ref,
    TripFilterState filterState,
  ) {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text(
            'فقط من لديهم ولي أمر',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: filterState.hasGuardianOnly,
          onChanged: (value) => ref
              .read(tripFilterProvider.notifier)
              .toggleHasGuardian(value ?? false),
          secondary: const Icon(Icons.family_restroom_rounded),
        ),
        CheckboxListTile(
          title: const Text(
            'فقط من لديهم رقم هاتف',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: filterState.hasPhoneOnly,
          onChanged: (value) => ref
              .read(tripFilterProvider.notifier)
              .toggleHasPhone(value ?? false),
          secondary: const Icon(Icons.phone_rounded),
        ),
      ],
    );
  }

  // 4. خيارات الترتيب
  Widget _buildSortOptions(WidgetRef ref, TripFilterState filterState) {
    return Column(
      children: [
        RadioListTile<SortOption>(
          title: const Text(
            'الترتيب الافتراضي',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: SortOption.defaultOrder,
          groupValue: filterState.sortBy,
          onChanged: (value) =>
              ref.read(tripFilterProvider.notifier).setSortOption(value!),
        ),
        RadioListTile<SortOption>(
          title: const Text(
            'حسب الاسم (أ-ي)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: SortOption.nameAsc,
          groupValue: filterState.sortBy,
          onChanged: (value) =>
              ref.read(tripFilterProvider.notifier).setSortOption(value!),
        ),
        RadioListTile<SortOption>(
          title: const Text(
            'حسب الاسم (ي-أ)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: SortOption.nameDesc,
          groupValue: filterState.sortBy,
          onChanged: (value) =>
              ref.read(tripFilterProvider.notifier).setSortOption(value!),
        ),
        RadioListTile<SortOption>(
          title: const Text(
            'حسب الحالة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: SortOption.status,
          groupValue: filterState.sortBy,
          onChanged: (value) =>
              ref.read(tripFilterProvider.notifier).setSortOption(value!),
        ),
        RadioListTile<SortOption>(
          title: const Text(
            'حسب الموقع',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: SortOption.location,
          groupValue: filterState.sortBy,
          onChanged: (value) =>
              ref.read(tripFilterProvider.notifier).setSortOption(value!),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    TripFilterState filterState,
  ) {
    final resultsCount = ref.watch(filterResultsCountProvider(tripId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر إعادة تعيين
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة تعيين',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onPressed: () {
                ref.read(tripFilterProvider.notifier).resetFilters();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // زر تطبيق
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(
                'تطبيق (${Formatters.formatSimple(resultsCount)})',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // الفلاتر تطبق تلقائياً عبر Provider
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dispatcherPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
