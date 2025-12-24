import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/enums/enums.dart';

class SidebarFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String tripSearchQuery;
  final ValueChanged<String> onSearchChanged;
  final TripState? selectedTripFilter;
  final ValueChanged<TripState?> onFilterChanged;

  const SidebarFilters({
    super.key,
    required this.searchController,
    required this.tripSearchQuery,
    required this.onSearchChanged,
    required this.selectedTripFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dispatcherPrimary.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'بحث في الرحلات...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.dispatcherPrimary,
                size: 20,
              ),
              suffixIcon: tripSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.dispatcherPrimary,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'الكل',
                isSelected: selectedTripFilter == null,
                onTap: () => onFilterChanged(null),
              ),
              _buildFilterChip(
                label: 'جارية',
                color: AppColors.warning,
                isSelected: selectedTripFilter == TripState.ongoing,
                onTap: () => onFilterChanged(TripState.ongoing),
              ),
              _buildFilterChip(
                label: 'مخطط',
                color: AppColors.primary,
                isSelected: selectedTripFilter == TripState.planned,
                onTap: () => onFilterChanged(TripState.planned),
              ),
              _buildFilterChip(
                label: 'مكتملة',
                color: AppColors.success,
                isSelected: selectedTripFilter == TripState.done,
                onTap: () => onFilterChanged(TripState.done),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.dispatcherPrimary;

    return Material(
      color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : chipColor,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}
