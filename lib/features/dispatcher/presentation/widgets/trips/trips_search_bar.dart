import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/trips_filter_provider.dart';
import 'trips_advanced_filter_sheet.dart';

/// شريط البحث والفلتر للرحلات
class TripsSearchBar extends ConsumerStatefulWidget {
  const TripsSearchBar({super.key});

  @override
  ConsumerState<TripsSearchBar> createState() => _TripsSearchBarState();
}

class _TripsSearchBarState extends ConsumerState<TripsSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تهيئة النص من الحالة الحالية
    final currentState = ref.read(tripsFilterProvider);
    _searchController.text = currentState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filterState = ref.watch(tripsFilterProvider);
    final hasActiveFilters = filterState.hasActiveFilters;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchTrip,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey.shade500,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر مسح البحث
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(tripsFilterProvider.notifier).clearSearch();
                      },
                    ),

                  // زر الفلتر المتقدم
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: hasActiveFilters
                              ? AppColors.dispatcherPrimary
                              : null,
                        ),
                        onPressed: () => _showAdvancedFilter(context),
                      ),

                      // مؤشر الفلاتر النشطة
                      if (hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${filterState.activeFiltersCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.dispatcherPrimary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {}); // لتحديث زر المسح
              ref.read(tripsFilterProvider.notifier).setSearch(value);
            },
          ),

          const SizedBox(height: 8),

          // شرائح الفلتر السريع (Filter Chips)
          if (hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // عرض الفلاتر النشطة
                  ...filterState.getActiveFilters(context).map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(
                              filter.label,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                            onDeleted: () => ref
                                .read(tripsFilterProvider.notifier)
                                .removeFilter(filter),
                            onSelected: (_) {}, // Required parameter
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: filter.color.withValues(alpha: 0.1),
                            labelStyle: TextStyle(color: filter.color),
                          ),
                        ),
                      ),

                  // زر مسح الكل
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(
                      l10n.clearFilters,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(tripsFilterProvider.notifier).clearAllFilters();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAdvancedFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TripsAdvancedFilterSheet(),
    );
  }
}
