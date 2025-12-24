import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// واجهة عرض حالة الفراغ للركاب
class EmptyPassengersView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  const EmptyPassengersView({
    super.key,
    required this.hasFilters,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilters ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'لا توجد نتائج مطابقة' : 'لا يوجد ركاب',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'جرب تعديل الفلاتر أو البحث'
                : 'اضغط على "إضافة" لإضافة ركاب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text(
                'مسح الفلاتر',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onPressed: onClearFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
