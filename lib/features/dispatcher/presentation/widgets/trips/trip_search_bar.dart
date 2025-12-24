import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/trip_filter_provider.dart';
import 'advanced_filter_sheet.dart';

/// شريط البحث والفلتر للرحلات
class TripSearchBar extends ConsumerStatefulWidget {
  final int tripId;

  const TripSearchBar({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripSearchBar> createState() => _TripSearchBarState();
}

class _TripSearchBarState extends ConsumerState<TripSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تهيئة النص من الحالة الحالية
    final currentState = ref.read(tripFilterProvider);
    _searchController.text = currentState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(tripFilterProvider);
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
              hintText: 'ابحث في الركاب، السائق، أو المعلومات...',
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
                        ref.read(tripFilterProvider.notifier).clearSearch();
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
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
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
              ref.read(tripFilterProvider.notifier).setSearch(value);
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
                                .read(tripFilterProvider.notifier)
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
                    label: const Text(
                      'مسح الكل',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    onPressed: () => ref
                        .read(tripFilterProvider.notifier)
                        .clearAllFilters(),
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
      builder: (context) => AdvancedFilterSheet(tripId: widget.tripId),
    );
  }
}
